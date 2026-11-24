<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Standing
@design standing=v1
@cites conformance=v1
@cites text=v1
@cites identifiers=v1
@cites files=v1
@cites data-forms=v1
@cites ontology=v1
@cites object-store=v1
@cites changes=v1
@cites findings=v1
@cites documents=v1
@cites revisions=v1
@cites approval=v1
@cites rfc/8259
Specifies the parameter `historical-paths` and historical files; the successors of retired declared items; the finding classes `retired`, `cycle`, `deleted-decision`, and `reused-label`; the conditions on an offered fix of a `retired` finding; and requirements for conforming programs that give successors and the findings of these classes.

Declared items change over time: authors replace them with `supersedes`
edges, mark them `@deprecated` (or set the member `status` in
`.sinter/`), and give them new labels when their revised content
changes. When a declared item is retired, other items that cite that
declared item can still name it, and in-force items can replace it
through effective `supersedes` edges. A conforming program finds those
successors, reports edges to retired items, reports cycles of
`supersedes` and `refines` edges, reports decision records that a change
deletes, and reports items that reuse a label from the history of the
default branch for other content, across the text encoding, the
`.sinter/` encoding, and any valid program's own store. A repository can
also name historical paths so that historical text files give no
findings of these classes at spots in those files.

From Conformance (`conformance`), the design takes conforming programs,
inputs, dependence, objects, encodings, valid program's own stores, and
the general requirements that bind every conforming program, including
`conformance#end-runs-at-limits`, `conformance#reject-invalid-inputs`,
`conformance#report-missing-parts`,
`conformance#give-results-over-canonical-objects`, and
`conformance#read-defined-encodings`. From Text and notation (`text`),
the design takes texts, characters, spaces, tabs, places, lines, line
numbers, whole numbers, decimal numerals, boundaries, runs, spans,
positions, code point order, code spans, sequences, and results. From
Identifiers (`identifiers`), it takes tag lines, declarations,
citations, citation lines, citation entries, inline citations, tag line
texts, status tags, the parameter `external-namespaces` with its
bindings, and the results that a conforming program of Identifiers
gives. From Files and paths (`files`), it takes valid paths, path sets,
valid path sets, and membership in the set of a path set. From Data
forms (`data-forms`), it takes JSON values, indexes, hash forms, vector
lines, test-vector sets, the forms of a group, and the meaning of a
vector. From RFC 8259, the design takes JSON values, with their objects,
members, arrays, strings, numbers, and the literal names `true` and
`false`.

From the Ontology (`ontology`), the design takes trees, items, declared
items and their kinds, decision records, containment (including
`.sinter/` containment), names, current revisions, revised contents,
same items across trees, vector sets, groups of conformance vectors,
sites, tests, external items, objects and their kinds (`object-kind`),
content hashes, content ids, computed identity objects, object
withdrawal and counting voids, statements, judgments, voids, things,
conflicts, encodings, kept objects of the log branch, citation edges of
all five kinds and when an edge says what its kind of edge says, pinned
edges, subjects of approval, approval states, deprecated items
(including the member `status` in `.sinter/`), effective `supersedes`
edges, cycles of `supersedes` edges, retired items, items in force, the
default branch, finding classes, and parameters. From the Object store
(`object-store`), the design takes store files, valid object files,
needed identity files, and the object store of a tree (with its validity
and missing computed identity objects). From Changes (`changes`), it
takes commits, shallow commits, the files of the tree of a commit, the
parameter `default-branch-name` with its bindings, the commit of the
default branch, the change of a commit, the base of the change of a
commit, first-parent lines, repository reads, and undisturbed repository
reads. From Findings (`findings`), it takes finding subjects, spots,
edits, edit sets, edited texts, edited trees, fixes, ackable findings,
finding parts, `findings#limit-fix-edit-sets`, and
`findings#make-no-fixes-on-unreadable-files`.

From Documents (`documents`), the design takes the parameters
`file-readers` and `vector-paths` with their bindings, read files, files
that cannot be read, tag texts, accepted inputs, files of declared
items, sets of names, origins, origin positions, canonical objects,
containment in a tree, kept object sets, vector files, the edges of a
tree with their form runs and form positions, position subjects, edge
finding subjects and declared-item edge spots, the order of positions,
the spots of runs, and tree findings. From Revisions (`revisions`), it
takes base items. From Approval (`approval`), it takes the parameters
`approval-kinds` and `persons` with their bindings, approval needs,
listed persons, latest counting judgments, judgment conflicts, merged
content, subject states, merge-read edges, in force under the bindings,
and incomplete first-parent lines.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [tree](sinter:ontology#tree=v1) | a set of files, each a valid path with a content, such as the tree of a commit or the tree of a working tree |
| base tree | the earlier tree with which a conforming program compares a tree, such as the tree of the base of the change of a commit |
| [object store of a tree](sinter:object-store#tree-object-store=v1) | the set of all store files of a tree (in `.sinter/` and outside `.sinter/local/`), valid when every store file of that tree is a valid object file |
| [content hash](sinter:ontology#content-hash=v1) | the SHA-256 hash of the canonical byte sequence of an object, with no member `id` and no final line feed |
| [content id](sinter:ontology#content-id=v1) | the object kind word of an object, `:`, and the first 32 lowercase hex digits of its content hash |
| [counting void](sinter:ontology#object-withdrawal=v1), [withdrawn](sinter:ontology#object-withdrawal=v1), [replaced](sinter:ontology#object-withdrawal=v1) | a `void` object in `.sinter/` that meets its acceptance rule, carries no `agent`, satisfies `approval#listed-person`, and meets the copy rule; an object named by a counting void's `withdraws` edge; a declared-item object in `.sinter/` named by a `revises` edge of a non-withdrawn declared-item object of the same name or of a counting void of a declared-item kind |
| [kept object set](sinter:documents#kept-object-set=v1) | a caller input holding kept declared-item objects and kept computed identity objects from the log branch, deduplicated by content id |
| [binding of `historical-paths`](sinter:#historical-paths=v1) | a path set; when that path set is valid, the files outside `.sinter/` whose valid paths are in its set are the historical files |
| [historical file](sinter:#historical-file=v1) | a file of a tree whose valid path is in the set of a valid binding of `historical-paths` and is neither a store file nor a local file inside `.sinter/` |
| [retired](sinter:ontology#retired-item=v1), [in force](sinter:ontology#in-force-item=v1) | a declared item is retired in a tree when it is deprecated, when it is the cited item of an effective `supersedes` edge and is on no cycle of `supersedes` edges, or when it belongs to a retired design or specification; a declared item is in force when it is not retired |
| [in force under the bindings](sinter:approval#bound-in-force-item=v1) | in force as the atom `ontology#in-force-item` gives it, under `approval-kinds`, `persons`, `default-branch-name`, `file-readers`, and `external-namespaces` |
| [effective `supersedes` edge](sinter:ontology#effective-supersedes-edge=v1) | a `supersedes` edge that says what `supersedes` says, whose source and every item that holds its source are not deprecated, and whose source is approved |
| [direct replacement](sinter:#successor=v1) | a declared item y directly replaces a declared item x when an effective `supersedes` edge has y as its source and x as its cited item |
| [successor](sinter:#successor=v1) | a declared item in force that replaces a retired declared item through one or more direct replacements, with every intermediate item retired |
| [cycle of `supersedes` and `refines` edges](sinter:#edge-cycle=v1) | a maximal non-empty set of declared items of a tree in which each member reaches each member (itself included) along one or more `supersedes` and `refines` edges that say what their kind of edge says (`supersedes` edges effective or not) |
| [declaration order](sinter:#cycle-finding=v1) | the order of declared items of a tree by the content id of each item's canonical object in code point order, then items in a file before items in no file, then valid path in code point order, and then origin position of the text of the tag line of each item's declaration in the order of positions |
| [anchor member](sinter:#cycle-finding=v1) | among the members of a cycle of `supersedes` and `refines` edges whose name comes first in code point order, the member that comes first in declaration order |
| [base item](sinter:revisions#base-item=v1) | the one declared item of a base tree with the same name in the corresponding set of names, of any kind and in either encoding, when the declared item of the tree is also the one declared item with its name in its set of names |
| [item with a new label](sinter:#new-label-item=v1) | a declared item of a tree that has a current revision, that is not in a historical file, that is in no set of names of that tree with another declared item of the same name, and that either has no base item in the base tree or whose base item has no current revision or a different current revision |
| [incomplete first-parent line](sinter:approval#incomplete-first-parent-line=v1) | a first-parent line of the commit of the default branch of a git repository that is incomplete for the repository reads from which a program takes that first-parent line and the files (read files and store files in `.sinter/` outside `.sinter/local/`) of the trees of the commits of that first-parent line, under a valid binding of `file-readers`, as the term `approval#incomplete-first-parent-line` gives it |
| [cut history](sinter:#cut-history=v1) | a history of the default branch whose first-parent line is incomplete |
| [approval completion](sinter:#approval-completion=v1) | an assignment of approved or not approved to each subject of approval of a tree that keeps the known state of every decided subject of approval and chooses approved or not approved for each undecided subject of approval |
| [tree finding](sinter:documents#tree-finding=v1) | a finding of one tree, with a class, a subject, and either a spot or no spot, that is not ackable |
| [`retired`](sinter:#retired-finding=v1) | the finding class of `cites`, `satisfies`, `verifies`, and `refines` edges that say what their kind of edge says, whose source counts, whose cited item counts as retired, and that do not stand only in historical files; ackable when, and only when, the cited item (or the design or specification of a cited vector set or group) has no successor |
| [`cycle`](sinter:#cycle-finding=v1) | the finding class of the names of the anchor members of cycles of `supersedes` and `refines` edges, when the anchor member is not in a historical file |
| [`deleted-decision`](sinter:#deleted-decision-finding=v1) | the finding class of decision records of a base tree whose name no declared item in the shared set of a tree has |
| [`reused-label`](sinter:#reused-label-finding=v1) | the finding class of items with a new label whose base item in a tree of the first-parent line of the default branch had the same label with a different kind or a different content hash |

## 2. Retirement, cycles, and guarantees over time

### 2.1 Historical paths and historical files

A repository can bind the parameter `historical-paths` to a valid path
set (schema `historical-paths`). The empty path set is a valid binding
under which no file of any tree is historical. `historical-paths`
applies only to text files outside `.sinter/`: the term
`historical-file` gives the historical files of a tree among markdown
files, code files, vector files, and other files outside `.sinter/`. A
store file or local file inside `.sinter/` is never a historical file,
even when the binding of `historical-paths` matches `.sinter/**` or
`**`, and a declared item taken from a valid program's own store with
no file is never in a historical file.

The declared items and edges of a historical file are those that the
terms `documents#item-file` and `documents#tree-edge` give. For example,
when `docs/devlog.md` is a historical file and holds `@cites d1=v1`
where `d2` supersedes `d1`, the edge still exists, and the tree has no
`retired` finding for that edge because its spot lies in a historical
file.

### 2.2 Successors of a retired item

The term `successor` defines the successors of a declared item in a tree
across the text encoding, the `.sinter/` encoding (when the object store
of the tree is valid), and any valid program's own store. Declared
items' status tags come from text `@deprecated` tags and from the
canonical member `status` in `.sinter/` (`ontology#deprecated-item`),
and containment follows `ontology#containment` (`documents#tree-containment`):
in `.sinter/`, a `spec` holds each declared item whose current canonical
object an exact `items` edge names, and a `design` holds each declared
item in `.sinter/` whose name is `<design-name>#<segment>`. Only
`supersedes` edges (cross-item replacement of a declared item by another
declared item, `ontology#supersedes-edge`) enter retirement and
successors; `revises` edges (replacement within one thing, including
earlier revisions of a declared item in `.sinter/`), `items` edges,
`about` edges, and record or `scope` edges never enter retirement or
successors.

A retired declared item can have zero, one, or several successors. These
examples show how the term `successor` works when every item is approved
and no item is deprecated unless stated:

1. **A chain.** Decision record `d2` has `@supersedes d1=v1`, and `d3`
   has `@supersedes d2=v1`. Both `d1` and `d2` are retired, and `d3` is
   in force. The only successor of `d1` is `d3`, and the only successor
   of `d2` is `d3`.
2. **A fork.** Both `d2` and `d3` have `@supersedes d1=v1`, and both are
   in force. The successors of `d1` are `d2` and `d3`.
3. **A diamond.** `d2` and `d3` both supersede `d1`, and `d4` supersedes
   both `d2` and `d3`. The only successor of `d1` is `d4`, given once.
4. **Retirement of parts.** Design `billing-2` has
   `@supersedes billing=v1`. Design `billing` holds the requirements
   `billing#limit` and `billing#legacy`. Design `billing-2` holds the
   requirement `billing-2#limit`, which has
   `@supersedes billing#limit=v1`, and holds no part superseding
   `billing#legacy`. Both `billing#limit` and `billing#legacy` are
   retired because they belong to the retired design `billing`. The only
   successor of `billing#limit` is `billing-2#limit`. Because no
   effective `supersedes` edge cites `billing#legacy`, `billing#legacy`
   has no successor.
5. **Deprecation.** Decision record `d1` carries `@deprecated` (or
   `"status":["deprecated"]` in `.sinter/`), and no effective
   `supersedes` edge cites `d1`. Then `d1` is retired and has no
   successor. When `d3` has `@supersedes d2=v1` and `d3` is deprecated,
   the edge from `d3` is not effective, so `d2` is in force and has no
   successor.
6. **A cycle inside a retired design.** Design `old` is superseded by
   `new`, so `old#p` and `old#q` are retired because they belong to the
   retired design `old`. Inside `old`, `old#p` has `@supersedes
   old#q=v1` and `old#q` has `@supersedes old#p=v1`. Both edges stay
   effective because neither source nor `old` is deprecated. No chain of
   direct replacements from `old#p` or `old#q` reaches an item in force,
   so neither `old#p` nor `old#q` has a successor. If `new#q` also has
   an effective `@supersedes old#q=v1` and is in force, the only
   successor of both `old#p` and `old#q` is `new#q`.
7. **An edge into an in-force cycle.** Items `y` and `z` supersede each
   other and are neither deprecated nor in a retired design, so both `y`
   and `z` are in force. Item `y` also has an effective
   `@supersedes x=v1`, so `x` is retired. Because `y` is in force, the
   only successor of `x` is `y`, and not `z` (term `successor`).

### 2.3 Findings of the class `retired` and offered fixes

The atom `retired-finding` gives the findings of the class `retired`.
That atom refines `ontology#retired-item`. Only citation edges of the
kinds `cites`, `satisfies`, `verifies`, and `refines`
(`documents#tree-edge`) whose targets are neither missing parts nor
ambiguous pins give `retired` findings; `supersedes` edges, structural
edges (`items`, `about`, `revises`), record and `scope` edges, and edges
of replaced or withdrawn declared-item objects in `.sinter/` give no
`retired` finding.

Citations resolve, and give their cited items, as `ontology#edge` and
`documents#tree-edge` give them, across both encodings and the kept
object set. For example, `@cites name:…` means `=*` of that name; a text
`@cites pin:…` and a stored `"to":"pin:…"` edge in `.sinter/` resolve as
`n=l` when an input holds that `pin` object `(n, l)`; a text citation of
an unknown `pin:` content id has no cited item; and an edge on a pin
cycle still cites the declared item of name `n`. An edge whose target is
an ambiguous pin or a missing part withholds its cited item.

For example, design `billing-2` has `@supersedes billing=v1`,
`billing-2#limit` has `@supersedes billing#limit=v1`, and `billing-2`
and `billing-2#limit` are approved and in force. Each of these gives one
`retired` finding when its file is not historical:

- a sentence in `docs/guide.md` with `@cites billing#limit=v1` (a site
  always counts as a source; not ackable because `billing#limit` has the
  successor `billing-2#limit`);
- a function in `src/limit.ml` with `@satisfies billing#limit=v1` (a
  site always counts; not ackable);
- a test with `@verifies billing#limit=v1` (a test always counts; not
  ackable);
- an in-force requirement `quota#soft-limit` with
  `@refines billing#limit=v1` (subject is the edge finding subject
  `<source-content-id> refines <target-content-id>`; not ackable);
- a test with `@verifies billing[limits]` (the group `billing[limits]`
  counts as retired because `billing` is retired; not ackable because
  `billing` has the successor `billing-2`);
- a test with `@verifies deprecated-design[rows]` where
  `deprecated-design` is `@deprecated` with no successor (ackable
  because `deprecated-design` has no successor);
- in `billing-2.test-vectors.jsonl`, a vector line whose `"form"` is
  `"#old-schema=v1"` when `billing-2#new-schema` effectively supersedes
  `billing-2#old-schema` (`billing-2` is in force, so its vector group
  counts as a source; not ackable).

By contrast, each of these gives no `retired` finding:

- the `supersedes` edge from `billing-2` to `billing`, or a `revises`
  edge in `.sinter/`;
- `@cites billing#window=v1` inside `billing#limit`, because the source
  `billing#limit` is retired;
- a vector line in `billing.test-vectors.jsonl`, because the item of the
  kind `design` `billing` of that vector set is retired;
- a `@cites` edge to an external item such as `rfc/8259`, because an
  external item meets neither condition for counting as retired
  (`retired-finding`);
- an edge that does not say what its kind of edge says, such as
  `@satisfies d1=v1` to a retired decision record;
- a citation to an undeclared name or an unknown `pin:` content id in
  text, because that edge has no cited item in the tree.

A `retired` finding is ackable (`findings#ackable-finding`) when, and
only when, its cited item has no successor (for a cited vector set or
group of conformance vectors, when the design or specification of that
vector set has no successor).

No requirement obliges a conforming program to offer a fix for a
`retired` finding. Fixes are text edits in place only: a conforming
program offers no fix for a `retired` finding of a stored edge in
`.sinter/`, of an edge from a program's own store, or of a finding with
no spot, and never alters or deletes a file of `.sinter/`. When a
conforming program makes a fix, `findings#make-no-fixes-on-unreadable-files`
binds always: in an execution in which a program could not read a file
or a folder (a missing part under `conformance#input`), the program
makes no fix in any tree.

When a program offers a fix for a `retired` finding whose cited item has
successors and whose edge stands in a text file or a vector file with a
spot, the requirement `limit-retired-fix-edit-sets` limits its edit
sets. For example, suppose that `billing-2#limit` has an effective
`@supersedes billing#limit=v1`, that `billing-2#limit` is in force at
`v1`, and that `billing#window` is in force. When `docs/guide.md` holds
`@cites billing#{limit=v1, window=v1}`, `billing#limit` has the single
successor `billing-2#limit`, so a fix that meets
`limit-retired-fix-edit-sets` has one edit set. That edit set edits only
that tag line so that it cites `billing-2#limit=v1` and
`billing#window=v1`, for example
`@cites {billing-2#limit=v1, billing#window=v1}`. When the cited item
has two successors `d3` and `d4`, a fix that meets
`limit-retired-fix-edit-sets` has two edit sets, first for `d3` and then
for `d4`, in code point order of their names. When the original edge is
unpinned (`@cites billing#limit=*` or `@cites name:…`), the edge in the
edited citation stays unpinned (`@cites billing-2#limit=*`). When a
`retired` finding is on a vector line whose group holds several vector
lines, each edit set of a fix that meets `limit-retired-fix-edit-sets`
rewrites the form pin of every vector line of that group so that the
edited vector file stays a test-vector set. When the cited item has no
successor (for example a `@deprecated` record or a retired vector group
whose design has no successor) and the finding has a spot with a span in
a text file, `limit-retired-fix-edit-sets` adds no condition beyond
`findings#limit-fix-edit-sets` (so an edit set may add an acknowledgment
in a text file).

For example, in these cases, no edit of the citation or form pin meets
`limit-retired-fix-edit-sets` for a successor of the retired item, so a
conforming program offers no fix for that finding:

1. **A form pin that cannot name the successor.** A vector line in
   `billing.test-vectors.jsonl` has `"form":"#row=v1"`, and schema
   `billing-2#row` (in another design) or `billing#spec-row` (in a
   specification of `billing` while the vector set is of `billing`
   itself) supersedes `billing#row`. By `ontology#edge`, a form pin in
   `billing.test-vectors.jsonl` can name only a schema that `billing`
   holds directly, so no edit of the form pin can cite that successor.
2. **A pinned citation to a term with no label.** Design `billing`
   declares `@term rate=v1`, design `billing-2` declares `@term rate`
   with no label and `@supersedes billing#rate=v1`, and `docs/guide.md`
   holds `@cites billing#rate=v1`. Because `billing-2#rate` has no
   current revision, no edit can write its current revision in place of
   the pin.
3. **A successor with a duplicate name.** Two declared items of the
   tree have the name `d2`, and one or both supersede `d1`. An edge
   whose target has the name of two or more declared items of the tree
   has no cited item (`ontology#edge`), so no edit of the citation can
   cite that successor.
4. **A stored edge in `.sinter/` or a finding with no spot.** A declared
   item stored in `.sinter/` holds a `cites` edge to a retired item, or
   a text declared item writes two citations that give the same
   canonical edge (so the finding has no spot). Because fixes edit only
   text files at a spot with a span, no fix is allowed.

The same consequence holds when a retired item has two successors and
only one of them fails one of these conditions: because a fix that meets
`limit-retired-fix-edit-sets` has one edit set for each successor, a
conforming program offers no fix for that finding.

### 2.4 Findings of the class `cycle`

The term `edge-cycle` defines a cycle of `supersedes` and `refines`
edges in a tree (across both encodings, ignoring `revises` and other
non-citation edges), and the atom `cycle-finding` gives the findings of
the class `cycle`.

For example, each of these gives one `cycle` finding when its anchor
member is not in a historical file:

- `d1` has `@supersedes d2=v1` and `d2` has `@supersedes d1=v1` (subject
  `d1`);
- requirement `r` has `@supersedes r=v1` and reaches no other item that
  reaches it (subject `r`);
- atom `x` has `@refines y=v1` and atom `y` has `@refines x=v1`
  (subject `x`);
- requirement `r1` has `@supersedes r2=v1` and `r2` has
  `@refines r1=v1` (subject `r1`);
- `a` and `b` supersede each other while `b` and `c` refine each other:
  all three reach each other, so they form one cycle `{a, b, c}`
  (subject `a`);
- inside a deprecated design `old`, `old#p` and `old#q` supersede each
  other (subject `old#p`).

When `old#p` is in a historical text file and `old#q` is not, the anchor
member is `old#p`, so the cycle gives no `cycle` finding. When `old#q`
is in a historical text file and `old#p` is not, the anchor member is
`old#p`, so the tree still has the `cycle` finding. When `old#p` is a
stored declared item in `.sinter/`, `historical-paths` never makes its
file historical, so the tree has the `cycle` finding with the valid path
of that store file alone as its spot. When two members of a cycle share
the first name in code point order, declaration order (ordered by
content id first, then file presence, valid path, and origin position)
chooses the anchor member (atom `cycle-finding`).

### 2.5 Deleted decision records

The atom `deleted-decision-finding` gives the findings of the class
`deleted-decision` for a tree against a base tree, using the shared set
(`documents#name-set`) across both encodings. Only declared items of a
tree enter its shared set: a leftover `name` computed identity object in
`.sinter/` or in `kept-object-set` is not a declared item and never
keeps a name in the shared set. A decision record stored in `.sinter/`
of the base tree leaves the declared items of the tree through a
counting void (`ontology#object-withdrawal`, under
`approval#listed-person`) — or if its file is absent from the tree —
while a void that does not count withdraws nothing, and revising a
stored decision record with a newer `decision` object of the same name
keeps that name in the shared set.

For example, when a change deletes the text file of
`@decision rust-bridge=v1`, withdraws a stored decision record
`rust-bridge` in `.sinter/` with a counting void, or renames
`@decision parser-bridge=v1` to `@decision wasm-bridge=v1`, the tree has
one `deleted-decision` finding (`rust-bridge` or `parser-bridge`).
Moving a decision record between folders or between the text encoding
and `.sinter/` with the same name keeps that name in the shared set and
gives no finding. Changing `@decision x=v1` to `@req x=v1` in the shared
set keeps the name `x` in the shared set (`ontology#same-item`) and
gives no `deleted-decision` finding. When the text file of
`@decision rust-bridge=v1` stays at the same valid path with content
that is not valid UTF-8, the tree still has the `deleted-decision`
finding `rust-bridge`.

A `deleted-decision` finding has no spot, because the finding names a
decision record whose name no declared item in the shared set of the
tree has. Therefore, `deleted-decision` findings do not depend on
`historical-paths`, and no binding of `historical-paths`, valid or not,
removes a `deleted-decision` finding. The requirements
`compare-change-for-deleted-decisions`, `report-missing-base`, and
`omit-missing-base-report` cover the change of a commit.

### 2.6 Reused labels

The term `new-label-item` selects the declared items of a tree (across
both encodings) that the atom `reused-label-finding` compares. That atom
compares each such item against a sequence of trees by
`revisions#base-item` (aligned with `ontology#same-item` across kinds
and encodings) using the content hash of each item's canonical object
(`ontology#content-hash`). For the change of a commit, that sequence is
the trees of the commits of the first-parent line of the commit of the
default branch.

For example, on the default branch, `@req billing#size` had label `v2`
with canonical content hash H1, and later moved to label `v3` with
canonical content hash H2. The base tree of a branch holds
`billing#size=v3`.

- Moving `billing#size` back to `v2` with a new canonical content hash
  H3 gives one `reused-label` finding with subject `billing#size`.
- Moving `billing#size` back to `v2` with the exact same kind and exact
  same canonical content hash H1 (even after moving between text and
  `.sinter/`) gives no `reused-label` finding.
- Deleting `billing#size` in one change and declaring
  `@req billing#size=v2` with a new canonical content hash in a later
  change gives one `reused-label` finding, because `billing#size` has no
  base item in the later change's base tree.
- An older label reuse on an untouched item `old=v1` gives no
  `reused-label` finding, because `old` keeps its base label and is not
  an item with a new label.
- A term with no label is never an item with a new label and gives no
  `reused-label` finding.
- A tree on the first-parent line that holds two items with the name
  `billing#size` gives `billing#size` no base item in that tree and
  therefore no comparison against that tree.
- A historical text file in a tree of the first-parent line is still
  read for the labels and content hashes of its declared items;
  `historical-paths` only prevents findings for text items whose file in
  the checked tree is historical, and never prevents findings for stored
  items in `.sinter/` or items from a program's own store.

For the change of a commit, the requirements
`compare-change-for-reused-labels`, `report-missing-base`,
`omit-missing-base-report`, `report-cut-history`, and
`omit-cut-history-report` state what a conforming program gives when the
change has no base, when the program does not give the findings of the
class `reused-label`, when the tree of the commit has no item with a new
label, or when the history of the default branch is cut (term
`cut-history`).

### 2.7 Bindings, stores, incomplete histories, and concurrent changes

Each definition and each requirement uses one binding of each parameter,
one set of kept objects (`documents#kept-object-set`), and valid object
stores (`object-store#tree-object-store`, or valid program's own
stores). When the object store of a tree is not valid, a conforming
program gives no result over the objects of that tree
(`conformance#reject-invalid-inputs`). The requirement
`omit-findings-under-invalid-historical-paths` covers a binding of
`historical-paths` that is not valid. Successors and `deleted-decision`
findings do not depend on `historical-paths`.

Successors and the class `retired` read in force under the bindings
(`approval#bound-in-force-item`), which reads `approval` and `decline`
statements and `void` statements from the valid object store of the tree
under the optional parameter `persons` (`approval#persons`,
`approval#listed-person`). Non-counting statements (unaccepted
statements, withdrawn statements, judgments or voids carrying `agent`,
and judgments or voids whose `by` is not in a valid binding of
`persons`) do not count, and conflicting latest `approval` and `decline`
judgments decide nothing (leaving the subject `neither`, not approved).
The classes `cycle`, `deleted-decision`, and `reused-label` read no
approval judgments, and depend on `persons` only through whether a
`void` statement in `.sinter/` counts (`ontology#object-withdrawal`).
Under a binding of `persons` that does not meet `approval#persons`, a
conforming program gives every result that holds identically under every
valid binding of `persons` and when `persons` is unbound, and withholds
every result whose value depends on `persons`.

A missing computed identity object in `.sinter/` or on the log branch is
a missing part (`object-store#tree-object-store`, `conformance#input`)
when no valid input of the run supplies that identity object or its key.
A conforming program withholds only the results that need that missing
key (or an edge whose target is an ambiguous pin or a missing part) and
still gives every result that does not need it
(`conformance#report-missing-parts`). When another valid input of the
run gives that computed identity object or its key, the run does not
lack that part.

The term `approval-completion` and the requirements `give-successors`,
`give-retired-findings`, and `limit-retired-fix-edit-sets` state what a
conforming program gives when the first-parent line of the commit of the
default branch is incomplete (`approval#incomplete-first-parent-line`,
covering both read files and store files in `.sinter/` outside
`.sinter/local/`) or when the binding of `default-branch-name` is not
valid: any successor or `retired` finding that does not depend on an
undecided subject of approval is still given, and any result that
depends on one is omitted; when the cause is an incomplete first-parent
line, the program reports that it cannot see the whole history.

What a program gives while another process changes a file or a ref is a
matter of the quality of an implementation.

### 2.8 Findings

Each finding of the classes `cycle`, `deleted-decision`, and
`reused-label` is a [tree finding](sinter:documents#tree-finding=v1) and
is not ackable. A finding of the class `retired` is a finding of its
tree (`findings#finding-part`) that is ackable
(`findings#ackable-finding`) when, and only when, its cited item has no
successor (for a cited vector set or group of conformance vectors, when
the design or specification of that vector set has no successor), as the
atom `retired-finding` gives. Finding classes and subjects for declared
items and their edges come only from canonical objects, while spots
follow the encoding (run spots in text files, valid paths alone with no
span in `.sinter/`, and no spot from a program's own store); edges from
tests, sites, and vector lines keep position subjects and run spots.

| class | atom | ackable |
|---|---|---|
| `retired` | [`retired-finding`](sinter:#retired-finding=v1) | when the cited item (or vector set's design or specification) has no successor |
| `cycle` | [`cycle-finding`](sinter:#cycle-finding=v1) | no |
| `deleted-decision` | [`deleted-decision-finding`](sinter:#deleted-decision-finding=v1) | no |
| `reused-label` | [`reused-label-finding`](sinter:#reused-label-finding=v1) | no |

## 3. Parameters

### 3.1 `historical-paths`

@schema historical-paths=v1
@cites {
    files#{path-set=v1, valid-path-set=v1},
    ontology#{parameter=v1},
    text#{code-span=v1},
}

A binding of the parameter `historical-paths` is a path set. A binding
of `historical-paths` meets the schema `historical-paths` when, and only
when, that path set is a valid path set.

## 4. Definitions

### 4.1 Historical files

@term historical-file=v1
@cites {
    files#{path=v1, path-set=v1, path-set-membership=v1},
    ontology#{tree=v1, parameter=v1},
    object-store#{store-file=v1},
    text#{code-span=v1},
    #{historical-paths=v1},
}

Under a valid binding H of `historical-paths`, a file of a tree is a
historical file of that tree under H when, and only when, both of these
conditions hold:

1. The valid path of that file is in the set of H.
2. That file is neither a store file nor a local file of that tree
   (term `object-store#store-file`).

A declared item taken from a valid program's own store with no file is
not in a historical file of any tree under any binding of
`historical-paths`.

### 4.2 Successors of a retired item

@term successor=v1
@cites {
    conformance#{own-store=v1},
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        declared-item=v1, item=v1, edge=v1, supersedes-edge=v1,
        effective-supersedes-edge=v1, retired-item=v1, in-force-item=v1,
        deprecated-item=v1, containment=v1, object-withdrawal=v1,
        vector-set=v1, conformance-vector-group=v1, default-branch=v1,
        tree=v1, parameter=v1, encoding=v1, log-branch=v1,
    },
    object-store#{tree-object-store=v1},
    changes#{
        commit=v1, default-branch-name=v1, default-branch-commit=v1,
        first-parent-line=v1,
    },
    documents#{
        file-readers=v1, kept-object-set=v1, tree-edge=v1,
        tree-containment=v1,
    },
    approval#{
        approval-kinds=v1, persons=v1, merge-read-edge=v1,
        bound-in-force-item=v1,
    },
    text#{sequence=v1, result=v1, code-span=v1},
}

This term is for a git repository R, a valid binding A of
`approval-kinds`, `persons` unbound or bound to a valid binding L
(schema `approval#persons`), a valid binding F of `file-readers`, a
binding N of `external-namespaces` for which a conforming program of the
design Identifiers gives the result "valid", a set K of kept objects
(`documents#kept-object-set`), a tree T whose object store is valid
(`object-store#tree-object-store`, or a valid program's own store), and,
when T has a `supersedes` edge that reads a merge under A
(`approval#merge-read-edge`), a valid binding D of
`default-branch-name`.

In this term, declared items (neither withdrawn nor replaced under
`ontology#object-withdrawal`), status tags (in text and from the member
`status` in `.sinter/` per `ontology#deprecated-item`), containment
(`ontology#containment`, `documents#tree-containment`), and citation
edges (`documents#tree-edge`) come from both encodings of T (or from a
valid program's own store) under F, N, K, and `persons`. In force in T
under these inputs is as `approval#bound-in-force-item` gives it, and a
declared item of T is retired in T under these inputs when it is not in
force there. A `supersedes` edge of T under F, N, K, and `persons` is
effective in T under these inputs when that edge is effective in T (atom
`ontology#effective-supersedes-edge`), read as
`approval#bound-in-force-item` gives. Only `supersedes` edges (whose
targets are neither missing parts nor ambiguous pins) enter direct
replacement; `revises` edges, structural edges (`items`, `about`), and
edges of records or `scope` objects never enter direct replacement.

A declared item y of T directly replaces a declared item x of T in T
under these inputs when, and only when, some `supersedes` edge of T is
effective in T under these inputs, has y as its source, and has x as its
cited item.

For a declared item x of T that is retired in T under these inputs, a
declared item s of T is a successor of x in T under these inputs when,
and only when, both of these conditions hold:

1. s is in force in T under these inputs.
2. There is a finite sequence of one or more pairs (u, v) of declared
   items of T that meets all three of these conditions:
   - the first item of the first pair is x, and the second item of the
     last pair is s;
   - for each pair (u, v) of the sequence, v directly replaces u in T
     under these inputs;
   - for each pair before the last, its second item is the first item of
     the next pair, and that item is retired in T under these inputs.

A declared item of T that is in force in T under these inputs has no
successor. An item of T that is not a declared item, such as a group of
conformance vectors or a vector set, has no successor.

### 4.3 Findings of the class `retired`

@atom retired-finding=v1
@refines ontology#retired-item=v1
@cites {
    conformance#{own-store=v1},
    identifiers#{
        external-namespaces=v1, validate-bindings=v1, citation-entry=v1,
        inline-citation=v1,
    },
    data-forms#{vector-line=v1},
    ontology#{
        declared-item=v1, edge=v1, cites-edge=v1, satisfies-edge=v1,
        verifies-edge=v1, refines-edge=v1, vector-set=v1,
        conformance-vector-group=v1, deprecated-item=v1, containment=v1,
        object-withdrawal=v1, object=v1, content-id=v1, default-branch=v1,
        tree=v1, parameter=v1, encoding=v1, log-branch=v1,
    },
    object-store#{tree-object-store=v1},
    changes#{
        commit=v1, default-branch-name=v1, default-branch-commit=v1,
        first-parent-line=v1,
    },
    findings#{ackable-finding=v1, finding-part=v1},
    documents#{
        file-readers=v1, vector-paths=v1, kept-object-set=v1,
        item-file=v1, canonical-object=v1, tree-edge=v1,
        tree-containment=v1, origin=v1, origin-position=v1,
        position-subject=v1, edge-finding-subject=v1, run-spot=v1,
    },
    approval#{
        approval-kinds=v1, persons=v1, merge-read-edge=v1,
        bound-in-force-item=v1,
    },
    text#{result=v1, code-span=v1},
    #{historical-paths=v1, historical-file=v1, successor=v1},
}

This atom is for a git repository R, a valid binding A of
`approval-kinds`, `persons` unbound or bound to a valid binding L
(schema `approval#persons`), a valid binding F of `file-readers`, a
valid binding V of `vector-paths`, a binding N of `external-namespaces`
for which a conforming program of the design Identifiers gives the
result "valid", a set K of kept objects (`documents#kept-object-set`), a
valid binding H of `historical-paths`, a tree T whose object store is
valid (`object-store#tree-object-store`, or a valid program's own
store), and, when T has a `supersedes` edge that reads a merge under A
(`approval#merge-read-edge`), a valid binding D of
`default-branch-name`.

In this atom, edges of T are the citation edges (`documents#tree-edge`)
across both encodings (or from a valid program's own store) under F, V,
N, K, and `persons` whose targets are neither missing parts nor
ambiguous pins (`ontology#edge`, `documents#canonical-object`).
Structural edges (`items`, `about`, `revises`), record and `scope`
edges, and edges of replaced or withdrawn declared-item objects in
`.sinter/` give no finding of the class `retired`.

A source of an edge of T counts in T under these inputs when, and only
when, one of these three conditions holds:

1. The source is a declared item of T that is in force in T under these
   inputs (`approval#bound-in-force-item`).
2. The source is a group of conformance vectors of a vector set of T,
   and the item of the kind `design` or of the kind `spec` of that
   vector set is in force in T under these inputs
   (`approval#bound-in-force-item`).
3. The source is neither a declared item nor a group of conformance
   vectors (a test or a site).

A cited item of an edge of T counts as retired in T under these inputs
when, and only when, one of these two conditions holds:

1. The cited item is a declared item of T that is not in force in T
   under these inputs (`approval#bound-in-force-item`).
2. The cited item is a vector set of T, or a group of conformance
   vectors of a vector set of T, and the item of the kind `design` or of
   the kind `spec` of that vector set is not in force in T under these
   inputs (`approval#bound-in-force-item`).

Under these inputs, T has one finding of the class `retired`
(`findings#finding-part`, with tree T and class `retired`):

- for each canonical citation edge e whose source is a declared item of
  T and that meets all four of these conditions:
  1. e is of the kind `cites`, `satisfies`, `verifies`, or `refines`,
     and e says what its kind of edge says in T;
  2. the source of e counts in T under these inputs;
  3. the cited item of e counts as retired in T under these inputs;
  4. at least one declared item of T whose canonical object is the
     canonical object of the source of e is not in a historical file of
     T under H (a stored declared item in `.sinter/` or a declared item
     from a valid program's own store is never in a historical file);
- for each edge e whose source is a test, a site, or a group of
  conformance vectors (from a vector line) and that meets all four of
  these conditions:
  1. e is of the kind `cites`, `satisfies`, `verifies`, or `refines`,
     and e says what its kind of edge says in T;
  2. the source of e counts in T under these inputs;
  3. the cited item of e counts as retired in T under these inputs;
  4. the file of e in T is not a historical file of T under H.

The subject and the spot of that finding follow the source of e:

- For a canonical citation edge e whose source is a declared item, the
  subject of that finding is the edge finding subject of e
  (`documents#edge-finding-subject`), and the spot of that finding is
  the declared-item edge spot of e in T
  (`documents#edge-finding-subject`).
- For an edge e that a citation entry or an inline citation standing in
  a test or in a site gives, the subject of that finding is the position
  subject of the origin position of that citation entry or inline
  citation (`documents#position-subject`), and the spot of that finding
  is the spot of the run of that citation entry or inline citation in
  the text of the file of e (`documents#run-spot`).
- For an edge e that a vector line gives, the subject of that finding is
  the position subject of the form position of e in the vector file of e
  (`documents#position-subject`), and the spot of that finding is the
  spot of the form run of e in the text of that vector file
  (`documents#run-spot`).

The message, the mark, the related messages, and the fix of that finding
are those that the program that gives that finding gives. That finding
is ackable (`findings#ackable-finding`) when, and only when, one of
these two conditions holds:

1. The cited item of e is a declared item of T and has no successor in T
   under these inputs (term `successor`).
2. The cited item of e is a vector set of T, or a group of conformance
   vectors of a vector set of T, and the item of the kind `design` or of
   the kind `spec` of that vector set has no successor in T under these
   inputs (term `successor`).

Otherwise, that finding is not ackable.

### 4.4 Cycles of `supersedes` and `refines` edges

@term edge-cycle=v1
@cites {
    conformance#{own-store=v1},
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        declared-item=v1, edge=v1, supersedes-edge=v1, refines-edge=v1,
        object-withdrawal=v1, tree=v1, parameter=v1, encoding=v1,
        log-branch=v1,
    },
    object-store#{tree-object-store=v1},
    documents#{file-readers=v1, kept-object-set=v1, tree-edge=v1},
    approval#{persons=v1},
    text#{sequence=v1, result=v1, code-span=v1},
}

This term is for a tree T whose object store is valid
(`object-store#tree-object-store`, or a valid program's own store), a
valid binding F of `file-readers`, a binding N of `external-namespaces`
for which a conforming program of the design Identifiers gives the
result "valid", a set K of kept objects (`documents#kept-object-set`),
and `persons` unbound or bound to a valid binding L (schema
`approval#persons`).

In T under these inputs, a pair (x, y) of declared items of T (across
both encodings, neither withdrawn nor replaced under
`ontology#object-withdrawal`) is a cycle step when, and only when,
either of these two conditions holds for a citation edge of T
(`documents#tree-edge`, whose target is neither a missing part nor an
ambiguous pin):

- some `supersedes` edge of T says what the kind of edge `supersedes`
  says in T, with x as its source and y as its cited item;
- some `refines` edge of T says what the kind of edge `refines` says in
  T, with x as its source and y as its cited item.

Edges of kind `revises`, structural edges (`items`, `about`), record and
`scope` edges, and edges of replaced or withdrawn declared-item objects
in `.sinter/` never form cycle steps.

A declared item a of T reaches a declared item b of T along cycle steps
in T under these inputs when, and only when, there is a finite sequence
of one or more cycle steps of T whose first pair has a as its first
item, whose last pair has b as its second item, and in which, for each
pair before the last, its second item is the first item of the next
pair.

A cycle of `supersedes` and `refines` edges in T under these inputs is a
non-empty set C of declared items of T that meets both of these
conditions:

1. For each declared item a in C and each declared item b in C
   (including when a and b are the same declared item), a reaches b
   along cycle steps in T under these inputs.
2. No set of declared items of T that holds every declared item of C and
   at least one other declared item of T meets condition 1.

### 4.5 Findings of the class `cycle`

@atom cycle-finding=v1
@cites {
    conformance#{own-store=v1},
    files#{path=v1},
    identifiers#{
        external-namespaces=v1, validate-bindings=v1, declaration=v1,
        tag-line-text=v1,
    },
    ontology#{
        declared-item=v1, item-name=v1, object=v1, content-id=v1,
        tree=v1, parameter=v1, encoding=v1, log-branch=v1,
    },
    object-store#{valid-object-file=v1, tree-object-store=v1},
    findings#{spot=v1},
    documents#{
        file-readers=v1, kept-object-set=v1, item-file=v1,
        canonical-object=v1, origin=v1, origin-position=v1,
        position-order=v1, run-spot=v1, tree-finding=v1,
    },
    approval#{persons=v1},
    text#{code-point-order=v1, position=v1, text=v1, result=v1, code-span=v1},
    #{historical-paths=v1, historical-file=v1, edge-cycle=v1},
}

In this atom, one declared item d1 of a tree T comes before another
declared item d2 of T in declaration order when, and only when, one of
these four conditions is true:

1. The content id of the canonical object of d1 comes before the content
   id of the canonical object of d2 in code point order.
2. Those two content ids are equal, d1 stands in a file of T (a read
   file or a valid object file of `.sinter/`), and d2 stands in no file
   of T (comes from a valid program's own store with no file).
3. Those two content ids are equal, both d1 and d2 stand in files of T,
   and the valid path of the file of d1 comes before the valid path of
   the file of d2 in code point order.
4. Those two content ids are equal, both d1 and d2 stand in the same
   text file of T, and the origin position of the text of the tag line
   of the declaration of d1 comes before the origin position of the text
   of the tag line of the declaration of d2 in the order of positions.

For a tree T whose object store is valid
(`object-store#tree-object-store`, or a valid program's own store), a
valid binding F of `file-readers`, a binding N of `external-namespaces`
for which a conforming program of the design Identifiers gives the
result "valid", a set K of kept objects (`documents#kept-object-set`),
`persons` unbound or bound to a valid binding L (schema
`approval#persons`), and a valid binding H of `historical-paths`, the
anchor member of a cycle C of `supersedes` and `refines` edges in T
under these inputs is this: among the declared items of C whose name in
T comes first in code point order among the names in T of all declared
items of C, the declared item that comes first in declaration order.

Under these inputs, T has one tree finding of the class `cycle` for each
text s that is the name in T of the anchor member of at least one cycle
of `supersedes` and `refines` edges in T under these inputs whose anchor
member is not in a historical file of T under H (a stored declared item
in `.sinter/` or a declared item from a valid program's own store is
never in a historical file). The subject of that tree finding is s.
Among all anchor members of cycles of `supersedes` and `refines` edges
in T under these inputs whose name in T is s and that are not in a
historical file of T under H, let d be the declared item that comes
first in declaration order. The spot of that tree finding follows the
input from which d comes:

- when d is in the text encoding in T, the spot of the run of the text
  of the tag line of the declaration of d in the text of the file of d
  in T (`documents#run-spot`);
- when d is in the `.sinter/` encoding in T, the spot that is the valid
  path of the valid object file of d in T alone, with no span;
- when a program takes d from a valid program's own store with no file
  in T, no spot.

### 4.6 Findings of the class `deleted-decision`

@atom deleted-decision-finding=v1
@cites {
    conformance#{own-store=v1},
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        declared-item=v1, decision-record=v1, item-name=v1, same-item=v1,
        object-withdrawal=v1, computed-identity=v1, tree=v1,
        parameter=v1, encoding=v1,
    },
    object-store#{tree-object-store=v1},
    documents#{
        file-readers=v1, item-file=v1, name-set=v1, tree-finding=v1,
    },
    approval#{persons=v1},
    text#{text=v1, result=v1, code-span=v1},
}

For a tree T and a base tree B (each with a valid object store under
`object-store#tree-object-store`, or from valid program's own stores),
under a valid binding F of `file-readers`, a binding N of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", and `persons` unbound or bound to
a valid binding L (schema `approval#persons`), the declared items, their
kinds, their names, and the sets of names of T and of B are those that T
and B have across both encodings under F, N, and `persons`
(`documents#item-file`, `documents#name-set`,
`ontology#object-withdrawal`). A computed identity object (such as a
`name` object in `.sinter/`) is not a declared item and never appears in
the shared set of T. A decision record stored in `.sinter/` of B that a
counting void withdraws in T (`ontology#object-withdrawal`) is not a
declared item of T.

Under these inputs, T has one tree finding of the class
`deleted-decision` against B for each text t that is the name in B of a
decision record of B such that no declared item in the shared set of T
(of any kind and in either encoding, `ontology#same-item`) has a name in
T that is the same text as t.

The subject of that tree finding is t. That tree finding has no spot.

### 4.7 Items with new labels

@term new-label-item=v1
@cites {
    conformance#{own-store=v1},
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        declared-item=v1, item-name=v1, item-revision=v1,
        object-withdrawal=v1, containment=v1, tree=v1, parameter=v1,
        encoding=v1,
    },
    object-store#{tree-object-store=v1},
    documents#{
        file-readers=v1, item-file=v1, name-set=v1, tree-containment=v1,
    },
    revisions#{base-item=v1},
    approval#{persons=v1},
    text#{text=v1, result=v1, code-span=v1},
    #{historical-paths=v1, historical-file=v1},
}

For a tree T and a base tree B (each with a valid object store under
`object-store#tree-object-store`, or from valid program's own stores),
under a valid binding F of `file-readers`, a binding N of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", `persons` unbound or bound to a
valid binding L (schema `approval#persons`), and a valid binding H of
`historical-paths`, a declared item d of T (across both encodings under
F, N, and `persons`) is an item with a new label against B under these
inputs when, and only when, all four of these conditions hold:

1. d has a current revision in T.
2. d is not in a historical file of T under H (a stored declared item in
   `.sinter/` or a declared item from a valid program's own store is
   never in a historical file).
3. For each set of names of T in which d is, no other declared item in
   that set of names has a name in T that is the same text as the name
   of d in T.
4. Either d has no base item in B (`revisions#base-item`), or the base
   item e of d in B has no current revision in B or has a current
   revision in B that is not the same text as the current revision of d
   in T.

### 4.8 Findings of the class `reused-label`

@atom reused-label-finding=v1
@cites {
    conformance#{own-store=v1},
    identifiers#{
        external-namespaces=v1, validate-bindings=v1, declaration=v1,
        tag-line-text=v1,
    },
    ontology#{
        declared-item=v1, item-name=v1, item-revision=v1,
        revised-content=v1, object=v1, content-hash=v1, same-item=v1,
        containment=v1, object-withdrawal=v1, tree=v1, parameter=v1,
        encoding=v1, log-branch=v1,
    },
    object-store#{valid-object-file=v1, tree-object-store=v1},
    findings#{spot=v1},
    documents#{
        file-readers=v1, kept-object-set=v1, item-file=v1,
        canonical-object=v1, origin=v1, run-spot=v1, tree-finding=v1,
    },
    revisions#{base-item=v1},
    approval#{persons=v1},
    text#{text=v1, sequence=v1, result=v1, code-span=v1},
    #{historical-paths=v1, new-label-item=v1},
}

For a tree T, a base tree B, and a finite sequence L of trees (each with
a valid object store under `object-store#tree-object-store`, or from
valid program's own stores), under a valid binding F of `file-readers`,
a binding N of `external-namespaces` for which a conforming program of
the design Identifiers gives the result "valid", a set K of kept objects
(`documents#kept-object-set`), `persons` unbound or bound to a valid
binding P (schema `approval#persons`), and a valid binding H of
`historical-paths`, T has one tree finding of the class `reused-label`
against B and L for each declared item d of T (across both encodings)
that meets both of these conditions:

1. d is an item with a new label against B under these inputs.
2. For at least one element M of L, d has a base item e in M
   (`revisions#base-item`), e has a current revision in M that is the
   same text as the current revision of d in T, and either d and e are
   of different kinds of item or the content hash of the canonical
   object of d in T (`ontology#content-hash`) is not the content hash of
   the canonical object of e in M.

The subject of that tree finding is the name of d in T. The spot of that
tree finding follows the input from which d comes:

- when d is in the text encoding in T, the spot of the run of the text
  of the tag line of the declaration of d in the text of the file of d
  in T (`documents#run-spot`);
- when d is in the `.sinter/` encoding in T, the spot that is the valid
  path of the valid object file of d in T alone, with no span;
- when a program takes d from a valid program's own store with no file
  in T, no spot.

### 4.9 Cut histories

@term cut-history=v1
@cites {
    ontology#{default-branch=v1, tree=v1, parameter=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
        repository-read=v1,
    },
    documents#{file-readers=v1},
    approval#{incomplete-first-parent-line=v1},
    text#{code-span=v1},
}

This term is for a git repository R, a valid binding D of
`default-branch-name` under which the default branch of R has a commit
d, a valid binding F of `file-readers`, and the repository reads from
which a program takes the first-parent line of d and the files of the
trees of the commits of that first-parent line.

The history of the default branch of R under D and F is cut for those
repository reads when, and only when, the first-parent line of d under F
is incomplete for those repository reads (term
`approval#incomplete-first-parent-line`).

### 4.10 Approval completions

@term approval-completion=v1
@cites {
    conformance#{conforming-program=v1, own-store=v1},
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        item=v1, declared-item=v1, subject-of-approval=v1,
        approval-state=v1, deprecated-item=v1, containment=v1,
        object-withdrawal=v1, object=v1, content-hash=v1, content-id=v1,
        edge=v1, supersedes-edge=v1, effective-supersedes-edge=v1,
        retired-item=v1, in-force-item=v1, default-branch=v1, tree=v1,
        parameter=v1, encoding=v1, log-branch=v1,
    },
    object-store#{store-file=v1, tree-object-store=v1},
    changes#{
        commit=v1, commit-file=v1, shallow-commit=v1,
        default-branch-name=v1, default-branch-commit=v1,
        first-parent-line=v1, repository-read=v1,
    },
    documents#{
        file-readers=v1, vector-paths=v1, kept-object-set=v1,
        read-file=v1, tree-edge=v1, tree-containment=v1,
    },
    approval#{
        approval-kinds=v1, persons=v1, approval-need=v1,
        latest-judgment=v1, judgment-conflict=v1, merged-content=v1,
        incomplete-first-parent-line=v1,
    },
    text#{result=v1, sequence=v1, code-span=v1},
    #{historical-paths=v1, successor=v1, retired-finding=v1},
}

This term is for a git repository R, a tree T whose object store is
valid (`object-store#tree-object-store`, or a valid program's own
store), a valid binding A of `approval-kinds`, `persons` unbound or
bound to a valid binding L (schema `approval#persons`), a binding D of
`default-branch-name` (valid or not), a valid binding F of
`file-readers`, a valid binding V of `vector-paths` (when reading
findings of the class `retired`), a binding N of `external-namespaces`
for which a conforming program of the design Identifiers gives the
result "valid", a set K of kept objects (`documents#kept-object-set`),
and the repository reads from which a program takes the commit of the
default branch of R under D (when D is a valid binding), the
first-parent line of that commit (when the default branch has a commit
under D), and the files of the trees of the commits of that first-parent
line. In this term, R holds a git object when R holds that git object at
the end of those repository reads.

When D is a valid binding of `default-branch-name` and the default
branch of R has a commit d under D, the held first-parent commits of d
for those repository reads are the finite sequence of commits of R that
starts with d, in which each commit before the last is not a shallow
commit of R, in which each commit after the first is the first parent
that the commit object of the commit right before it names, and whose
last commit C meets one of these three conditions:

1. C is a shallow commit of R.
2. The commit object of C names no parent.
3. The commit object of C names as its first parent a git object that is
   not a commit of R.

A commit C of the held first-parent commits of d has an intact read tree
under F for those repository reads when R holds the git tree object of
C, holds every git tree object that a tree entry among the entries of
the git tree object of C names, holds every blob that a regular-file
entry among the entries of the git tree object of C names when that
regular-file entry gives a file of the tree of C that is a read file of
the tree of C under F, and holds every blob that a regular-file entry
among the entries of the git tree object of C names when that
regular-file entry gives a store file of the tree of C (in `.sinter/`
and outside `.sinter/local/`, term `object-store#store-file`).

For each subject of approval S that T has (across both encodings under
F, N, K, and `persons`, or from a valid program's own store), with
declared-item canonical object content id t, S is either decided (known
approved or known not approved) or undecided in T under these inputs for
those repository reads:

- When S needs approval under A (`approval#approval-need`), S is
  decided: let J be the set of latest counting judgments of t in T under
  `persons` (`approval#latest-judgment`); S is known approved when J is
  not empty and every element of J is of the kind `approval`, and S is
  known not approved otherwise (including when J is empty or a conflict
  exists under `approval#judgment-conflict`).
- When S does not need approval under A and D is not a valid binding of
  `default-branch-name`, S is undecided.
- When S does not need approval under A, D is a valid binding of
  `default-branch-name`, and the default branch of R has no commit under
  D, S is decided and is known not approved.
- When S does not need approval under A, D is a valid binding of
  `default-branch-name`, the default branch of R has a commit d under D,
  and the first-parent line of d under F is not incomplete for those
  repository reads (`approval#incomplete-first-parent-line`), S is
  decided: S is known approved when the revised content of S in T has
  merged into the default branch of R under D, F, and N
  (`approval#merged-content`), and S is known not approved otherwise.
- When S does not need approval under A, D is a valid binding of
  `default-branch-name`, the default branch of R has a commit d under D,
  and the first-parent line of d under F is incomplete for those
  repository reads (`approval#incomplete-first-parent-line`): S is
  decided and is known approved when some commit C of the held
  first-parent commits of d has an intact read tree under F for those
  repository reads whose object store is valid
  (`object-store#tree-object-store`) and the tree of C has, in either
  encoding under F, N, K, and `persons`, a subject of approval S2 that
  is the same subject of approval as S and whose declared item's
  canonical object in the tree of C has the same content hash
  (`ontology#content-hash`) as the canonical object of the declared item
  of S in T; otherwise, S is undecided.

An approval completion M of T under these inputs for those repository
reads is an assignment of one of the two states approved or not approved
to each subject of approval S of T such that each decided subject of
approval gets its known state (approved when known approved, not
approved when known not approved) and each undecided subject of approval
gets either approved or not approved.

Under an approval completion M (reading declared items, status tags from
text and from the member `status` in `.sinter/` per
`ontology#deprecated-item`, containment under `ontology#containment` and
`documents#tree-containment`, and citation edges from both encodings of
T):

- A declared item of T is approved under M when it is approved by the
  rules of the term `ontology#approval-state`, with the state approved
  of each subject of approval of T read as the state that M assigns to
  that subject of approval.
- A `supersedes` edge of T is effective under M when it meets the
  conditions of the atom `ontology#effective-supersedes-edge`, with
  approved read as approved under M.
- A declared item of T is retired under M when it meets the conditions
  of the atom `ontology#retired-item`, with effective `supersedes` edges
  read as effective under M; a declared item of T is in force under M
  when it is not retired under M (atom `ontology#in-force-item`).
- For a declared item x of T, a declared item s of T is a successor of x
  under M by the rules of the term `successor`, with in force, retired,
  and effective `supersedes` edges read under M. A declared item of T
  that is in force under M, or an item of T that is not a declared item,
  has no successor under M.
- Under a valid binding H of `historical-paths`, an edge e of T gives a
  `retired` finding under M when e meets the four conditions of the atom
  `retired-finding`, with in force read as in force under M; its
  subject, its spot, and whether it is ackable are those that the atom
  `retired-finding` gives for e with in force and successors read under
  M.

## 5. Requirements

### 5.1 Successors of a retired item

@req give-successors=v1
@cites {
    conformance#{
        conforming-program=v1, dependence=v1, report-missing-parts=v1,
        give-results-over-canonical-objects=v1,
        read-defined-encodings=v1, own-store=v1,
    },
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        declared-item=v1, default-branch=v1, edge=v1, tree=v1,
        parameter=v1, log-branch=v1,
    },
    object-store#{tree-object-store=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
        repository-read=v1, undisturbed-read=v1,
    },
    documents#{file-readers=v1, kept-object-set=v1},
    approval#{approval-kinds=v1, persons=v1, listed-person=v1},
    text#{result=v1, code-span=v1},
    #{successor=v1, approval-completion=v1},
}

This requirement applies for a git repository R, a tree T whose object
store is valid (`object-store#tree-object-store`, or a valid program's
own store), a valid binding A of `approval-kinds`, `persons` unbound or
bound, a binding D of `default-branch-name` (whether or not D is a valid
binding of `default-branch-name`), a valid binding F of `file-readers`,
a binding N of `external-namespaces` for which a conforming program of
the design Identifiers gives the result "valid", and a valid kept object
set K (`documents#kept-object-set`). Under these inputs, this
requirement applies when a conforming program gives the successors of a
declared item x of T under these inputs, and each repository read from
which that program takes the commit of the default branch under D (when
D is valid), the first-parent line of that commit, and the files of the
trees of the commits of that first-parent line is undisturbed.

When `persons` is unbound or bound to a valid binding L, let C be the
set of approval completions of T under these inputs for those repository
reads (term `approval-completion`):

- When every approval completion in C gives the same set of successors
  of x in T, that program must give each item of that set once, must
  give no other item, and must not give that it cannot see the whole
  history for the successors of x.
- When two approval completions in C give different sets of successors
  of x in T, that program must give no successor of x; when D is a valid
  binding of `default-branch-name`, that program must give that it
  cannot see the whole history for the successors of x; when D is not a
  valid binding of `default-branch-name`, that program must not give
  that it cannot see the whole history for the successors of x.

When `persons` is bound to a value that does not meet the schema
`approval#persons`, if every valid binding of `persons` and unbound
`persons` give the same set of successors of x in T (under the rules of
this requirement for unbound or valid bindings of `persons`, with no
disagreement across approval completions for any of them), that program
must give each item of that set once, must give no other item, and must
not give that it cannot see the whole history for the successors of x;
otherwise, that program must give no successor of x, must give that it
cannot see the whole history for the successors of x only when D is a
valid binding of `default-branch-name` and two approval completions
disagree for every valid binding of `persons` and for unbound `persons`,
and must not give that it cannot see the whole history otherwise.

The successors of x need a missing part of an edge (`ontology#edge`,
including an ambiguous pin or a missing computed identity object under
`object-store#tree-object-store`) only when the set of successors of x
depends on that edge or on the canonical object of an item that needs
that part; when another valid input of the run supplies a missing
computed identity object or its key, the run does not lack that part.

### 5.2 Findings of the class `retired`

@req give-retired-findings=v1
@cites {
    conformance#{
        conforming-program=v1, dependence=v1, reject-invalid-inputs=v1,
        report-missing-parts=v1,
        give-results-over-canonical-objects=v1,
        read-defined-encodings=v1, own-store=v1,
    },
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        finding-class=v1, default-branch=v1, edge=v1, tree=v1,
        parameter=v1, log-branch=v1,
    },
    object-store#{tree-object-store=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
        repository-read=v1, undisturbed-read=v1,
    },
    findings#{ackable-finding=v1, finding-part=v1},
    documents#{
        file-readers=v1, vector-paths=v1, kept-object-set=v1,
        tree-edge=v1,
    },
    approval#{approval-kinds=v1, persons=v1, listed-person=v1},
    text#{result=v1, code-span=v1},
    #{historical-paths=v1, retired-finding=v1, approval-completion=v1},
}

This requirement applies for a git repository R, a tree T whose object
store is valid (`object-store#tree-object-store`, or a valid program's
own store), a valid binding A of `approval-kinds`, `persons` unbound or
bound, a binding D of `default-branch-name` (whether or not D is a valid
binding of `default-branch-name`), a valid binding F of `file-readers`,
a valid binding V of `vector-paths`, a binding N of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", a valid kept object set K
(`documents#kept-object-set`), and a valid binding H of
`historical-paths`. Under these inputs, this requirement applies when a
conforming program gives the findings of the class `retired` of T under
these inputs, and each repository read from which that program takes the
commit of the default branch under D (when D is valid), the first-parent
line of that commit, and the files of the trees of the commits of that
first-parent line is undisturbed.

When `persons` is unbound or bound to a valid binding L, let C be the
set of approval completions of T under these inputs for those repository
reads (term `approval-completion`):

- For each edge e of T that gives a `retired` finding under every
  approval completion in C (under H), that program must give that
  finding once; when every approval completion in C agrees on whether
  that finding is ackable, that finding has that ackability; when two
  approval completions in C disagree on whether that finding is ackable,
  that program must give nothing for whether that finding is ackable.
  That program must give no other finding of the class `retired` for T.
- When some edge e of T differs across C under H (gives a `retired`
  finding under some approval completion in C and gives none under some
  other approval completion in C, or gives a `retired` finding under
  every approval completion in C whose ackability differs across two
  approval completions in C) and D is a valid binding of
  `default-branch-name`, that program must give that it cannot see the
  whole history for the findings of the class `retired` of T. Otherwise,
  that program must not give that it cannot see the whole history for
  the findings of the class `retired` of T.

When `persons` is bound to a value that does not meet the schema
`approval#persons`, that program must give once each `retired` finding
that holds under every valid binding of `persons` and when `persons` is
unbound (under the rules of this requirement for unbound or valid
bindings of `persons`), with its ackability when all of those agree on
whether it is ackable and giving nothing for whether it is ackable when
two of them disagree, and must give no finding of the class `retired`
whose existence depends on `persons`, and no other finding of the class
`retired` for T; that program must give that it cannot see the whole
history for the findings of the class `retired` of T only when D is a
valid binding of `default-branch-name` and some edge differs across
approval completions for every valid binding of `persons` and for
unbound `persons`, and must not give that it cannot see the whole
history otherwise.

Only a finding of the class `retired` for an edge that a vector line
gives or whose cited item is a vector set or a group of conformance
vectors depends on the binding of `vector-paths`. When an edge of T has
a target that is an ambiguous pin or a missing part (`ontology#edge`,
including a missing computed identity object under
`object-store#tree-object-store`), only the findings of the class
`retired` that depend on that edge or on the canonical object of an item
that needs that part need that missing part; every other finding of the
class `retired` of T does not need that part. When another valid input
of the run supplies a missing computed identity object or its key, the
run does not lack that part.

### 5.3 Offered fixes of `retired` findings

@req limit-retired-fix-edit-sets=v1
@cites {
    conformance#{conforming-program=v1, input=v1, own-store=v1},
    files#{path=v1},
    identifiers#{
        external-namespaces=v1, validate-bindings=v1, tag-line=v1,
        citation=v1, citation-line=v1, citation-entry=v1,
        inline-citation=v1, tag-line-text=v1,
    },
    data-forms#{vector-line=v1, test-vector-set=v1},
    ontology#{
        declared-item=v1, item-name=v1, item-revision=v1, same-item=v1,
        external-item=v1, edge=v1, cites-edge=v1, pinned-edge=v1,
        site=v1, default-branch=v1, tree=v1, parameter=v1, encoding=v1,
        log-branch=v1,
    },
    object-store#{store-file=v1, tree-object-store=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
        repository-read=v1, undisturbed-read=v1,
    },
    findings#{
        spot=v1, edit=v1, edit-set=v1, edited-text=v1, edited-tree=v1,
        fix=v1, finding-part=v1, limit-fix-edit-sets=v1,
        make-no-fixes-on-unreadable-files=v1,
    },
    documents#{
        file-readers=v1, vector-paths=v1, kept-object-set=v1,
        tag-text=v1, accepted-input=v1, tree-edge=v1, origin=v1,
        unreadable-file=v1, vector-file=v1,
    },
    approval#{approval-kinds=v1, persons=v1},
    text#{
        result=v1, character=v1, space=v1, tab=v1, place=v1, line=v1,
        line-number=v1, whole-number=v1, boundary=v1, span=v1, run=v1,
        code-point-order=v1, text=v1, code-span=v1,
    },
    #{
        historical-paths=v1, successor=v1, retired-finding=v1,
        approval-completion=v1, give-retired-findings=v1,
    },
}

This requirement applies for a git repository R, a tree T whose object
store is valid (`object-store#tree-object-store`, or a valid program's
own store), a valid binding A of `approval-kinds`, `persons` unbound or
bound, a binding D of `default-branch-name` (whether or not D is a valid
binding of `default-branch-name`), a valid binding F of `file-readers`,
a valid binding V of `vector-paths`, a binding N of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", a valid kept object set K
(`documents#kept-object-set`), and a valid binding H of
`historical-paths`, when each repository read from which a conforming
program takes the commit of the default branch under D (when D is
valid), the first-parent line of that commit, and the files of the trees
of the commits of that first-parent line is undisturbed.

In an execution in which content of a file or a folder is a part that an
input lacks under `conformance#input` because a conforming program could
not take that content, that conforming program must make no fix in any
tree (`findings#make-no-fixes-on-unreadable-files`).

No edit of a fix for a `retired` finding of T may have a spot whose
valid path is a store path or a local path (`object-store#store-file`).

For each `retired` finding f of T given for an edge E under
`give-retired-findings`:

- When E is an edge of a stored declared item in `.sinter/`, when the
  source of E comes from a valid program's own store with no file, or
  when f has no spot (or its spot has no span), that program must give
  no fix for f.
- Otherwise (when f has a spot with a span in a read file or a vector
  file of T), let c be the cited item of E. When `persons` is unbound or
  bound to a valid binding L, let C be the set of approval completions
  of T under these inputs for those repository reads (term
  `approval-completion`); when `persons` is bound to a value that does
  not meet `approval#persons`, let C be the union of those sets of
  approval completions across every valid binding of `persons` and
  unbound `persons`. When two approval completions in C give different
  sets of successors of c in T, that program must give no fix for f.
  When every approval completion in C gives the same set S of successors
  of c in T, S has one or more items, and that program gives a fix for
  f, that fix must meet all three of these conditions:

  1. The fix has exactly one edit set for each successor of c in S, in
     the code point order of the names of those successors in T.
  2. Let W be this non-empty set of runs of the text of the file of E in
     T:
     - when a citation entry gives E, the single run of the text of the
       tag line of the citation of E in the text of that file (term
       `documents#origin`);
     - when an inline citation gives E, the single run of that inline
       citation in the text of that file;
     - when a vector line gives E, the form run of the edge of each
       vector line of the group of the vector line of E in that vector
       file (schema `data-forms#test-vector-set`).

     For each edit set of the fix, every edit of that edit set has a
     spot whose valid path is the valid path of the file of E in T, and
     whose span starts and ends at boundaries of one run in W.
  3. For each successor s in S, let T′ be the edited tree of the edit
     set for s, read under F, V, N, K, and `persons`. Let t be the text
     of the file of E in T (with n characters), and let t′ be the edited
     text of the valid path of that file for the edit set (with n′
     characters). In T′ under these inputs:
     - when a citation entry gives E, let r be the run in W (starting at
       boundary b0 and ending at boundary b1 in t), and let r′ be the
       run of t′ that starts at boundary b0 and ends at boundary
       n′ − (n − b1): the file of E in T′ can be read, there is an
       accepted input of that file that is a citation (the edited
       citation) such that the run of the text of the tag line of that
       citation in t′ (term `documents#origin`) starts and ends at
       boundaries of r′, every character of r′ at a place outside that
       run is a space or a tab, and no other tag line of any tag text of
       that file has a place of its origin in r′;
     - when an inline citation gives E, let r be the run in W (starting
       at boundary b0 and ending at boundary b1 in t), and let r′ be the
       run of t′ that starts at boundary b0 and ends at boundary
       n′ − (n − b1): the file of E in T′ can be read, and r′ is the run
       in t′ (term `documents#origin`) of an accepted input of that file
       that is an inline citation (the edited inline citation);
     - when a citation entry or an inline citation gives E, the edited
       citation or edited inline citation in that file gives an edge E′
       of the same kind of edge as E, whose source is the same item as
       the source of E (or is a site when the source of E is a site),
       whose cited item is the same item as s, and that is pinned with
       the current revision of s in T as its label when E is pinned, and
       is not pinned when E is not pinned;
     - when a citation entry gives E, each edge that a citation gives is
       represented by three properties: its kind of edge; its pinned
       label, or that it is not pinned; and its target, which is its
       cited item (as the same item) when the edge has a cited item that
       is not an external item, and is the entry name of its citation
       entry when its cited item is an external item or when the edge
       has no cited item. Taken by these three properties, the set of
       edges that the edited citation gives in T′ is the set of edges
       that the citation of E gave in T with E replaced by E′;
     - when a vector line gives E, the content of the vector file of E
       in T′ is a test-vector set, and for each vector line L of the
       group of the vector line of E in that vector file in T (on line l
       of t, starting at boundary ls and ending at boundary le, whose
       edge has form run rL starting at boundary b0 and ending at
       boundary b1), let l′ be the line of t′ with the same line number
       as l (starting at boundary ls′ and ending at boundary le′) and
       let rL′ be the run of t′ that starts at boundary ls′ + (b0 − ls)
       and ends at boundary le′ − (le − b1): rL′ is the form run of an
       edge EL′ that a vector line of that vector file gives in T′, and
       EL′ is of the kind `cites`, its source is the same item as the
       source of E, its cited item is the same item as s, and EL′ is
       pinned with the current revision of s in T as its label.

### 5.4 Findings of the class `cycle`

@req give-cycle-findings=v1
@cites {
    conformance#{
        conforming-program=v1, dependence=v1, report-missing-parts=v1,
        give-results-over-canonical-objects=v1,
        read-defined-encodings=v1, own-store=v1,
    },
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        finding-class=v1, edge=v1, tree=v1, parameter=v1, log-branch=v1,
    },
    object-store#{tree-object-store=v1},
    documents#{file-readers=v1, kept-object-set=v1, tree-finding=v1},
    approval#{persons=v1, listed-person=v1},
    text#{result=v1, code-span=v1},
    #{historical-paths=v1, cycle-finding=v1},
}

This requirement applies for a tree T whose object store is valid
(`object-store#tree-object-store`, or a valid program's own store),
under a valid binding F of `file-readers`, a binding N of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", a valid kept object set K
(`documents#kept-object-set`), `persons` unbound or bound, and a valid
binding H of `historical-paths`.

When a conforming program gives the findings of the class `cycle` of T
under these inputs:

- When `persons` is unbound or bound to a valid binding L, that program
  must give each tree finding of that class that T has under these
  inputs once, and must give no other finding of that class.
- When `persons` is bound to a value that does not meet
  `approval#persons`, that program must give once each tree finding of
  that class that T has identically (same subject and same spot) under
  every valid binding of `persons` and when `persons` is unbound, and
  must give no finding of that class whose existence or spot depends on
  `persons`, and no other finding of that class.

A finding of the class `cycle` needs a missing part of an edge
(`ontology#edge`, including an ambiguous pin or a missing computed
identity object under `object-store#tree-object-store`) only when the
existence or spot of that finding depends on that edge or on the
canonical object of an item that needs that part; every other finding of
the class `cycle` of T does not need that part. When another valid input
of the run supplies a missing computed identity object or its key, the
run does not lack that part.

### 5.5 Findings of the class `deleted-decision`

@req give-deleted-decision-findings=v1
@cites {
    conformance#{
        conforming-program=v1, dependence=v1,
        give-results-over-canonical-objects=v1,
        read-defined-encodings=v1, own-store=v1,
    },
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{finding-class=v1, tree=v1, parameter=v1},
    object-store#{tree-object-store=v1},
    documents#{file-readers=v1, tree-finding=v1},
    approval#{persons=v1, listed-person=v1},
    text#{result=v1, code-span=v1},
    #{deleted-decision-finding=v1},
}

This requirement applies for a tree T and a base tree B (each with a
valid object store under `object-store#tree-object-store`, or from valid
program's own stores), under a valid binding F of `file-readers`, a
binding N of `external-namespaces` for which a conforming program of the
design Identifiers gives the result "valid", and `persons` unbound or
bound.

When a conforming program gives the findings of the class
`deleted-decision` of T against B under these inputs:

- When `persons` is unbound or bound to a valid binding L, that program
  must give each tree finding of that class that T has against B under
  these inputs once, and must give no other finding of that class.
- When `persons` is bound to a value that does not meet
  `approval#persons`, that program must give once each tree finding of
  that class that T has against B under every valid binding of `persons`
  and when `persons` is unbound, and must give no finding of that class
  whose existence depends on `persons`, and no other finding of that
  class.

A finding of the class `deleted-decision` does not need any computed
identity object missing from the object store of T or of B
(`object-store#tree-object-store`).

### 5.6 Findings of the class `reused-label`

@req give-reused-label-findings=v1
@cites {
    conformance#{
        conforming-program=v1, dependence=v1, report-missing-parts=v1,
        give-results-over-canonical-objects=v1,
        read-defined-encodings=v1, own-store=v1,
    },
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        finding-class=v1, edge=v1, tree=v1, parameter=v1, log-branch=v1,
    },
    object-store#{tree-object-store=v1},
    changes#{commit=v1, change-of-a-commit=v1},
    documents#{file-readers=v1, kept-object-set=v1, tree-finding=v1},
    approval#{persons=v1, listed-person=v1},
    text#{result=v1, sequence=v1, code-span=v1},
    #{historical-paths=v1, reused-label-finding=v1},
}

This requirement applies for a tree T, a base tree B, and a finite
sequence L of trees (each with a valid object store under
`object-store#tree-object-store`, or from valid program's own stores),
under a valid binding F of `file-readers`, a binding N of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", a valid kept object set K
(`documents#kept-object-set`), `persons` unbound or bound, and a valid
binding H of `historical-paths`. This requirement does not apply when a
conforming program gives the findings of the class `reused-label` of the
change of a commit.

When a conforming program gives the findings of the class `reused-label`
of T against B and L under these inputs:

- When `persons` is unbound or bound to a valid binding P, that program
  must give each tree finding of that class that T has against B and L
  under these inputs once, and must give no other finding of that class.
- When `persons` is bound to a value that does not meet
  `approval#persons`, that program must give once each tree finding of
  that class that T has against B and L identically (same subject and
  same spot) under every valid binding of `persons` and when `persons`
  is unbound, and must give no finding of that class whose existence or
  spot depends on `persons`, and no other finding of that class.

A finding of the class `reused-label` for a declared item d of T needs a
missing part of an edge (`ontology#edge`) only when computing the
canonical object of d in T, of its base item in B, or of its base item
in an element of L needs that part. It does not need a computed identity
object missing from `.sinter/` (`object-store#tree-object-store`) when
the valid object files already hold their canonical byte sequences.

### 5.7 No finding under a binding of `historical-paths` that is not valid

@req omit-findings-under-invalid-historical-paths=v1
@cites {
    conformance#{conforming-program=v1},
    ontology#{finding-class=v1, tree=v1, parameter=v1},
    changes#{commit=v1, change-of-a-commit=v1},
    text#{code-span=v1},
    #{
        historical-paths=v1, retired-finding=v1, cycle-finding=v1,
        reused-label-finding=v1,
    },
}

Under a binding of `historical-paths` that is not valid, a conforming
program must give no finding of the classes `retired`, `cycle`, and
`reused-label` of any tree, and must not give that it cannot see the
whole history for the findings of the class `retired` of any tree or for
the change of any commit.

### 5.8 Deleted decision records of the change of a commit

@req compare-change-for-deleted-decisions=v1
@cites {
    conformance#{
        conforming-program=v1, give-results-over-canonical-objects=v1,
        read-defined-encodings=v1,
    },
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{finding-class=v1, tree=v1, parameter=v1},
    object-store#{tree-object-store=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        change-of-a-commit=v1, change-base=v1, repository-read=v1,
        undisturbed-read=v1,
    },
    documents#{file-readers=v1, tree-finding=v1},
    approval#{persons=v1, listed-person=v1},
    text#{result=v1, code-span=v1},
    #{deleted-decision-finding=v1},
}

This requirement applies for a commit h under a valid binding D of
`default-branch-name` under which the change of h has a base, a valid
binding F of `file-readers`, a binding N of `external-namespaces` for
which a conforming program of the design Identifiers gives the result
"valid", `persons` unbound or bound, and valid object stores
(`object-store#tree-object-store`) of the tree of h and of the tree of
the base of the change of h. Under these inputs, this requirement applies
when a conforming program meets two conditions. First, that program
gives the findings of the class `deleted-decision` of the change of h
under these inputs. Second, each repository read from which that program
takes the base of the change of h and the files of the tree of h and of
the tree of that base is undisturbed.

Under these inputs and when both conditions hold:

- When `persons` is unbound or bound to a valid binding L, that program
  must give each tree finding of that class that the tree of h has
  against the tree of the base of the change of h under F, N, and
  `persons` once, and must give no other finding of that class.
- When `persons` is bound to a value that does not meet
  `approval#persons`, that program must give once each tree finding of
  that class that the tree of h has against the tree of the base of the
  change of h under every valid binding of `persons` and when `persons`
  is unbound, and must give no finding of that class whose existence
  depends on `persons`, and no other finding of that class.

### 5.9 Reused labels of the change of a commit

@req compare-change-for-reused-labels=v1
@cites {
    conformance#{
        conforming-program=v1, give-results-over-canonical-objects=v1,
        read-defined-encodings=v1,
    },
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        finding-class=v1, default-branch=v1, tree=v1, parameter=v1,
        log-branch=v1,
    },
    object-store#{tree-object-store=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, change-of-a-commit=v1, change-base=v1,
        first-parent-line=v1, repository-read=v1, undisturbed-read=v1,
    },
    documents#{file-readers=v1, kept-object-set=v1, tree-finding=v1},
    approval#{persons=v1, listed-person=v1},
    text#{result=v1, sequence=v1, code-span=v1},
    #{
        historical-paths=v1, new-label-item=v1, reused-label-finding=v1,
        cut-history=v1,
    },
}

This requirement applies for a commit h of a git repository R under a
valid binding D of `default-branch-name` under which the change of h has
a base (so the default branch of R has a commit d under D), a valid
binding F of `file-readers`, a binding N of `external-namespaces` for
which a conforming program of the design Identifiers gives the result
"valid", a valid kept object set K (`documents#kept-object-set`),
`persons` unbound or bound, a valid binding H of `historical-paths`, and
valid object stores (`object-store#tree-object-store`) of the tree of h,
of the tree of the base of the change of h, and of the tree of each
commit of the first-parent line of d. Let L be the sequence of the trees
of the commits of the first-parent line of d, in the order of that line.

This requirement applies when a conforming program meets three
conditions. First, that program gives the findings of the class
`reused-label` of the change of h under these inputs. Second, each
repository read from which that program takes the base of the change of
h, the first-parent line of d, and the files of the trees of h, of that
base, and of the commits of that line is undisturbed. Third, when
`persons` is unbound or bound to a valid binding P, either the tree of h
has no item with a new label against the tree of the base of the change
of h under F, N, `persons`, and H, or the history of the default branch
of R under D and F is not cut for those repository reads; when `persons`
is bound to a value that does not meet `approval#persons`, that same
disjunction holds for every valid binding of `persons` and for unbound
`persons`.

- When `persons` is unbound or bound to a valid binding P: when the tree
  of h has no item with a new label against the tree of the base of the
  change of h under F, N, `persons`, and H, that program must give no
  finding of the class `reused-label`; otherwise, that program must give
  each tree finding of the class `reused-label` that the tree of h has
  against the tree of the base of the change of h and L under these
  inputs once, and must give no other finding of that class.
- When `persons` is bound to a value that does not meet
  `approval#persons`, that program must give once each tree finding of
  the class `reused-label` that holds identically (same subject and same
  spot) under every valid binding of `persons` and when `persons` is
  unbound, and must give no finding of that class whose existence or
  spot depends on `persons`, and no other finding of that class.

### 5.10 The change of a commit with no base

@req report-missing-base=v1
@cites {
    conformance#{conforming-program=v1},
    ontology#{finding-class=v1, parameter=v1},
    changes#{
        commit=v1, default-branch-name=v1, change-of-a-commit=v1,
        change-base=v1, repository-read=v1, undisturbed-read=v1,
    },
    text#{code-span=v1},
    #{deleted-decision-finding=v1, reused-label-finding=v1},
}

This requirement applies for a commit h under a valid binding of
`default-branch-name` under which the change of h has no base, when a
conforming program meets two conditions. First, that program gives the
findings of the class `deleted-decision` or of the class `reused-label`
of the change of h under that binding. Second, each repository read from
which that program takes that the change of h has no base is
undisturbed. Under that binding and when both conditions hold, that
program must give that the change of h has no base, must give no finding
of the class or classes whose findings it gives, and must not give that
it cannot see the whole history for the change of h.

### 5.11 The change of a commit with a base

@req omit-missing-base-report=v1
@cites {
    conformance#{conforming-program=v1},
    ontology#{finding-class=v1, parameter=v1},
    changes#{
        commit=v1, default-branch-name=v1, change-of-a-commit=v1,
        change-base=v1, repository-read=v1, undisturbed-read=v1,
    },
    text#{code-span=v1},
    #{deleted-decision-finding=v1, reused-label-finding=v1},
}

This requirement applies for a commit h under a valid binding of
`default-branch-name` under which the change of h has a base, when a
conforming program meets two conditions. First, that program gives the
findings of the class `deleted-decision` or of the class `reused-label`
of the change of h under that binding, or gives whether the change of h
has a base under that binding. Second, each repository read from which
that program takes whether the change of h has a base is undisturbed.
Under that binding and when both conditions hold, that program must not
give that the change of h has no base.

### 5.12 Cut histories

@req report-cut-history=v1
@cites {
    conformance#{conforming-program=v1},
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        finding-class=v1, default-branch=v1, tree=v1, parameter=v1,
    },
    object-store#{tree-object-store=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, change-of-a-commit=v1, change-base=v1,
        first-parent-line=v1, repository-read=v1, undisturbed-read=v1,
    },
    documents#{file-readers=v1},
    approval#{persons=v1},
    text#{result=v1, code-span=v1},
    #{
        historical-paths=v1, new-label-item=v1, reused-label-finding=v1,
        cut-history=v1,
    },
}

This requirement applies for a commit h of a git repository R under a
valid binding D of `default-branch-name` under which the change of h has
a base (so the default branch of R has a commit d under D), a valid
binding F of `file-readers`, a binding N of `external-namespaces` for
which a conforming program of the design Identifiers gives the result
"valid", `persons` unbound or bound to a valid binding P (schema
`approval#persons`), a valid binding H of `historical-paths`, and valid
object stores (`object-store#tree-object-store`) of the tree of h and of
the tree of the base of the change of h.

This requirement applies when a conforming program meets four
conditions. First, that program gives the findings of the class
`reused-label` of the change of h under these inputs. Second, each
repository read from which that program takes the base of the change of
h, the first-parent line of d, and the files of the trees of h, of that
base, and of the commits of that line is undisturbed. Third, the tree of
h has at least one item with a new label against the tree of the base of
the change of h under F, N, `persons`, and H. Fourth, the history of the
default branch of R under D and F is cut for those repository reads.
When all four conditions hold, that program must give that it cannot see
the whole history for the change of h, and must give no finding of the
class `reused-label`.

### 5.13 When no label is new, the default branch is read in full, or reused labels are not given

@req omit-cut-history-report=v1
@cites {
    conformance#{conforming-program=v1},
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        finding-class=v1, default-branch=v1, tree=v1, parameter=v1,
    },
    object-store#{tree-object-store=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, change-of-a-commit=v1, change-base=v1,
        first-parent-line=v1, repository-read=v1, undisturbed-read=v1,
    },
    documents#{file-readers=v1},
    approval#{persons=v1},
    text#{result=v1, code-span=v1},
    #{
        historical-paths=v1, new-label-item=v1, reused-label-finding=v1,
        cut-history=v1,
    },
}

This requirement applies for a commit h of a git repository R under a
valid binding D of `default-branch-name` under which the change of h has
a base (so the default branch of R has a commit d under D), a valid
binding F of `file-readers`, a binding N of `external-namespaces` for
which a conforming program of the design Identifiers gives the result
"valid", `persons` unbound or bound to a valid binding P (schema
`approval#persons`), a valid binding H of `historical-paths`, and valid
object stores (`object-store#tree-object-store`) of the tree of h and of
the tree of the base of the change of h.

Under these inputs, when a conforming program meets two conditions, that
program must not give that it cannot see the whole history for the
change of h under these inputs. First, that program does not give the
findings of the class `reused-label` of the change of h under these
inputs. Second, each repository read from which that program takes the
base of the change of h is undisturbed.

Under these inputs, when a conforming program meets three conditions,
that program must not give that it cannot see the whole history for the
change of h under these inputs. First, that program gives the findings
of the class `reused-label` of the change of h under these inputs.
Second, each repository read from which that program takes the base of
the change of h, the first-parent line of d, and the files of the trees
of h, of that base, and of the commits of that line is undisturbed.
Third, either the tree of h has no item with a new label against the
tree of the base of the change of h under F, N, `persons`, and H, or the
history of the default branch of R under D and F is not cut for those
repository reads.

## 6. Conformance

A program conforms to this design when it is a
[conforming program](sinter:conformance#conforming-program=v1) of this design.

The vectors of this design are in the file
[`standing.test-vectors.jsonl`](standing.test-vectors.jsonl), in the
same folder as this design. The file is a test-vector set, as the
specification [`test-vectors`](sinter:data-forms#test-vectors=v1) of
Data forms gives it. A vector is an input and what a conforming program
gives for that input. Each vector follows from the requirements and adds
nothing to them. The vectors are in six groups: `successors`, `retired`,
`retired-fixes`, `cycles`, `deleted-decisions`, and `reused-labels`.
Each group has a subsection below that gives the forms of that group,
as the term [`group-form-list`](sinter:data-forms#group-form-list=v1)
gives the forms of a group. These requirements have no vectors:
`compare-change-for-deleted-decisions`,
`compare-change-for-reused-labels`, `report-missing-base`,
`omit-missing-base-report`, `report-cut-history`, and
`omit-cut-history-report`.

### 6.1 Successors

@schema successors-vector=v1
@cites {
    rfc/8259,
    conformance#{conforming-program=v1},
    text#{
        text=v1, character=v1, whole-number=v1, decimal-numeral=v1,
        sequence=v1, result=v1, code-span=v1,
    },
    data-forms#{
        index=v1, group-form-list=v1, vector-meaning=v1, json-value=v1,
    },
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        declared-item=v1, containment=v1, item-name=v1, edge=v1,
        supersedes-edge=v1, effective-supersedes-edge=v1,
        default-branch=v1, tree=v1, parameter=v1,
    },
    object-store#{tree-object-store=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
        repository-read=v1,
    },
    documents#{file-readers=v1},
    approval#{
        approval-kinds=v1, persons=v1, bound-in-force-item=v1,
        incomplete-first-parent-line=v1,
    },
    #{successor=v1, give-successors=v1},
}

The group `successors` holds the vectors of the requirement
`give-successors`. Each vector gives the declared items of a tree (with
their kinds, the items of the kind `design` that hold them, and whether
each is in force), the `supersedes` edges of the tree (with whether each
edge is effective), and one declared item of that tree. The vector gives
the successors of that declared item in the tree. The group uses no
need, so these forms give no need names.

The input of each vector stands for a git repository whose default
branch's first-parent line (when the default branch has a commit) is not
incomplete (`approval#incomplete-first-parent-line`) for the repository
reads from which a conforming program takes that first-parent line and
the files of the trees of the commits of that first-parent line; for a
tree with a valid object store (`object-store#tree-object-store`); for
`persons` unbound; for valid bindings of `approval-kinds`,
`default-branch-name`, and `file-readers`; and for a binding of
`external-namespaces` for which a conforming program of Identifiers
gives the result "valid". Each vector checks a conforming program when
no other process changes these inputs while the program runs.

The JSON values, objects, arrays, strings, numbers, and the literal
names `true` and `false` of this schema are as RFC 8259 defines them.
Inside `input` and `values`, a text is a JSON string whose characters
are the characters of the text in order, a whole number of 1 or more is
a JSON number written as its decimal numeral, and a sequence is a JSON
array of its elements in order.

- `input`: a JSON object with three members:
  - `items`: the declared items of the tree, as a sequence. Each element
    is a JSON object with `name` (the name of the item), `kind` (one of
    `"design"`, `"spec"`, `"schema"`, `"req"`, `"atom"`, `"term"`, and
    `"decision"`), `in-force` (`true` when the item is in force in the
    tree under the bindings, and `false` when it is retired), and, when
    an item of the kind `design` holds the item, `design` (the name of
    that item of the kind `design`).
  - `edges`: the `supersedes` edges of the tree that say what
    `supersedes` says in the tree, as a sequence. Each element is a JSON
    object with `source` (the 1-based index of the source in `items`),
    `cited` (the 1-based index of the cited item in `items`), and
    `effective` (`true` when the edge is effective in the tree under the
    bindings, and `false` otherwise).
  - `target`: the 1-based index in `items` of the declared item whose
    successors are asked.
- `result`: no vector of the group has this member; these forms name no
  question for `result`.
- `values`: a JSON object with one member, `successors`: a JSON array of
  the 1-based indexes in `items` of the successors of `target`, each
  once, in increasing numerical order.

When a conforming program gives the successors of `target` in the tree
under the bindings, that program gives the declared item at each index
in `successors` once and gives no other item.

### 6.2 Findings of the class `retired`

@schema retired-vector=v1
@cites {
    rfc/8259,
    conformance#{conforming-program=v1, own-store=v1},
    text#{
        text=v1, character=v1, code-point-order=v1, sequence=v1,
        result=v1, code-span=v1,
    },
    files#{path=v1, path-set=v1, valid-path-set=v1},
    data-forms#{group-form-list=v1, vector-meaning=v1, json-value=v1},
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        declared-item=v1, edge=v1, vector-set=v1,
        conformance-vector-group=v1, external-item=v1,
        default-branch=v1, tree=v1, finding-class=v1, parameter=v1,
    },
    object-store#{store-file=v1, tree-object-store=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
        repository-read=v1,
    },
    findings#{ackable-finding=v1, finding-part=v1},
    documents#{
        file-readers=v1, vector-paths=v1, tree-edge=v1,
        position-subject=v1, edge-finding-subject=v1,
    },
    approval#{
        approval-kinds=v1, persons=v1, bound-in-force-item=v1,
        incomplete-first-parent-line=v1,
    },
    #{
        historical-paths=v1, historical-file=v1, retired-finding=v1,
        give-retired-findings=v1,
        omit-findings-under-invalid-historical-paths=v1,
    },
}

The group `retired` holds the vectors of the requirements
`give-retired-findings` and
`omit-findings-under-invalid-historical-paths`. Each vector gives a
binding of `historical-paths` and the edges of a tree, with the source
and cited-item states, whether each retired cited item (or vector set's
design or specification) has a successor, optional file paths, and
subjects of those edges. The vector gives the subjects and ackability of
the `retired` findings of the tree, or `{}` when the binding of
`historical-paths` is not valid. The group uses no need, so these forms
give no need names.

The input of each vector stands for a git repository whose default
branch's first-parent line (when the default branch has a commit) is not
incomplete (`approval#incomplete-first-parent-line`) for the repository
reads from which a conforming program takes that first-parent line and
the files of the trees of the commits of that first-parent line; for a
tree with a valid object store (`object-store#tree-object-store`, or a
valid program's own store); for `persons` unbound; for valid bindings of
`approval-kinds`, `default-branch-name`, `file-readers`, and
`vector-paths`; and for a binding of `external-namespaces` for which a
conforming program of Identifiers gives the result "valid". Each vector
checks a conforming program when no other process changes these inputs
while the program runs.

The JSON values, objects, arrays, strings, and the literal names `true`
and `false` of this schema are as RFC 8259 defines them. Inside `input`
and `values`, a text is a JSON string whose characters are the
characters of the text in order, and a sequence is a JSON array of its
elements in order.

- `input`: a JSON object with two members:
  - `historical-paths`: a binding of `historical-paths`, as a JSON array
    of the path set members of that path set, each a text, in order.
  - `edges`: the edges of the tree, as a sequence. Each element is a
    JSON object with `kind` (one of `"cites"`, `"satisfies"`,
    `"verifies"`, `"refines"`, and `"supersedes"`), `fits` (`true` when
    the edge says what its kind of edge says in the tree, and `false`
    otherwise), `source-kind` (`"declared"` when the source is a
    declared item, `"group"` when the source is a group of conformance
    vectors, and `"other"` otherwise), `source-in-force` (present when
    `source-kind` is `"declared"` or `"group"`: `true` when that
    declared item, or the item of the kind `design` or of the kind
    `spec` of that group's vector set, is in force in the tree under the
    bindings, and `false` otherwise), `cited-kind` (`"declared"` when
    the cited item is a declared item, `"group"` when the cited item is
    a group of conformance vectors, `"vector-set"` when the cited item
    is a vector set, and `"external"` when the cited item is an external
    item or when the edge has no cited item), `cited-in-force` (present
    when `cited-kind` is `"declared"`, `"group"`, or `"vector-set"`:
    `true` when that declared item, or the item of the kind `design` or
    of the kind `spec` of the vector set — for `"group"`, the vector set
    of that group — is in force in the tree under the bindings, and
    `false` otherwise), `cited-has-successor` (present when `cited-kind`
    is `"declared"`, `"group"`, or `"vector-set"`: `true` when that
    declared item, or the item of the kind `design` or of the kind
    `spec` of that vector set, has one or more successors in the tree,
    and `false` otherwise), optional `path` (present for `"group"` and
    `"other"`, and for `"declared"` when the source stands in a text
    file or in a valid object file of `.sinter/`, omitted when the
    source comes from a valid program's own store with no file: the
    valid path of the file of the edge), and `subject` (the edge finding
    subject of the edge under `documents#edge-finding-subject` when
    `source-kind` is `"declared"`, or the position subject of the edge
    under `documents#position-subject` when `source-kind` is `"group"`
    or `"other"`).
- `result`: no vector of the group has this member; these forms name no
  question for `result`.
- `values`: `{}` when `historical-paths` is not a valid path set;
  otherwise, a JSON object with one member, `findings`, a JSON array
  with one element for each `retired` finding of the tree, in code point
  order of `subject`. Each element is a JSON object with `subject` (the
  subject of the finding) and `ackable` (`true` when the finding is
  ackable and `false` when it is not ackable).

When `values` is `{}`, a conforming program gives no finding of the
class `retired` for the tree. When `values` is not `{}` and a conforming
program gives the findings of the class `retired` of the tree under the
bindings, that program gives one finding of that class for each element
of `findings`, with the subject and ackability that the element states,
and gives no other finding of that class.

### 6.3 Offered fixes of `retired` findings

@schema retired-fix-vector=v1
@cites {
    rfc/8259,
    conformance#{conforming-program=v1, own-store=v1},
    text#{
        text=v1, character=v1, whole-number=v1, decimal-numeral=v1,
        boundary=v1, run=v1, code-point-order=v1, sequence=v1,
        result=v1, code-span=v1,
    },
    files#{path=v1},
    data-forms#{
        group-form-list=v1, vector-meaning=v1, json-value=v1,
        vector-line=v1, test-vector-set=v1,
    },
    identifiers#{
        external-namespaces=v1, validate-bindings=v1, citation=v1,
        citation-entry=v1, inline-citation=v1, tag-line-text=v1,
    },
    ontology#{
        declared-item=v1, containment=v1, item-name=v1,
        item-revision=v1, edge=v1, pinned-edge=v1, tree=v1,
        parameter=v1,
    },
    object-store#{store-file=v1, tree-object-store=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
        repository-read=v1,
    },
    findings#{fix=v1, edit=v1, edit-set=v1, spot=v1},
    documents#{file-readers=v1, vector-paths=v1, tree-edge=v1, origin=v1},
    approval#{
        approval-kinds=v1, persons=v1, incomplete-first-parent-line=v1,
    },
    #{
        historical-paths=v1, successor=v1, retired-finding=v1,
        limit-retired-fix-edit-sets=v1,
    },
}

The group `retired-fixes` holds the vectors of the requirement
`limit-retired-fix-edit-sets`. Each vector gives the origin kind, file
text (when the edge is in a text file or vector file), edge and run (for
a text or vector-line edge) of a `retired` finding whose cited item has
one or more successors, and the successors of its cited item. The vector
gives whether a fix that meets `limit-retired-fix-edit-sets` exists and,
when one does, the ordered edit-set obligations that any offered fix
meets. The group uses no need, so these forms give no need names.

The input of each vector stands for a git repository whose default
branch's first-parent line (when the default branch has a commit) is not
incomplete (`approval#incomplete-first-parent-line`) for the repository
reads from which a conforming program takes that first-parent line and
the files of the trees of the commits of that first-parent line; for a
tree with a valid object store (`object-store#tree-object-store`); for
`persons` unbound; for valid bindings of `approval-kinds`,
`default-branch-name`, `file-readers`, `vector-paths`, and
`historical-paths` (under which the file of the edge is not historical);
and for a binding of `external-namespaces` for which a conforming
program of Identifiers gives the result "valid". Each vector checks a
conforming program when no other process changes these inputs while the
program runs.

The JSON values, objects, arrays, strings, numbers, and the literal
names `true` and `false` of this schema are as RFC 8259 defines them.
Inside `input` and `values`, a text is a JSON string whose characters
are the characters of the text in order, a boundary is a JSON number
written as its decimal numeral, and a sequence is a JSON array of its
elements in order.

- `input`: a JSON object with these members:
  - `origin-kind`: one of `"citation-entry"`, `"inline-citation"`,
    `"vector-line"`, `"stored"`, and `"store"`.
  - `path`: present when `origin-kind` is not `"store"`: the valid path
    of the file of the edge `E` (a store path in `.sinter/` when
    `origin-kind` is `"stored"`).
  - `text`: present when `origin-kind` is `"citation-entry"`,
    `"inline-citation"`, or `"vector-line"`: the text of that file in
    the tree.
  - `edge-kind`: one of `"cites"`, `"satisfies"`, `"verifies"`, and
    `"refines"`.
  - `pinned`: `true` when `E` is pinned, and `false` when `E` is not
    pinned.
  - `run`: present when `origin-kind` is `"citation-entry"`,
    `"inline-citation"`, or `"vector-line"`: a JSON object with `from`
    and `to`, the start and end boundaries in `text` of the run of the
    text of the tag line of the citation of `E` in the text of that file
    (term `documents#origin`; for `"citation-entry"`), of the inline
    citation (for `"inline-citation"`), or of the form run (for
    `"vector-line"`).
  - `cited`: the name of the retired cited item of `E`.
  - `successors`: a JSON array of one or more JSON objects, one for each
    successor of `cited`, each with `name` (the name of the successor),
    `kind` (one of `"design"`, `"spec"`, `"schema"`, `"req"`, `"atom"`,
    `"term"`, and `"decision"`), `duplicate` (`true` when two or more
    declared items of the tree have its name, so that no edge has it as
    its cited item (`ontology#edge`), and `false` otherwise), optional
    `label` (its current revision,
    omitted when it is a term with no label), and, when `origin-kind` is
    `"vector-line"`, `in-vector-owner` (when the vector set is of an
    item of the kind `design` D, `true` when the successor is a schema
    that D holds directly and `false` otherwise; when the vector set is
    of an item of the kind `spec` S, `true` when the successor is a
    schema that S holds and `false` otherwise).
- `result`: no vector of the group has this member; these forms name no
  question for `result`.
- `values`: a JSON object with `fix-allowed` (`true` when a fix meeting
  `limit-retired-fix-edit-sets` exists, and `false` otherwise) and, when
  `fix-allowed` is `true`, `edit-sets`: a JSON array with one JSON
  object for each successor in the code point order of successor names,
  holding `successor` (the successor's name), `pinned` (whether the edge
  `E′` to that successor is pinned), optional `label` (when `pinned` is
  `true`, the current revision that the edge `E′` pins), `path` (the
  valid path within which every edit of that edit set has its spot), and
  `runs` (a JSON array of one or more JSON objects, each with `from` and
  `to`, the start and end boundaries in `text` of each run within which
  an edit of that edit set may have its spot, in increasing numerical
  order of `from`).

When `fix-allowed` is `false`, a conforming program gives no fix for the
`retired` finding. When `fix-allowed` is `true`, a conforming program
need not give a fix; when that program gives a fix for the `retired`
finding, that fix has as many edit sets as `edit-sets` has elements, in
the same order, where each edit set edits only `path` within the runs of
`runs`, gives in its edited tree the edge `E′` to that element's
`successor` (for each vector line of the group when `origin-kind` is
`"vector-line"`, with `label` when `pinned` is `true`, and unpinned when
`pinned` is `false`), and keeps any other edges of the citation.

### 6.4 Findings of the class `cycle`

@schema cycles-vector=v1
@cites {
    rfc/8259,
    conformance#{conforming-program=v1, own-store=v1},
    text#{
        text=v1, character=v1, whole-number=v1, decimal-numeral=v1,
        position=v1, code-point-order=v1, sequence=v1, result=v1,
        code-span=v1,
    },
    files#{path=v1, path-set=v1, valid-path-set=v1},
    data-forms#{
        index=v1, group-form-list=v1, vector-meaning=v1, json-value=v1,
    },
    identifiers#{
        external-namespaces=v1, validate-bindings=v1, declaration=v1,
        tag-line-text=v1,
    },
    ontology#{
        declared-item=v1, item-name=v1, content-id=v1, edge=v1,
        supersedes-edge=v1, refines-edge=v1, tree=v1, finding-class=v1,
        parameter=v1,
    },
    object-store#{store-file=v1, tree-object-store=v1},
    documents#{
        file-readers=v1, item-file=v1, tree-edge=v1, origin-position=v1,
        position-order=v1, tree-finding=v1,
    },
    #{
        historical-paths=v1, historical-file=v1, edge-cycle=v1,
        cycle-finding=v1, give-cycle-findings=v1,
        omit-findings-under-invalid-historical-paths=v1,
    },
}

The group `cycles` holds the vectors of the requirements
`give-cycle-findings` and
`omit-findings-under-invalid-historical-paths`. Each vector gives a
binding of `historical-paths`, the declared items of a tree (with their
kinds, canonical content ids, optional file paths, and optional
declaration origin positions), and the `supersedes` and `refines` edges
of the tree. The vector gives the `cycle` findings of the tree by
subject and spot (when the finding has a spot), or `{}` when the binding
of `historical-paths` is not valid. The group uses no need, so these
forms give no need names.

The input of each vector stands for a tree with a valid object store
(`object-store#tree-object-store`, or a valid program's own store),
`persons` unbound, a valid binding of `file-readers`, and a binding of
`external-namespaces` for which a conforming program of Identifiers
gives the result "valid". Each vector checks a conforming program when
no other process changes these inputs while the program runs.

The JSON values, objects, arrays, strings, numbers, and the literal
names `true` and `false` of this schema are as RFC 8259 defines them.
Inside `input` and `values`, a text is a JSON string whose characters
are the characters of the text in order, a whole number of 1 or more is
a JSON number written as its decimal numeral, and a sequence is a JSON
array of its elements in order.

- `input`: a JSON object with three members:
  - `historical-paths`: a binding of `historical-paths`, as a JSON array
    of the path set members of that path set, each a text, in order.
  - `items`: the declared items of the tree, as a sequence. Each element
    is a JSON object with `name` (the name of the item), `kind` (one of
    `"design"`, `"spec"`, `"schema"`, `"req"`, `"atom"`, `"term"`, and
    `"decision"`), `id` (the content id of the canonical object of the
    item), optional `path` (the valid path of the file of the item,
    omitted when the item comes from a valid program's own store with no
    file), and, when the item stands in a text file (when `path` is
    present and is not a store path in `.sinter/`), `line` (the line
    number of the origin position of the text of the tag line of the
    declaration of the item) and `column` (the column of that origin
    position).
  - `edges`: the `supersedes` and `refines` edges of the tree, as a
    sequence. Each element is a JSON object with `kind` (`"supersedes"`
    or `"refines"`), `fits` (`true` when the edge says what its kind of
    edge says in the tree, and `false` otherwise), `source` (the 1-based
    index of the source in `items`), and `cited` (the 1-based index of
    the cited item in `items`).
- `result`: no vector of the group has this member; these forms name no
  question for `result`.
- `values`: `{}` when `historical-paths` is not a valid path set;
  otherwise, a JSON object with one member, `findings`, a JSON array
  with one element for each `cycle` tree finding of the tree, in code
  point order of `subject`. Each element is a JSON object with `subject`
  (the subject of the finding), optional `path` (present when the
  finding has a spot: the valid path of the spot of the finding), and
  optional `line` and `column` (present when the spot has a span: the
  line number and column of the start of the spot of the finding).

When `values` is `{}`, a conforming program gives no finding of the
class `cycle` for the tree. When `values` is not `{}` and a conforming
program gives the findings of the class `cycle` of the tree under the
bindings, that program gives one finding of that class for each element
of `findings`, with the subject that the element states, and gives no
other finding of that class; when that program gives the spot of such a
finding, the spot has the valid path (and start position when `line` and
`column` are present) that the element states, and no spot when `path`
is absent.

### 6.5 Findings of the class `deleted-decision`

@schema deleted-decisions-vector=v1
@cites {
    rfc/8259,
    conformance#{conforming-program=v1},
    text#{
        text=v1, character=v1, code-point-order=v1, sequence=v1,
        result=v1, code-span=v1,
    },
    files#{path-set=v1, valid-path-set=v1},
    data-forms#{group-form-list=v1, vector-meaning=v1, json-value=v1},
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        declared-item=v1, decision-record=v1, item-name=v1, tree=v1,
        finding-class=v1, parameter=v1,
    },
    object-store#{tree-object-store=v1},
    documents#{file-readers=v1, name-set=v1, tree-finding=v1},
    #{
        historical-paths=v1, deleted-decision-finding=v1,
        give-deleted-decision-findings=v1,
    },
}

The group `deleted-decisions` holds the vectors of the requirement
`give-deleted-decision-findings`. Each vector gives a binding of
`historical-paths` (valid or not), the declared items of a base tree,
and the declared items of a tree. The vector gives the subjects of the
`deleted-decision` findings of the tree against the base tree. The group
uses no need, so these forms give no need names.

The input of each vector stands for trees with valid object stores
(`object-store#tree-object-store`), `persons` unbound, a valid binding of
`file-readers`, and a binding of `external-namespaces` for which a
conforming program of Identifiers gives the result "valid". Each vector
checks a conforming program when no other process changes these inputs
while the program runs.

The JSON values, objects, arrays, strings, and the literal names `true`
and `false` of this schema are as RFC 8259 defines them. Inside `input`
and `values`, a text is a JSON string whose characters are the
characters of the text in order, and a sequence is a JSON array of its
elements in order.

- `input`: a JSON object with three members:
  - `historical-paths`: a binding of `historical-paths`, as a JSON array
    of the path set members of that path set, each a text, in order.
  - `base`: the declared items of the base tree, as a sequence.
  - `tree`: the declared items of the tree, as a sequence.
  Each element of `base` and of `tree` is a JSON object with `name` (the
  name of the item), `kind` (one of `"design"`, `"spec"`, `"schema"`,
  `"req"`, `"atom"`, `"term"`, and `"decision"`), and, when the item is
  in a set of names, `set` (`"shared"` for the shared set, or
  `"design:"` followed by the name of the item of the kind `design` for
  the set of that design).
- `result`: no vector of the group has this member; these forms name no
  question for `result`.
- `values`: a JSON object with one member, `findings`, a JSON array of
  the subjects of the `deleted-decision` tree findings of the tree
  against the base tree, each once, in code point order (whether or not
  `historical-paths` is a valid path set).

When a conforming program gives the findings of the class
`deleted-decision` of the tree against the base tree under the valid
bindings of `file-readers` and `external-namespaces`, that program gives
one finding of that class with no spot for each subject in `findings`
and gives no other finding of that class, whether or not
`historical-paths` is a valid path set.

### 6.6 Findings of the class `reused-label`

@schema reused-labels-vector=v1
@cites {
    rfc/8259,
    conformance#{conforming-program=v1, own-store=v1},
    text#{
        text=v1, character=v1, code-point-order=v1, sequence=v1,
        result=v1, code-span=v1,
    },
    files#{path=v1, path-set=v1, valid-path-set=v1},
    data-forms#{
        group-form-list=v1, vector-meaning=v1, json-value=v1,
        hash-form=v1,
    },
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        declared-item=v1, item-name=v1, item-revision=v1,
        content-hash=v1, tree=v1, finding-class=v1, parameter=v1,
    },
    object-store#{store-file=v1, tree-object-store=v1},
    documents#{
        file-readers=v1, name-set=v1, item-file=v1, tree-finding=v1,
    },
    revisions#{base-item=v1},
    #{
        historical-paths=v1, historical-file=v1, new-label-item=v1,
        reused-label-finding=v1, give-reused-label-findings=v1,
        omit-findings-under-invalid-historical-paths=v1,
    },
}

The group `reused-labels` holds the vectors of the requirements
`give-reused-label-findings` and
`omit-findings-under-invalid-historical-paths`. Each vector gives a
binding of `historical-paths`, the declared items of a base tree, the
declared items of a tree, and a finite sequence L of trees. The vector
gives the subjects of the `reused-label` findings of the tree against
the base tree and L, or `{}` when the binding of `historical-paths` is
not valid. The group uses no need, so these forms give no need names.

The input of each vector stands for trees with valid object stores
(`object-store#tree-object-store`, or valid program's own stores),
`persons` unbound, a valid binding of `file-readers`, and a binding of
`external-namespaces` for which a conforming program of Identifiers
gives the result "valid". Each vector checks a conforming program when
no other process changes these inputs while the program runs.

The JSON values, objects, arrays, strings, and the literal names `true`
and `false` of this schema are as RFC 8259 defines them. Inside `input`
and `values`, a text is a JSON string whose characters are the
characters of the text in order, and a sequence is a JSON array of its
elements in order.

- `input`: a JSON object with four members:
  - `historical-paths`: a binding of `historical-paths`, as a JSON array
    of the path set members of that path set, each a text, in order.
  - `base`: the declared items of the base tree, as a sequence.
  - `tree`: the declared items of the tree, as a sequence.
  - `history`: the finite sequence L of trees, as a JSON array in which
    each element is the sequence of declared items of that element of L.
  Each declared item in `base`, in `tree`, and in each element of
  `history` is a JSON object with `name` (the name of the item), `kind`
  (one of `"design"`, `"spec"`, `"schema"`, `"req"`, `"atom"`, `"term"`,
  and `"decision"`), `hash` (the content hash of the canonical object of
  the item, a text that fits the hash form), optional `path` (the valid
  path of the file of the item, omitted when the item comes from a valid
  program's own store with no file), optional `label` (the current
  revision of the item, omitted when it is a term with no label), and,
  when the item is in a set of names, `set` (`"shared"` for the shared
  set, or `"design:"` followed by the name of the item of the kind
  `design` for the set of that design).
- `result`: no vector of the group has this member; these forms name no
  question for `result`.
- `values`: `{}` when `historical-paths` is not a valid path set;
  otherwise, a JSON object with one member, `findings`, a JSON array of
  the subjects of the `reused-label` tree findings of the tree against
  the base tree and `history`, each once, in code point order.

When `values` is `{}`, a conforming program gives no finding of the
class `reused-label` for the tree. When `values` is not `{}` and a
conforming program gives the findings of the class `reused-label` of the
tree against the base tree and `history` under the bindings, that
program gives one finding of that class with each subject in `findings`
and gives no other finding of that class.
