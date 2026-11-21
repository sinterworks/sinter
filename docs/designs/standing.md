<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Standing
@design standing=v1
@cites text=v1
@cites identifiers=v1
@cites files=v1
@cites data-forms=v1
@cites ontology=v1
@cites changes=v1
@cites findings=v1
@cites documents=v1
@cites revisions=v1
@cites ledger=v1
@cites approval=v1
@cites rfc/8259
Specifies the parameter `historical-paths` and historical files; the successors of retired declared items; the finding classes `retired`, `cycle`, `deleted-decision`, and `reused-label`; the conditions on an offered fix of a `retired` finding; and requirements for conforming programs that give successors and the findings of these classes.

Declared items change over time: authors replace them with `supersedes`
edges, withdraw them with `@deprecated`, and give them new labels when
their revised content changes. When a declared item is retired, other
items that cite that declared item can still name it, and in-force items
can replace it through effective `supersedes` edges. A conforming
program finds those successors, reports edges to retired items, reports
cycles of `supersedes` and `refines` edges, reports decision records
that a change deletes, and reports items that reuse a label from the
history of the default branch for other content. A repository can also
name historical paths so that historical files give no findings of these
classes at spots in those files.

From Text and notation (`text`), the design takes texts, characters,
spaces, tabs, places, lines, line numbers, whole numbers, decimal
numerals, boundaries, runs, spans, positions, code point order, code
spans, sequences, and what a conforming program and a result are. From
Identifiers (`identifiers`), it takes tag lines, declarations,
citations, citation lines with the production `every-part`, citation
entries, inline citations, tag line texts, the parameter
`external-namespaces` with its bindings, and the results that a
conforming program of Identifiers gives. From Files and paths (`files`),
it takes valid paths, path sets, valid path sets, and membership in the
set of a path set. From Data forms (`data-forms`), it takes JSON values,
indexes, hash forms, vector lines, test-vector sets, the forms of a
group, and the meaning of a vector. From RFC 8259, the design takes JSON
values, with their objects, members, arrays, strings, numbers, and the
literal names `true` and `false`.

From the Ontology (`ontology`), the design takes trees, items, declared
items and their kinds, decision records, containment, names, current
revisions, same items across trees, vector sets, groups of conformance
vectors, sites, external items, edges of all five kinds and when an edge
says what its kind of edge says, pinned edges, subjects of approval,
approval states, deprecated items, effective `supersedes` edges, retired
items, items in force, the default branch, the ledger, finding classes,
and parameters. From Changes (`changes`), it takes commits, shallow
commits, the files of the tree of a commit, the parameter
`default-branch-name` with its bindings, the commit of the default
branch, the change of a commit, the base of the change of a commit,
first-parent lines, repository reads, and undisturbed repository reads.
From Findings (`findings`), it takes spots, edits, edit sets,
edited texts, edited trees, fixes, finding parts, and the requirement
`findings#limit-fix-edit-sets`.

From Documents (`documents`), the design takes the parameter
`file-readers` with its bindings, read files, files that cannot be read,
tag texts, accepted inputs, files of declared items, sets of names,
named items, origins, origin positions, extent hashes, vector files, the
edges of a tree with their form runs and form positions, position
subjects, the order of positions, the spots of runs, and tree findings.
From Revisions (`revisions`), it takes base items. From the Ledger
(`ledger`), it takes stored ledgers, ledger objects, and valid ledgers.
From Approval (`approval`), it takes the parameter `approval-kinds` with
its bindings, approval needs, latest judgments, merged content, in force
under the bindings, and incomplete first-parent lines.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [tree](sinter:ontology#tree=v1) | a set of files, each a valid path with a content, such as the tree of a commit or the tree of a working tree |
| base tree | the earlier tree with which a conforming program compares a tree, such as the tree of the base of the change of a commit |
| [binding of `historical-paths`](sinter:#historical-paths=v1) | a path set; when that path set is valid, the files whose valid paths are in its set are the historical files |
| [historical file](sinter:#historical-file=v1) | a file of a tree whose valid path is in the set of a valid binding of `historical-paths` |
| [retired](sinter:ontology#retired-item=v1), [in force](sinter:ontology#in-force-item=v1) | a declared item is retired in a tree at a point of a ledger when it is deprecated, when it is the cited item of an effective `supersedes` edge and is on no cycle of `supersedes` edges, or when it belongs to a retired design or specification; a declared item is in force when it is not retired |
| [in force under the bindings](sinter:approval#bound-in-force-item=v1) | in force as the atom `ontology#in-force-item` gives it, under the bindings of `approval-kinds`, `default-branch-name`, `file-readers`, and `external-namespaces` |
| [effective `supersedes` edge](sinter:ontology#effective-supersedes-edge=v1) | a `supersedes` edge that says what `supersedes` says, whose source and every item that holds its source are not deprecated, and whose source is approved |
| [direct replacement](sinter:#successor=v1) | a declared item y directly replaces a declared item x when an effective `supersedes` edge has y as its source and x as its cited item, or matches `every-part` and replaces x by y by part name |
| [successor](sinter:#successor=v1) | a declared item in force that replaces a retired declared item through one or more direct replacements, with every intermediate item retired |
| [cycle of `supersedes` and `refines` edges](sinter:#edge-cycle=v1) | a maximal non-empty set of declared items of a tree in which each member reaches each member (itself included) along one or more `supersedes` and `refines` edges that say what their kind of edge says (`supersedes` edges effective or not, with their `every-part` part replacements) |
| [declaration order](sinter:#cycle-finding=v1) | the order of declared items of a tree by the valid path of each item's file in code point order, and then by the origin position of the text of the tag line of each item's declaration in the order of positions |
| [anchor member](sinter:#cycle-finding=v1) | among the members of a cycle of `supersedes` and `refines` edges whose name comes first in code point order, the member that comes first in declaration order |
| [base item](sinter:revisions#base-item=v1) | the one declared item of a base tree with the same name in the corresponding set of names, of any kind, when the declared item of the tree is also the one declared item with its name in its set of names |
| [item with a new label](sinter:#new-label-item=v1) | a declared item of a tree that has a current revision, whose file is not a historical file, that is in no set of names of that tree with another declared item of the same name, and that either has no base item in the base tree or whose base item has no current revision or a different current revision |
| [incomplete first-parent line](sinter:approval#incomplete-first-parent-line=v1) | a first-parent line of the commit of the default branch of a git repository that is incomplete for the repository reads from which a program takes that first-parent line and the files of the trees of the commits of that first-parent line, under a valid binding of `file-readers`, as the term `approval#incomplete-first-parent-line` gives it |
| [cut history](sinter:#cut-history=v1) | a history of the default branch whose first-parent line is incomplete |
| [approval completion](sinter:#approval-completion=v1) | an assignment of approved or not approved to each subject of approval of a tree that keeps the known state of every decided subject of approval and chooses approved or not approved for each undecided subject of approval |
| [tree finding](sinter:documents#tree-finding=v1) | a finding of one tree, with a class, a subject, and either a spot or no spot, that is not ackable |
| [`retired`](sinter:#retired-finding=v1) | the finding class of `cites`, `satisfies`, `verifies`, and `refines` edges that say what their kind of edge says, whose source counts, whose cited item counts as retired, and whose file is not a historical file |
| [`cycle`](sinter:#cycle-finding=v1) | the finding class of the names of the anchor members of cycles of `supersedes` and `refines` edges, when the anchor member is not in a historical file |
| [`deleted-decision`](sinter:#deleted-decision-finding=v1) | the finding class of decision records of a base tree whose name no declared item in the shared set of a tree has |
| [`reused-label`](sinter:#reused-label-finding=v1) | the finding class of items with a new label whose base item in a tree of the first-parent line of the default branch had the same label with a different kind or a different extent hash |

## 2. Retirement, cycles, and guarantees over time

### 2.1 Historical paths and historical files

A repository can bind the parameter `historical-paths` to a valid path
set (schema `historical-paths`). The empty path set is a valid binding
under which no file of any tree is historical. The term
`historical-file` gives the historical files of a tree, whatever reads
those files: a markdown file, a code file, a vector file, or a file with
no reader.

The declared items and edges of a historical file are those that the
terms `documents#item-file` and `documents#tree-edge` give. For example,
when `docs/devlog.md` is a historical file and holds `@cites d1=v1`
where `d2` supersedes `d1`, the edge still exists, and the tree has no
`retired` finding for that edge because its spot lies in a historical
file.

### 2.2 Successors of a retired item

The term `successor` defines the successors of a declared item in a tree
at a point of a ledger. A retired declared item can have zero, one, or
several successors. These examples show how the term `successor` works
when every item is approved and no item carries `@deprecated` unless
stated:

1. **A chain.** Decision record `d2` has `@supersedes d1=v1`, and `d3`
   has `@supersedes d2=v1`. Both `d1` and `d2` are retired, and `d3` is
   in force. The only successor of `d1` is `d3`, and the only successor
   of `d2` is `d3`.
2. **A fork.** Both `d2` and `d3` have `@supersedes d1=v1`, and both are
   in force. The successors of `d1` are `d2` and `d3`.
3. **A diamond.** `d2` and `d3` both supersede `d1`, and `d4` supersedes
   both `d2` and `d3`. The only successor of `d1` is `d4`, given once.
4. **Every-part supersession and retirement of parts.** Design
   `billing-2` has `@supersedes billing=v1#*`. Design `billing` holds
   the requirements `billing#limit` and `billing#legacy`. Design
   `billing-2` holds the requirement `billing-2#limit` and no part named
   `legacy`. Both `billing#limit` and `billing#legacy` are retired
   because they belong to the retired design `billing`. The only
   successor of `billing#limit` is `billing-2#limit`. Because
   `billing-2` holds no part named `legacy`, `billing#legacy` has no
   successor.
5. **Deprecation.** Decision record `d1` carries `@deprecated`, and no
   effective `supersedes` edge cites `d1`. Then `d1` is retired and has
   no successor. When `d3` has `@supersedes d2=v1` and `d3` carries
   `@deprecated`, the edge from `d3` is not effective, so `d2` is in
   force and has no successor.
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
That atom refines `ontology#retired-item`.

For example, design `billing-2` has `@supersedes billing=v1#*`, and
`billing-2` is approved and in force. Each of these gives one `retired`
finding when its file is not historical:

- a sentence in `docs/guide.md` with `@cites billing#limit=v1` (a site
  always counts as a source);
- a function in `src/limit.ml` with `@satisfies billing#limit=v1` (a
  site always counts);
- a test with `@verifies billing#limit=v1` (a test always counts);
- an in-force requirement `quota#soft-limit` with
  `@refines billing#limit=v1`;
- a test with `@verifies billing[limits]` (the group `billing[limits]`
  counts as retired because `billing` is retired);
- in `billing-2.test-vectors.jsonl`, a vector line whose `"form"` is
  `"#old-schema=v1"` when `billing-2#new-schema` effectively supersedes
  `billing-2#old-schema` (`billing-2` is in force, so its vector group
  counts as a source).

By contrast, each of these gives no `retired` finding:

- the `supersedes` edge from `billing-2` to `billing`;
- `@cites billing#window=v1` inside `billing#limit`, because the source
  `billing#limit` is retired;
- a vector line in `billing.test-vectors.jsonl`, because the item of the
  kind design `billing` of that vector set is retired;
- a `@cites` edge to an external item such as `rfc/8259`, because an
  external item meets neither condition for counting as retired
  (`retired-finding`);
- an edge that does not say what its kind of edge says, such as
  `@satisfies d1=v1` to a retired decision record.

No requirement obliges a conforming program to offer a fix for a
`retired` finding. When a program does offer a fix for a `retired`
finding whose cited item has successors, the requirement
`limit-retired-fix-edit-sets` limits its edit sets. For example, suppose
that `billing-2#limit` has an effective `@supersedes billing#limit=v1`,
that `billing-2#limit` is in force at `v1`, and that `billing#window` is
in force. When `docs/guide.md` holds
`@cites billing#{limit=v1, window=v1}`, `billing#limit` has the single
successor `billing-2#limit`, so a fix that meets
`limit-retired-fix-edit-sets` has one edit set. That edit set edits only
that tag line so that it cites `billing-2#limit=v1` and
`billing#window=v1`, for example
`@cites {billing-2#limit=v1, billing#window=v1}`. When the cited item
has two successors `d3` and `d4`, a fix that meets
`limit-retired-fix-edit-sets` has two edit sets, first for `d3` and then
for `d4`, in code point order of their names. When the original edge is
unpinned (`@cites billing#limit=*`), the edge in the edited citation
stays unpinned (`@cites billing-2#limit=*`). When a `retired` finding is
on a vector line whose group holds several vector lines, each edit set
of a fix that meets `limit-retired-fix-edit-sets` rewrites the form pin
of every vector line of that group so that the edited vector file stays
a test-vector set. When the cited item has no
successor (for example a `@deprecated` record or a retired vector
group), `limit-retired-fix-edit-sets` adds no condition beyond
`findings#limit-fix-edit-sets`.

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
   declares `@term rate=v1`, design `billing-2` has
   `@supersedes billing=v1#*` and declares `@term rate` with no label,
   and `docs/guide.md` holds `@cites billing#rate=v1`. Because
   `billing-2#rate` has no current revision, no edit can write its
   current revision in place of the pin.
3. **A successor with a duplicate name.** Two items in the same set of
   names share the name `d2`, and one or both supersede `d1`. Because a
   duplicated name names none of those items (`documents#named-item`),
   no edit of the citation can cite that successor.
4. **A citation that already names the successor with another pin.** A
   citation is `@cites {d1=v1, d2=v1}`, where `d2` is the only successor
   of `d1` and the current revision of `d2` is `v2`. Because two entries
   with the same entry name make a citation invalid
   (`identifiers#citation-line`), no single citation can cite both
   `d2=v2` and `d2=v1`.

The same consequence holds when a retired item has two successors and
only one of them fails one of these conditions: because a fix that meets
`limit-retired-fix-edit-sets` has one edit set for each successor, a
conforming program offers no fix for that finding.

### 2.4 Findings of the class `cycle`

The term `edge-cycle` defines a cycle of `supersedes` and `refines`
edges in a tree, and the atom `cycle-finding` gives the findings of the
class `cycle`.

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
- inside a `@deprecated` design `old`, `old#p` and `old#q` supersede
  each other (subject `old#p`).

When `old#p` is in a historical file and `old#q` is not, the anchor
member is `old#p`, so the cycle gives no `cycle` finding. When `old#q`
is in a historical file and `old#p` is not, the anchor member is
`old#p`, so the tree still has the `cycle` finding. When two members of
a cycle share the first name in code point order, declaration order
chooses the anchor member (atom `cycle-finding`).

### 2.5 Deleted decision records

The atom `deleted-decision-finding` gives the findings of the class
`deleted-decision` for a tree against a base tree, using the shared set
(`documents#name-set`).

For example, when a change deletes the file of `@decision rust-bridge=v1`,
or renames `@decision parser-bridge=v1` to `@decision wasm-bridge=v1`,
the tree has one `deleted-decision` finding (`rust-bridge` or
`parser-bridge`). Moving the file of a decision record to another folder
with the same name keeps that name in the shared set and gives no
finding. Changing `@decision x=v1` to `@req x=v1` in the shared set
keeps the name `x` in the shared set and gives no `deleted-decision`
finding. When the file of `@decision rust-bridge=v1` stays at the same valid path
with content that is not valid UTF-8, the tree still has the
`deleted-decision` finding `rust-bridge`.

A `deleted-decision` finding has no spot, because the finding names a
decision record whose name no declared item in the shared set of the
tree has. Therefore, `deleted-decision` findings do not depend on
`historical-paths`, and no binding of `historical-paths`, valid or not,
removes a `deleted-decision` finding. The requirements
`compare-change-for-deleted-decisions`, `report-missing-base`, and
`omit-missing-base-report` cover the change of a commit.

### 2.6 Reused labels

The term `new-label-item` selects the declared items of a tree that the
atom `reused-label-finding` compares. That atom compares each such item
against a sequence of trees by `revisions#base-item`. For the change of
a commit, that sequence is the trees of the commits of the first-parent
line of the commit of the default branch.

For example, on the default branch, `@req billing#size` had label `v2`
with text T1, and later moved to label `v3` with text T2. The base tree
of a branch holds `billing#size=v3`.

- Moving `billing#size` back to `v2` with a new text T3 gives one
  `reused-label` finding with subject `billing#size`.
- Moving `billing#size` back to `v2` with the exact same kind and exact
  same extent hash as T1 gives no `reused-label` finding.
- Deleting `billing#size` in one change and declaring
  `@req billing#size=v2` with new text in a later change gives one
  `reused-label` finding, because `billing#size` has no base item in the
  later change's base tree.
- An older label reuse on an untouched item `old=v1` gives no
  `reused-label` finding, because `old` keeps its base label and is not
  an item with a new label.
- A term with no label is never an item with a new label and gives no
  `reused-label` finding.
- A tree on the first-parent line that holds two items with the name
  `billing#size` gives `billing#size` no base item in that tree and
  therefore no comparison against that tree.
- A historical file in a tree of the first-parent line is still read for
  the labels and extent hashes of its declared items; `historical-paths`
  only prevents findings whose spot lies in a historical file of the
  checked tree.

For the change of a commit, the requirements
`compare-change-for-reused-labels`, `report-missing-base`,
`omit-missing-base-report`, `report-cut-history`, and
`omit-cut-history-report` state what a conforming program gives when the
change has no base, when the program does not give the findings of the
class `reused-label`, when the tree of the commit has no item with a new
label, or when the history of the default branch is cut (term
`cut-history`).

### 2.7 Bindings, ledgers, incomplete histories, and concurrent changes

Each definition and each requirement uses one binding of each parameter.
The requirement `omit-findings-under-invalid-historical-paths` covers a
binding of `historical-paths` that is not valid. Successors and
`deleted-decision` findings do not depend on `historical-paths`.

Successors and the class `retired` read in force under the bindings,
which reads the ledger. The requirements `report-missing-ledger-objects`
and `omit-missing-ledger-objects-report` cover a git repository that
does not hold its ledger objects. The term `approval-completion` and the
requirements `give-successors`, `give-retired-findings`, and
`limit-retired-fix-edit-sets` state what a conforming program gives when
the first-parent line of the commit of the default branch is incomplete
(term `approval#incomplete-first-parent-line`) or when the binding of
`default-branch-name` is not valid: any successor or `retired` finding
that does not depend on an undecided subject of approval is still given,
and any result that depends on one is omitted; when the cause is an
incomplete first-parent line, the program reports that it cannot see the
whole history. The classes `cycle`, `deleted-decision`, and
`reused-label` read no ledger.

What a program gives while another process changes a file, a ref, or the
ledger is a matter of the quality of an implementation.

### 2.8 Findings

Each finding of the classes `retired`, `cycle`, `deleted-decision`, and
`reused-label` is a [tree finding](sinter:documents#tree-finding=v1). No
finding of any of these classes is ackable.

| class | atom |
|---|---|
| `retired` | [`retired-finding`](sinter:#retired-finding=v1) |
| `cycle` | [`cycle-finding`](sinter:#cycle-finding=v1) |
| `deleted-decision` | [`deleted-decision-finding`](sinter:#deleted-decision-finding=v1) |
| `reused-label` | [`reused-label-finding`](sinter:#reused-label-finding=v1) |

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
    text#{code-span=v1},
    #{historical-paths=v1},
}

Under a valid binding H of `historical-paths`, a file of a tree is a
historical file of that tree under H when, and only when, the valid path
of that file is in the set of H.

### 4.2 Successors of a retired item

@term successor=v1
@cites {
    identifiers#{
        external-namespaces=v1, citation-entry=v1, citation-line=v1,
    },
    ontology#{
        declared-item=v1, item=v1, edge=v1, supersedes-edge=v1,
        effective-supersedes-edge=v1, retired-item=v1, in-force-item=v1,
        vector-set=v1, conformance-vector-group=v1, default-branch=v1,
        tree=v1, ledger=v1, parameter=v1,
    },
    changes#{
        commit=v1, default-branch-name=v1, default-branch-commit=v1,
        first-parent-line=v1,
    },
    ledger#{stored-ledger=v1},
    documents#{file-readers=v1, tree-edge=v1},
    approval#{approval-kinds=v1, bound-in-force-item=v1},
    text#{sequence=v1, code-span=v1},
}

This term is for a git repository R, a valid binding A of
`approval-kinds`, a valid binding D of `default-branch-name`, a valid
binding F of `file-readers`, a binding N of `external-namespaces`, a
tree T, and a point P of the ledger of R.

In this term, in force in T at P under A, D, F, and N is as the term
`approval#bound-in-force-item` gives it, and a declared item of T is
retired in T at P under A, D, F, and N when it is not in force there. In
this term, a `supersedes` edge of T under F and N is effective in T at P
under A, D, F, and N when that edge is effective in T at P (atom
`ontology#effective-supersedes-edge`), read as the term
`approval#bound-in-force-item` gives under A, D, F, and N.

A declared item y of T directly replaces a declared item x of T in T at
P under A, D, F, and N when, and only when, some `supersedes` edge of T
under F and N is effective in T at P under A, D, F, and N and says that
y is to replace x: either y is the source and x is the cited item of
that edge, or the production `every-part` matches the citation entry of
that edge and that edge says that x is to be replaced by y.

For a declared item x of T that is retired in T at P under A, D, F, and
N, a declared item s of T is a successor of x in T at P under A, D, F,
and N when, and only when, both of these conditions hold:

1. s is in force in T at P under A, D, F, and N.
2. There is a finite sequence of one or more pairs (u, v) of declared
   items of T that meets all three of these conditions:
   - the first item of the first pair is x, and the second item of the
     last pair is s;
   - for each pair (u, v) of the sequence, v directly replaces u in T at
     P under A, D, F, and N;
   - for each pair before the last, its second item is the first item of
     the next pair, and that item is retired in T at P under A, D, F,
     and N.

A declared item of T that is in force in T at P under A, D, F, and N has
no successor. An item of T that is not a declared item, such as a group
of conformance vectors or a vector set, has no successor.

### 4.3 Findings of the class `retired`

@atom retired-finding=v1
@refines ontology#retired-item=v1
@cites {
    identifiers#{
        external-namespaces=v1, citation-entry=v1, inline-citation=v1,
    },
    data-forms#{vector-line=v1},
    ontology#{
        declared-item=v1, edge=v1, cites-edge=v1, satisfies-edge=v1,
        verifies-edge=v1, refines-edge=v1, vector-set=v1,
        conformance-vector-group=v1, default-branch=v1, tree=v1,
        ledger=v1, parameter=v1,
    },
    changes#{
        commit=v1, default-branch-name=v1, default-branch-commit=v1,
        first-parent-line=v1,
    },
    ledger#{stored-ledger=v1},
    documents#{
        file-readers=v1, tree-edge=v1, origin=v1, origin-position=v1,
        position-subject=v1, run-spot=v1, tree-finding=v1,
    },
    approval#{approval-kinds=v1, bound-in-force-item=v1},
    text#{code-span=v1},
    #{historical-paths=v1, historical-file=v1},
}

This atom is for a git repository R, a valid binding A of
`approval-kinds`, a valid binding D of `default-branch-name`, a valid
binding F of `file-readers`, a binding N of `external-namespaces`, a
valid binding H of `historical-paths`, a point P of the ledger of R, and
a tree T.

A source of an edge of T under F and N counts in T at P under A, D, F,
and N when, and only when, one of these three conditions holds:

1. The source is a declared item of T that is in force in T at P under
   A, D, F, and N (term `approval#bound-in-force-item`).
2. The source is a group of conformance vectors of a vector set of T,
   and the item of the kind design or of the kind specification of that
   vector set is in force in T at P under A, D, F, and N (term
   `approval#bound-in-force-item`).
3. The source is neither a declared item nor a group of conformance
   vectors.

A cited item of an edge of T under F and N counts as retired in T at P
under A, D, F, and N when, and only when, one of these two conditions
holds:

1. The cited item is a declared item of T that is not in force in T at P
   under A, D, F, and N (term `approval#bound-in-force-item`).
2. The cited item is a vector set of T, or a group of conformance
   vectors of a vector set of T, and the item of the kind design or of
   the kind specification of that vector set is not in force in T at P
   under A, D, F, and N (term `approval#bound-in-force-item`).

At P under A, D, F, N, and H, T has one tree finding of the class
`retired` for each edge e that T has under F and N that meets all four
of these conditions:

1. e is of the kind `cites`, `satisfies`, `verifies`, or `refines`, and
   e says what its kind of edge says in T.
2. The source of e counts in T at P under A, D, F, and N.
3. The cited item of e counts as retired in T at P under A, D, F, and N.
4. The file of e in T is not a historical file of T under H.

For an edge that a citation entry or an inline citation gives, the
subject of that tree finding is the position subject of the origin
position of that citation entry or inline citation, and the spot of that
tree finding is the spot of the run of that citation entry or inline
citation in the text of the file of the edge. For an edge that a vector
line gives, the subject of that tree finding is the position subject of
the form position of that edge in the file of the edge, and the spot of
that tree finding is the spot of the form run of that edge in the text
of the file of the edge.

### 4.4 Cycles of `supersedes` and `refines` edges

@term edge-cycle=v1
@cites {
    identifiers#{
        external-namespaces=v1, citation-entry=v1, citation-line=v1,
    },
    ontology#{
        declared-item=v1, edge=v1, supersedes-edge=v1, refines-edge=v1,
        tree=v1, parameter=v1,
    },
    documents#{file-readers=v1, tree-edge=v1},
    text#{sequence=v1, code-span=v1},
}

This term is for a tree T, a valid binding F of `file-readers`, and a
binding N of `external-namespaces`. In T under F and N, a pair (x, y) of
declared items of T is a cycle step when, and only when, either of these
two conditions holds:

- some `supersedes` edge of T under F and N says what the kind of edge
  `supersedes` says in T and says that x is to replace y (either because
  x is the source and y is the cited item of that edge, or because the
  production `every-part` matches the citation entry of that edge and
  that edge says that y is to be replaced by x);
- some `refines` edge of T under F and N says what the kind of edge
  `refines` says in T, and x is the source and y is the cited item of
  that edge.

A declared item a of T reaches a declared item b of T along cycle steps
in T under F and N when, and only when, there is a finite sequence of
one or more cycle steps of T whose first pair has a as its first item,
whose last pair has b as its second item, and in which, for each pair
before the last, its second item is the first item of the next pair.

A cycle of `supersedes` and `refines` edges in T under F and N is a
non-empty set C of declared items of T that meets both of these
conditions:

1. For each declared item a in C and each declared item b in C
   (including when a and b are the same declared item), a reaches b
   along cycle steps in T under F and N.
2. No set of declared items of T that holds every declared item of C and
   at least one other declared item of T meets condition 1.

### 4.5 Findings of the class `cycle`

@atom cycle-finding=v1
@cites {
    files#{path=v1},
    identifiers#{
        external-namespaces=v1, declaration=v1, tag-line-text=v1,
    },
    ontology#{declared-item=v1, item-name=v1, tree=v1, parameter=v1},
    documents#{
        file-readers=v1, item-file=v1, origin=v1, origin-position=v1,
        position-order=v1, run-spot=v1, tree-finding=v1,
    },
    text#{code-point-order=v1, position=v1, text=v1, code-span=v1},
    #{historical-paths=v1, historical-file=v1, edge-cycle=v1},
}

In this atom, one declared item d1 of a tree comes before another
declared item d2 of that tree in declaration order when, and only when,
either of these two conditions is true:

1. The valid path of the file of d1 comes before the valid path of the
   file of d2 in code point order.
2. The valid path of the file of d1 and the valid path of the file of d2
   are the same, and the origin position of the text of the tag line of
   the declaration of d1 comes before the origin position of the text of
   the tag line of the declaration of d2 in the order of positions.

For a tree T, a valid binding F of `file-readers`, a binding N of
`external-namespaces`, and a valid binding H of `historical-paths`, the
anchor member of a cycle C of `supersedes` and `refines` edges in T
under F and N is this: among the declared items of C whose name in T
comes first in code point order among the names in T of all declared
items of C, the declared item that comes first in declaration order.

Under F, N, and H, T has one tree finding of the class `cycle` for each
text s that is the name in T of the anchor member of at least one cycle
of `supersedes` and `refines` edges in T under F and N whose anchor
member has a file in T that is not a historical file of T under H. The
subject of that tree finding is s. Among all anchor members of cycles of
`supersedes` and `refines` edges in T under F and N whose name in T is s
and whose file in T is not a historical file of T under H, let d be the
declared item that comes first in declaration order; the spot of that
tree finding is the spot of the run of the text of the tag line of the
declaration of d in the text of the file of d in T.

### 4.6 Findings of the class `deleted-decision`

@atom deleted-decision-finding=v1
@cites {
    identifiers#{external-namespaces=v1},
    ontology#{
        declared-item=v1, decision-record=v1, item-name=v1, tree=v1,
        parameter=v1,
    },
    documents#{file-readers=v1, name-set=v1, tree-finding=v1},
    text#{text=v1, code-span=v1},
}

For a tree T and a base tree B, under a valid binding F of
`file-readers` and a binding N of `external-namespaces`, the declared
items, their kinds, their names, and the sets of names of T and of B are
those that T and B have under F and N. Under F and N, T has one tree
finding of the class `deleted-decision` against B for each text t that
is the name in B of a decision record of B such that no declared item in
the shared set of T has a name in T that is the same text as t.

The subject of that tree finding is t. That tree finding has no spot.

### 4.7 Items with new labels

@term new-label-item=v1
@cites {
    identifiers#{external-namespaces=v1},
    ontology#{
        declared-item=v1, item-name=v1, item-revision=v1, tree=v1,
        parameter=v1,
    },
    documents#{file-readers=v1, item-file=v1, name-set=v1},
    revisions#{base-item=v1},
    text#{text=v1, code-span=v1},
    #{historical-paths=v1, historical-file=v1},
}

For a tree T and a base tree B, under a valid binding F of
`file-readers`, a binding N of `external-namespaces`, and a valid
binding H of `historical-paths`, a declared item d of T (under F and N)
is an item with a new label against B under F, N, and H when, and only
when, all four of these conditions hold:

1. d has a current revision in T.
2. The file of d in T is not a historical file of T under H.
3. For each set of names of T (under F and N) in which d is, no other
   declared item in that set of names has a name in T that is the same
   text as the name of d in T.
4. Either d has no base item in B (under F and N), or the base item e of
   d in B has no current revision in B or has a current revision in B
   that is not the same text as the current revision of d in T.

### 4.8 Findings of the class `reused-label`

@atom reused-label-finding=v1
@cites {
    identifiers#{
        external-namespaces=v1, declaration=v1, tag-line-text=v1,
    },
    ontology#{
        declared-item=v1, item-name=v1, item-revision=v1, tree=v1,
        parameter=v1,
    },
    documents#{
        file-readers=v1, extent-hash=v1, item-file=v1, origin=v1,
        run-spot=v1, tree-finding=v1,
    },
    revisions#{base-item=v1},
    text#{text=v1, sequence=v1, code-span=v1},
    #{historical-paths=v1, new-label-item=v1},
}

For a tree T, a base tree B, and a finite sequence L of trees, under a
valid binding F of `file-readers`, a binding N of `external-namespaces`,
and a valid binding H of `historical-paths`, T has one tree finding of
the class `reused-label` against B and L for each declared item d of T
that meets both of these conditions:

1. d is an item with a new label against B under F, N, and H.
2. For at least one element K of L, d has a base item e in K (under F
   and N), e has a current revision in K that is the same text as the
   current revision of d in T, and either d and e are of different kinds
   of item or the extent hash of d in T (under F and N) is not the
   extent hash of e in K (under F and N).

The subject of that tree finding is the name of d in T. The spot of that
tree finding is the spot of the run of the text of the tag line of the
declaration of d in the text of the file of d in T.

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
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        item=v1, declared-item=v1, subject-of-approval=v1,
        approval-state=v1, edge=v1, supersedes-edge=v1,
        effective-supersedes-edge=v1, retired-item=v1, in-force-item=v1,
        default-branch=v1, tree=v1, ledger=v1, parameter=v1,
    },
    changes#{
        commit=v1, commit-file=v1, shallow-commit=v1,
        default-branch-name=v1, default-branch-commit=v1,
        first-parent-line=v1, repository-read=v1,
    },
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    documents#{
        file-readers=v1, read-file=v1, extent-hash=v1, tree-edge=v1,
        tree-finding=v1,
    },
    approval#{
        approval-kinds=v1, approval-need=v1, latest-judgment=v1,
        merged-content=v1, incomplete-first-parent-line=v1,
    },
    text#{conforming-program=v1, result=v1, sequence=v1, code-span=v1},
    #{historical-paths=v1, successor=v1, retired-finding=v1},
}

This term is for a git repository R whose ledger is valid and that holds
its ledger objects, a valid binding A of `approval-kinds`, a binding D
of `default-branch-name` (valid or not), a valid binding F of
`file-readers`, a binding N of `external-namespaces` for which a
conforming program of the design Identifiers gives the result "valid", a
tree T, a point P of the ledger of R, and the repository reads from
which a program
takes the ledger of R, the commit of the default branch of R under D
(when D is a valid binding), the first-parent line of that commit (when
the default branch has a commit under D), and the files of the trees of
the commits of that first-parent line. In this term, R holds a git
object when R holds that git object at the end of those repository
reads.

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
the git tree object of C names, and holds every blob that a regular-file
entry among the entries of the git tree object of C names when that
regular-file entry gives a file of the tree of C that is a read file of
the tree of C under F.

For each subject of approval S that T has under F and N, S is either
decided (known approved or known not approved) or undecided in T at P
under A, D, F, and N for those repository reads:

- When S needs approval under A (term `approval#approval-need`), S is
  decided: S is known approved when the latest judgment of S at P under
  F and N (term `approval#latest-judgment`) is of the kind `approval`,
  and S is known not approved otherwise.
- When S does not need approval under A and D is not a valid binding of
  `default-branch-name`, S is undecided.
- When S does not need approval under A, D is a valid binding of
  `default-branch-name`, and the default branch of R has no commit under
  D, S is decided and is known not approved.
- When S does not need approval under A, D is a valid binding of
  `default-branch-name`, the default branch of R has a commit d under D,
  and the first-parent line of d under F is not incomplete for those
  repository reads (term `approval#incomplete-first-parent-line`), S is
  decided: S is known approved when the revised content of S in T has
  merged into the default branch of R under D, F, and N (term
  `approval#merged-content`), and S is known not approved otherwise.
- When S does not need approval under A, D is a valid binding of
  `default-branch-name`, the default branch of R has a commit d under D,
  and the first-parent line of d under F is incomplete for those
  repository reads (term `approval#incomplete-first-parent-line`): S is
  decided and is known approved when some commit C of the held
  first-parent commits of d has an intact read tree under F for those
  repository reads and the tree of C has, under F and N, a subject of
  approval S2 that is the same subject of approval as S and whose
  declared item has, in the tree of C under F and N, the extent hash
  that the declared item of S has in T under F and N; otherwise, S is
  undecided.

An approval completion M of T at P under A, D, F, and N for those
repository reads is an assignment of one of the two states approved or
not approved to each subject of approval S of T such that each decided
subject of approval gets its known state (approved when known approved,
not approved when known not approved) and each undecided subject of
approval gets either approved or not approved.

Under an approval completion M:

- A declared item of T is approved under M when it is approved by the
  rules of the term `ontology#approval-state`, with the state approved
  of each subject of approval of T read as the state that M assigns to
  that subject of approval.
- A `supersedes` edge of T under F and N is effective under M when it
  meets the conditions of the atom `ontology#effective-supersedes-edge`,
  with approved read as approved under M.
- A declared item of T is retired under M when it meets the conditions
  of the atom `ontology#retired-item`, with effective `supersedes` edges
  read as effective under M; a declared item of T is in force under M
  when it is not retired under M (atom `ontology#in-force-item`).
- For a declared item x of T, a declared item s of T is a successor of x
  under M by the rules of the term `successor`, with in force, retired,
  and effective `supersedes` edges read under M. A declared item of T
  that is in force under M, or an item of T that is not a declared item,
  has no successor under M.
- Under a valid binding H of `historical-paths`, an edge e of T under F
  and N gives a `retired` tree finding under M when e meets the four
  conditions of the atom `retired-finding`, with in force read as in
  force under M; its subject and spot are those that the atom
  `retired-finding` gives for e.

## 5. Requirements

### 5.1 Successors of a retired item

@req give-successors=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        declared-item=v1, default-branch=v1, tree=v1, ledger=v1,
        parameter=v1,
    },
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
        repository-read=v1, undisturbed-read=v1,
    },
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    documents#{file-readers=v1},
    approval#{approval-kinds=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{successor=v1, approval-completion=v1},
}

This requirement applies for a git repository R whose ledger is valid
and that holds its ledger objects, under four bindings: a valid binding
A of `approval-kinds`, a binding D of `default-branch-name` (whether or
not D is a valid binding of `default-branch-name`), a valid binding F of
`file-readers`, and a binding N of `external-namespaces` for which a
conforming program of the design Identifiers gives the result "valid".
Under these bindings, this requirement applies when a conforming program
gives the successors of a declared item x of a tree T at a point P of
the ledger of R under A, D, F, and N, and each repository read from
which that program takes the ledger, the commit of the default branch
under D (when D is valid), the first-parent line of that commit, and the
files of the trees of the commits of that first-parent line is
undisturbed.

Let C be the set of approval completions of T at P under A, D, F, and N
for those repository reads (term `approval-completion`). When every
approval completion in C gives the same set of successors of x in T,
that program must give each item of that set once, must give no other
item, and must not give that it cannot see the whole history for the
successors of x. When two approval completions in C give different sets
of successors of x in T, that program must give no successor of x; when
D is a valid binding of `default-branch-name`, that program must give
that it cannot see the whole history for the successors of x; when D is
not a valid binding of `default-branch-name`, that program must not give
that it cannot see the whole history for the successors of x.

### 5.2 Findings of the class `retired`

@req give-retired-findings=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        finding-class=v1, default-branch=v1, tree=v1, ledger=v1,
        parameter=v1,
    },
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
        repository-read=v1, undisturbed-read=v1,
    },
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    documents#{file-readers=v1, tree-edge=v1, tree-finding=v1},
    approval#{approval-kinds=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{historical-paths=v1, retired-finding=v1, approval-completion=v1},
}

This requirement applies for a git repository R whose ledger is valid
and that holds its ledger objects, under five bindings: a valid binding
A of `approval-kinds`, a binding D of `default-branch-name` (whether or
not D is a valid binding of `default-branch-name`), a valid binding F of
`file-readers`, a binding N of `external-namespaces` for which a
conforming program of the design Identifiers gives the result "valid",
and a valid binding H of `historical-paths`. Under these bindings, this
requirement applies when a conforming program gives the findings of the
class `retired` of a tree T at a point P of the ledger of R under A, D,
F, N, and H, and each repository read from which that program takes the
ledger, the commit of the default branch under D (when D is valid), the
first-parent line of that commit, and the files of the trees of the
commits of that first-parent line is undisturbed.

Let C be the set of approval completions of T at P under A, D, F, and N
for those repository reads (term `approval-completion`). For each edge e
of T under F and N such that e gives a `retired` tree finding under
every approval completion in C (under H), that program must give that
tree finding once; and that program must give no other finding of the
class `retired` for T. When some edge e of T under F and N gives a
`retired` tree finding under some approval completion in C (under H) and
gives no `retired` tree finding under some other approval completion in
C (under H), and D is a valid binding of `default-branch-name`, that
program must give that it cannot see the whole history for the findings
of the class `retired` of T. Otherwise (when no edge of T under F and N
differs across C under H, or when D is not a valid binding of
`default-branch-name`), that program must not give that it cannot see
the whole history for the findings of the class `retired` of T.

### 5.3 Offered fixes of `retired` findings

@req limit-retired-fix-edit-sets=v1
@cites {
    files#{path=v1},
    identifiers#{
        external-namespaces=v1, validate-bindings=v1, tag-line=v1,
        citation=v1, citation-entry=v1, inline-citation=v1,
        tag-line-text=v1,
    },
    data-forms#{vector-line=v1, test-vector-set=v1},
    ontology#{
        declared-item=v1, item-name=v1, item-revision=v1, same-item=v1,
        external-item=v1, edge=v1, cites-edge=v1, pinned-edge=v1,
        site=v1, default-branch=v1, tree=v1, ledger=v1, parameter=v1,
    },
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
        repository-read=v1, undisturbed-read=v1,
    },
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    findings#{
        spot=v1, edit=v1, edit-set=v1, edited-text=v1, edited-tree=v1,
        fix=v1, finding-part=v1, limit-fix-edit-sets=v1,
    },
    documents#{
        file-readers=v1, tag-text=v1, accepted-input=v1, tree-edge=v1,
        origin=v1, tree-finding=v1, unreadable-file=v1, vector-file=v1,
    },
    approval#{approval-kinds=v1},
    text#{
        conforming-program=v1, result=v1, character=v1, space=v1,
        tab=v1, place=v1, line=v1, line-number=v1, whole-number=v1,
        boundary=v1, span=v1, run=v1, code-point-order=v1, text=v1,
        code-span=v1,
    },
    #{
        historical-paths=v1, successor=v1, retired-finding=v1,
        approval-completion=v1,
    },
}

This requirement applies for a git repository R whose ledger is valid
and that holds its ledger objects, a tree T, a point P of the ledger of
R, a valid binding A of `approval-kinds`, a binding D of
`default-branch-name` (whether or not D is a valid binding of
`default-branch-name`), a valid binding F of `file-readers`, a binding N
of `external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", and a valid binding H of
`historical-paths`, when each repository read from which a conforming
program takes the ledger, the commit of the default branch under D (when
D is valid), the first-parent line of that commit, and the files of the
trees of the commits of that first-parent line is undisturbed.

Let C be the set of approval completions of T at P under A, D, F, and N
for those repository reads (term `approval-completion`). For each edge E
of T under F and N that gives a `retired` tree finding f under every
approval completion in C (under H), let c be the cited item of E. When
two approval completions in C give different sets of successors of
c in T, that program must give no fix for f. When every approval
completion in C gives the same set K of successors of c in T, K has one
or more items, and that program gives a fix for f, that fix must meet
all three of these conditions:

1. The fix has exactly one edit set for each successor of c in K, in the
   code point order of the names of those successors in T.
2. Let W be this non-empty set of runs of the text of the file of E in
   T:
   - when a citation entry gives E, the single run of the text of the
     tag line of the citation of E in the text of that file (term
     `documents#origin`);
   - when an inline citation gives E, the single run of that inline
     citation in the text of that file;
   - when a vector line gives E, the form run of the edge of each vector
     line of the group of the vector line of E in that vector file
     (schema `data-forms#test-vector-set`).

   For each edit set of the fix, every edit of that edit set has a spot
   whose valid path is the valid path of the file of E in T, and whose
   span starts and ends at boundaries of one run in W.
3. For each successor s in K, let T′ be the edited tree of the edit set
   for s, read under F and N. Let t be the text of the file of E in T
   (with n characters), and let t′ be the edited text of the valid path
   of that file for the edit set (with n′ characters). In T′ under F and
   N:
   - when a citation entry gives E, let r be the run in W (starting at
     boundary b0 and ending at boundary b1 in t), and let r′ be the run
     of t′ that starts at boundary b0 and ends at boundary
     n′ − (n − b1): the file of E in T′ can be read, there is an
     accepted input of that file that is a citation (the edited
     citation) such that the run of the text of the tag line of that
     citation in t′ (term `documents#origin`) starts and ends at
     boundaries of r′, every character of r′ at a place outside that run
     is a space or a tab, and no other tag line of any tag text of that
     file has a place of its origin in r′;
   - when an inline citation gives E, let r be the run in W (starting at
     boundary b0 and ending at boundary b1 in t), and let r′ be the run
     of t′ that starts at boundary b0 and ends at boundary
     n′ − (n − b1): the file of E in T′ can be read, and r′ is the run
     in t′ (term `documents#origin`) of an accepted input of that file
     that is an inline citation (the edited inline citation);
   - when a citation entry or an inline citation gives E, the edited
     citation or edited inline citation in that file gives an edge E′ of
     the same kind of edge as E, whose source is the same item as the
     source of E (or is a site when the source of E is a site), whose
     cited item is the same item as s, and that is pinned with the
     current revision of s in T as its label when E is pinned, and is
     not pinned when E is not pinned;
   - when a citation entry gives E, each edge that a citation gives is
     represented by three properties: its kind of edge; its pinned
     label, or that it is not pinned; and its target, which is its
     cited item (as the same item) when the edge has a cited item that
     is not an external item, and is the entry name of its citation
     entry when its cited item is an external item or when the edge has
     no cited item. Taken by these three properties, the set of edges
     that the edited citation gives in T′ is the set of edges that the
     citation of E gave in T with E replaced by E′;
   - when a vector line gives E, the content of the vector file of E in
     T′ is a test-vector set, and for each vector line L of the group of
     the vector line of E in that vector file in T (on line l of t,
     starting at boundary ls and ending at boundary le, whose edge has
     form run rL starting at boundary b0 and ending at boundary b1), let
     l′ be the line of t′ with the same line number as l (starting at
     boundary ls′ and ending at boundary le′) and let rL′ be the run of
     t′ that starts at boundary ls′ + (b0 − ls) and ends at boundary
     le′ − (le − b1): rL′ is the form run of an edge EL′ that a vector
     line of that vector file gives in T′, and EL′ is of the kind
     `cites`, its source is the same item as the source of E, its cited
     item is the same item as s, and EL′ is pinned with the current
     revision of s in T as its label.

### 5.4 Findings of the class `cycle`

@req give-cycle-findings=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{finding-class=v1, tree=v1, parameter=v1},
    documents#{file-readers=v1, tree-finding=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{historical-paths=v1, cycle-finding=v1},
}

This requirement applies under a valid binding F of `file-readers`, a
binding N of `external-namespaces` for which a conforming program of the
design Identifiers gives the result "valid", and a valid binding H of
`historical-paths`. When a conforming program gives the findings of the
class `cycle` of a tree T under F, N, and H, that program must give each
tree finding of that class that T has under F, N, and H once, and must
give no other finding of that class.

### 5.5 Findings of the class `deleted-decision`

@req give-deleted-decision-findings=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{finding-class=v1, tree=v1, parameter=v1},
    documents#{file-readers=v1, tree-finding=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{deleted-decision-finding=v1},
}

This requirement applies under a valid binding F of `file-readers` and a
binding N of `external-namespaces` for which a conforming program of the
design Identifiers gives the result "valid". When a conforming program
gives the findings of the class `deleted-decision` of a tree T against a
base tree B under F and N, that program must give each tree finding of
that class that T has against B under F and N once, and must give no
other finding of that class.

### 5.6 Findings of the class `reused-label`

@req give-reused-label-findings=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{finding-class=v1, tree=v1, parameter=v1},
    changes#{commit=v1, change-of-a-commit=v1},
    documents#{file-readers=v1, tree-finding=v1},
    text#{conforming-program=v1, result=v1, sequence=v1, code-span=v1},
    #{historical-paths=v1, reused-label-finding=v1},
}

This requirement applies under a valid binding F of `file-readers`, a
binding N of `external-namespaces` for which a conforming program of the
design Identifiers gives the result "valid", and a valid binding H of
`historical-paths`. This requirement does not apply when a conforming
program gives the findings of the class `reused-label` of the change of
a commit. When a conforming program gives the findings of the class
`reused-label` of a tree T against a base tree B and a finite sequence L
of trees under F, N, and H, that program must give each tree finding of
that class that T has against B and L under F, N, and H once, and must
give no other finding of that class.

### 5.7 No finding under a binding of `historical-paths` that is not valid

@req omit-findings-under-invalid-historical-paths=v1
@cites {
    ontology#{finding-class=v1, tree=v1, parameter=v1},
    changes#{commit=v1, change-of-a-commit=v1},
    text#{conforming-program=v1, code-span=v1},
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

### 5.8 Missing ledger objects

@req report-missing-ledger-objects=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        declared-item=v1, finding-class=v1, tree=v1, ledger=v1,
        parameter=v1,
    },
    changes#{
        default-branch-name=v1, repository-read=v1,
        undisturbed-read=v1,
    },
    ledger#{ledger-object=v1},
    documents#{file-readers=v1},
    approval#{approval-kinds=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{historical-paths=v1, successor=v1, retired-finding=v1},
}

This requirement applies for a git repository R that does not hold its
ledger objects, under a valid binding A of `approval-kinds`, a binding D
of `default-branch-name` (whether or not D is a valid binding of
`default-branch-name`), a valid binding F of `file-readers`, and a
binding N of `external-namespaces` for which a conforming program of the
design Identifiers gives the result "valid". When a conforming program
meets two conditions, that program must give that R lacks its ledger
objects, must give no successor of any declared item of any tree
at any point of the ledger of R, must give no finding of the class
`retired` of any tree at any point of the ledger of R, and must not give
that it cannot see the whole history for those successors or those
findings:

1. That program gives the successors of a declared item of a tree at a
   point of the ledger of R under A, D, F, and N, or, under a valid
   binding H of `historical-paths`, gives the findings of the class
   `retired` of a tree at a point of the ledger of R under A, D, F, N,
   and H.
2. Each repository read from which that program reads the ledger of R is
   undisturbed.

### 5.9 When the repository holds its ledger objects

@req omit-missing-ledger-objects-report=v1
@cites {
    ontology#{
        declared-item=v1, finding-class=v1, tree=v1, ledger=v1,
    },
    changes#{repository-read=v1, undisturbed-read=v1},
    ledger#{ledger-object=v1},
    text#{conforming-program=v1, code-span=v1},
    #{successor=v1, retired-finding=v1},
}

This requirement applies for a git repository R that holds its ledger
objects. When a conforming program meets two conditions, that program
must not give that R lacks its ledger objects:

1. That program gives the successors of a declared item of a tree or
   gives the findings of the class `retired` of a tree at a point of the
   ledger of R.
2. Each repository read from which that program reads the ledger of R is
   undisturbed.

### 5.10 Deleted decision records of the change of a commit

@req compare-change-for-deleted-decisions=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{finding-class=v1, tree=v1, parameter=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        change-of-a-commit=v1, change-base=v1, repository-read=v1,
        undisturbed-read=v1,
    },
    documents#{file-readers=v1, tree-finding=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{deleted-decision-finding=v1},
}

This requirement applies for a commit h under three bindings: a valid
binding D of `default-branch-name` under which the change of h has a
base, a valid binding F of `file-readers`, and a binding N of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid". Under these bindings, this
requirement applies when a conforming program meets two conditions.
First, that program gives the findings of the class `deleted-decision`
of the change of h under these bindings. Second, each repository read
from which that program takes the base of the change of h and the files
of the tree of h and of the tree of that base is undisturbed. Under
these bindings and when both conditions hold, that program must give
each tree finding of that class that the tree of h has against the tree
of the base of the change of h under F and N once, and must give no
other finding of that class.

### 5.11 Reused labels of the change of a commit

@req compare-change-for-reused-labels=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        finding-class=v1, default-branch=v1, tree=v1, parameter=v1,
    },
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, change-of-a-commit=v1, change-base=v1,
        first-parent-line=v1, repository-read=v1, undisturbed-read=v1,
    },
    documents#{file-readers=v1, tree-finding=v1},
    text#{conforming-program=v1, result=v1, sequence=v1, code-span=v1},
    #{
        historical-paths=v1, new-label-item=v1, reused-label-finding=v1,
        cut-history=v1,
    },
}

This requirement applies for a commit h of a git repository R under four
bindings: a valid binding D of `default-branch-name` under which the
change of h has a base (so the default branch of R has a commit d under
D), a valid binding F of `file-readers`, a binding N of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", and a valid binding H of
`historical-paths`. Let L be the sequence of the trees of the commits of
the first-parent line of d, in the order of that line.

This requirement applies when a conforming program meets three
conditions. First, that program gives the findings of the class
`reused-label` of the change of h under D, F, N, and H. Second, each
repository read from which that program takes the base of the change of
h, the first-parent line of d, and the files of the trees of h, of that
base, and of the commits of that line is undisturbed. Third, either the
tree of h has no item with a new label against the tree of the base of
the change of h under F, N, and H, or the history of the default branch
of R under D and F is not cut for those repository reads.

When the tree of h has no item with a new label against the tree of the
base of the change of h under F, N, and H, that program must give no
finding of the class `reused-label`. Otherwise, that program must give
each tree finding of the class `reused-label` that the tree of h has
against the tree of the base of the change of h and L under F, N, and H
once, and must give no other finding of that class.

### 5.12 The change of a commit with no base

@req report-missing-base=v1
@cites {
    ontology#{finding-class=v1, parameter=v1},
    changes#{
        commit=v1, default-branch-name=v1, change-of-a-commit=v1,
        change-base=v1, repository-read=v1, undisturbed-read=v1,
    },
    text#{conforming-program=v1, code-span=v1},
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

### 5.13 The change of a commit with a base

@req omit-missing-base-report=v1
@cites {
    ontology#{finding-class=v1, parameter=v1},
    changes#{
        commit=v1, default-branch-name=v1, change-of-a-commit=v1,
        change-base=v1, repository-read=v1, undisturbed-read=v1,
    },
    text#{conforming-program=v1, code-span=v1},
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

### 5.14 Cut histories

@req report-cut-history=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        finding-class=v1, default-branch=v1, tree=v1, parameter=v1,
    },
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, change-of-a-commit=v1, change-base=v1,
        first-parent-line=v1, repository-read=v1, undisturbed-read=v1,
    },
    documents#{file-readers=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{
        historical-paths=v1, new-label-item=v1, reused-label-finding=v1,
        cut-history=v1,
    },
}

This requirement applies for a commit h of a git repository R under four
bindings: a valid binding D of `default-branch-name` under which the
change of h has a base (so the default branch of R has a commit d under
D), a valid binding F of `file-readers`, a binding N of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", and a valid binding H of
`historical-paths`.

This requirement applies when a conforming program meets four
conditions. First, that program gives the findings of the class
`reused-label` of the change of h under D, F, N, and H. Second, each
repository read from which that program takes the base of the change of
h, the first-parent line of d, and the files of the trees of h, of that
base, and of the commits of that line is undisturbed. Third, the tree of
h has at least one item with a new label against the tree of the base of
the change of h under F, N, and H. Fourth, the history of the default
branch of R under D and F is cut for those repository reads. When all
four conditions hold, that program must give that it cannot see the
whole history for the change of h, and must give no finding of the class
`reused-label`.

### 5.15 When no label is new, the default branch is read in full, or reused labels are not given

@req omit-cut-history-report=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        finding-class=v1, default-branch=v1, tree=v1, parameter=v1,
    },
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, change-of-a-commit=v1, change-base=v1,
        first-parent-line=v1, repository-read=v1, undisturbed-read=v1,
    },
    documents#{file-readers=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{
        historical-paths=v1, new-label-item=v1, reused-label-finding=v1,
        cut-history=v1,
    },
}

This requirement applies for a commit h of a git repository R under four
bindings: a valid binding D of `default-branch-name` under which the
change of h has a base (so the default branch of R has a commit d under
D), a valid binding F of `file-readers`, a binding N of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", and a valid binding H of
`historical-paths`.

Under these bindings, when a conforming program meets two conditions,
that program must not give that it cannot see the whole history for the
change of h under D, F, N, and H. First, that program does not give the
findings of the class `reused-label` of the change of h under D, F, N,
and H. Second, each repository read from which that program takes the
base of the change of h is undisturbed.

Under these bindings, when a conforming program meets three conditions,
that program must not give that it cannot see the whole history for the
change of h under D, F, N, and H. First, that program gives the findings
of the class `reused-label` of the change of h under D, F, N, and H.
Second, each repository read from which that program takes the base of
the change of h, the first-parent line of d, and the files of the trees
of h, of that base, and of the commits of that line is undisturbed.
Third, either the tree of h has no item with a new label against the
tree of the base of the change of h under F, N, and H, or the history of
the default branch of R under D and F is not cut for those repository
reads.

## 6. Conformance

A program conforms to this design when it is a
[conforming program](sinter:text#conforming-program=v1) of this design.

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
`report-missing-ledger-objects`, `omit-missing-ledger-objects-report`,
`compare-change-for-deleted-decisions`,
`compare-change-for-reused-labels`, `report-missing-base`,
`omit-missing-base-report`, `report-cut-history`, and
`omit-cut-history-report`.

By the schemas below, each vector checks a program only when the program
reaches no limit of its own and no other process changes the inputs
while the program runs.

### 6.1 Successors

@schema successors-vector=v1
@cites {
    rfc/8259,
    text#{
        conforming-program=v1, text=v1, character=v1, whole-number=v1,
        decimal-numeral=v1, sequence=v1, result=v1, code-span=v1,
    },
    data-forms#{
        index=v1, group-form-list=v1, vector-meaning=v1, json-value=v1,
    },
    identifiers#{
        external-namespaces=v1, validate-bindings=v1,
        citation-entry=v1, citation-line=v1,
    },
    ontology#{
        declared-item=v1, containment=v1, item-name=v1, edge=v1,
        supersedes-edge=v1, effective-supersedes-edge=v1,
        default-branch=v1, tree=v1, ledger=v1, parameter=v1,
    },
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
        repository-read=v1,
    },
    documents#{file-readers=v1},
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    approval#{
        approval-kinds=v1, bound-in-force-item=v1,
        incomplete-first-parent-line=v1,
    },
    #{successor=v1, give-successors=v1},
}

The group `successors` holds the vectors of the requirement
`give-successors`. Each vector gives the declared items of a tree (with
their kinds, the items of the kind design that hold them, and whether
each is in force), the `supersedes` edges of the tree (with whether each
edge is effective and whether `every-part` matches its citation entry),
and one declared item of that tree. The vector gives the successors of
that declared item in the tree at a point of a ledger. The group uses no
need, so these forms give no need names.

The input of each vector stands for a valid ledger of a git repository
that holds its ledger objects and whose default branch's first-parent
line (when the default branch has a commit) is not incomplete (term
`approval#incomplete-first-parent-line`) for the repository reads from
which a conforming program takes that first-parent line and the files of
the trees of the commits of that first-parent line; for valid bindings
of `approval-kinds`, `default-branch-name`, and `file-readers`; and for
a binding of `external-namespaces` for which a conforming program of
Identifiers gives the result "valid". Each vector checks a conforming
program only when the program reaches no limit of its own and no other
process changes these inputs while the program runs.

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
    tree at the point under the bindings, and `false` when it is
    retired), and, when an item of the kind design holds the item,
    `design` (the name of that item of the kind design).
  - `edges`: the `supersedes` edges of the tree that say what
    `supersedes` says in the tree, as a sequence. Each element is a JSON
    object with `source` (the 1-based index of the source in `items`),
    `cited` (the 1-based index of the cited item in `items`),
    `effective` (`true` when the edge is effective in the tree at the
    point under the bindings, and `false` otherwise), and `every-part`
    (`true` when `every-part` matches the citation entry of the edge,
    and `false` otherwise).
  - `target`: the 1-based index in `items` of the declared item whose
    successors are asked.
- `result`: no vector of the group has this member; these forms name no
  question for `result`.
- `values`: a JSON object with one member, `successors`: a JSON array of
  the 1-based indexes in `items` of the successors of `target`, each
  once, in increasing numerical order.

When a conforming program gives the successors of `target` in the tree
at the point under the bindings, that program gives the declared item at
each index in `successors` once and gives no other item.

### 6.2 Findings of the class `retired`

@schema retired-vector=v1
@cites {
    rfc/8259,
    text#{
        conforming-program=v1, text=v1, character=v1,
        code-point-order=v1, sequence=v1, result=v1, code-span=v1,
    },
    files#{path=v1, path-set=v1, valid-path-set=v1},
    data-forms#{group-form-list=v1, vector-meaning=v1, json-value=v1},
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        declared-item=v1, edge=v1, vector-set=v1,
        conformance-vector-group=v1, external-item=v1,
        default-branch=v1, tree=v1, ledger=v1, finding-class=v1,
        parameter=v1,
    },
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
        repository-read=v1,
    },
    documents#{
        file-readers=v1, tree-edge=v1, position-subject=v1,
        tree-finding=v1,
    },
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    approval#{
        approval-kinds=v1, bound-in-force-item=v1,
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
and cited-item states and file paths of those edges. The vector gives
the subjects of the `retired` findings of the tree, or `{}` when the
binding of `historical-paths` is not valid. The group uses no need, so
these forms give no need names.

The input of each vector stands for a valid ledger of a git repository
that holds its ledger objects and whose default branch's first-parent
line (when the default branch has a commit) is not incomplete (term
`approval#incomplete-first-parent-line`) for the repository reads from
which a conforming program takes that first-parent line and the files of
the trees of the commits of that first-parent line; for valid bindings
of `approval-kinds`, `default-branch-name`, and `file-readers`; and for
a binding of `external-namespaces` for which a conforming program of
Identifiers gives the result "valid". Each vector checks a conforming
program only when the program reaches no limit of its own and no other
process changes these inputs while the program runs.

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
    declared item, or the item of the kind design or of the kind
    specification of that group's vector set, is in force in the tree at
    the point under the bindings, and `false` otherwise), `cited-kind`
    (`"declared"` when the cited item is a declared item, `"group"` when
    the cited item is a group of conformance vectors, `"vector-set"`
    when the cited item is a vector set, and `"external"` when the cited
    item is an external item or when the edge has no cited item),
    `cited-in-force` (present when `cited-kind` is `"declared"`,
    `"group"`, or `"vector-set"`: `true` when that declared item, or the
    item of the kind design or of the kind specification of the vector
    set (for `"group"`, the vector set of that group), is in force in
    the tree at the point under the bindings, and `false` otherwise),
    `path` (the valid path of the file of the edge), and `at` (the
    position subject of the edge).
- `result`: no vector of the group has this member; these forms name no
  question for `result`.
- `values`: `{}` when `historical-paths` is not a valid path set;
  otherwise, a JSON object with one member, `findings`, a JSON array of
  the subjects (`at`) of the `retired` tree findings of the tree, each
  once, in code point order.

When `values` is `{}`, a conforming program gives no finding of the
class `retired` for the tree. When `values` is not `{}` and a conforming
program gives the findings of the class `retired` of the tree at the
point under the bindings, that program gives one finding of that class
with each subject in `findings` and gives no other finding of that
class.

### 6.3 Offered fixes of `retired` findings

@schema retired-fix-vector=v1
@cites {
    rfc/8259,
    text#{
        conforming-program=v1, text=v1, character=v1, whole-number=v1,
        decimal-numeral=v1, boundary=v1, run=v1, code-point-order=v1,
        sequence=v1, result=v1, code-span=v1,
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
        item-revision=v1, edge=v1, pinned-edge=v1, tree=v1, ledger=v1,
        parameter=v1,
    },
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
        repository-read=v1,
    },
    findings#{fix=v1, edit=v1, edit-set=v1, spot=v1},
    documents#{
        file-readers=v1, tree-edge=v1, origin=v1, named-item=v1,
        tree-finding=v1,
    },
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    approval#{approval-kinds=v1, incomplete-first-parent-line=v1},
    #{
        historical-paths=v1, successor=v1, retired-finding=v1,
        limit-retired-fix-edit-sets=v1,
    },
}

The group `retired-fixes` holds the vectors of the requirement
`limit-retired-fix-edit-sets`. Each vector gives the file text of a
`retired` finding whose cited item has one or more successors, the edge
and run of that finding, and the successors of its cited item. The
vector gives whether a fix that meets `limit-retired-fix-edit-sets`
exists and, when one does, the ordered edit-set obligations that any
offered fix meets. The group uses no need, so these forms give no need
names.

The input of each vector stands for a valid ledger of a git repository
that holds its ledger objects and whose default branch's first-parent
line (when the default branch has a commit) is not incomplete (term
`approval#incomplete-first-parent-line`) for the repository reads from
which a conforming program takes that first-parent line and the files of
the trees of the commits of that first-parent line; for valid bindings
of `approval-kinds`, `default-branch-name`, `file-readers`, and
`historical-paths` (under which the file of the edge is not historical);
and for a binding of `external-namespaces` for which a conforming
program of Identifiers gives the result "valid". Each vector checks a
conforming program only when the program reaches no limit of its own and
no other process changes these inputs while the program runs.

The JSON values, objects, arrays, strings, numbers, and the literal
names `true` and `false` of this schema are as RFC 8259 defines them.
Inside `input` and `values`, a text is a JSON string whose characters
are the characters of the text in order, a boundary is a JSON number
written as its decimal numeral, and a sequence is a JSON array of its
elements in order.

- `input`: a JSON object with these members:
  - `path`: the valid path of the file of the edge `E`.
  - `text`: the text of that file in the tree.
  - `origin-kind`: one of `"citation-entry"`, `"inline-citation"`, and
    `"vector-line"`.
  - `edge-kind`: one of `"cites"`, `"satisfies"`, `"verifies"`, and
    `"refines"`.
  - `pinned`: `true` when `E` is pinned, and `false` when `E` is not
    pinned.
  - `run`: a JSON object with `from` and `to`, the start and end
    boundaries in `text` of the run of the text of the tag line of the
    citation of `E` in the text of that file (term `documents#origin`;
    for `"citation-entry"`), of the inline citation (for
    `"inline-citation"`), or of the form run (for `"vector-line"`).
  - `cited`: the name of the retired cited item of `E`.
  - `successors`: a JSON array of one or more JSON objects, one for each
    successor of `cited`, each with `name` (the name of the successor),
    `kind` (one of `"design"`, `"spec"`, `"schema"`, `"req"`, `"atom"`,
    `"term"`, and `"decision"`), `duplicate` (`true` when two or more
    items share its name in its set of names so no citation names it,
    and `false` otherwise), optional `label` (its current revision,
    omitted when it is a term with no label), and, when `origin-kind` is
    `"vector-line"`, `in-vector-owner` (when the vector set is of an
    item of the kind design D, `true` when the successor is a schema
    that D holds directly and `false` otherwise; when the vector set is
    of an item of the kind specification S, `true` when the successor is
    a schema that S holds and `false` otherwise).
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
    text#{
        conforming-program=v1, text=v1, character=v1, whole-number=v1,
        decimal-numeral=v1, position=v1, code-point-order=v1,
        sequence=v1, result=v1, code-span=v1,
    },
    files#{path=v1, path-set=v1, valid-path-set=v1},
    data-forms#{
        index=v1, group-form-list=v1, vector-meaning=v1, json-value=v1,
    },
    identifiers#{
        external-namespaces=v1, validate-bindings=v1, citation-entry=v1,
        citation-line=v1, declaration=v1, tag-line-text=v1,
    },
    ontology#{
        declared-item=v1, containment=v1, item-name=v1, edge=v1,
        supersedes-edge=v1, refines-edge=v1, tree=v1, finding-class=v1,
        parameter=v1,
    },
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
kinds, the items of the kind design that hold them, file paths, and
declaration origin positions), and the `supersedes` and `refines` edges
of the tree. The vector gives
the `cycle` findings of the tree by subject and declaration origin
position, or `{}` when the binding of `historical-paths` is not valid.
The group uses no need, so these forms give no need names.

The input of each vector stands for a valid binding of `file-readers`
and a binding of `external-namespaces` for which a conforming program of
Identifiers gives the result "valid". Each vector checks a conforming
program only when the program reaches no limit of its own and no other
process changes these inputs while the program runs.

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
    `"decision"`), `path` (the valid path of the file of the item),
    `line` (the line number of the origin position of the text of the
    tag line of the declaration of the item), `column` (the column of
    that origin position), and, when an item of the kind design holds
    the item, `design` (the name of that item of the kind design).
  - `edges`: the `supersedes` and `refines` edges of the tree, as a
    sequence. Each element is a JSON object with `kind` (`"supersedes"`
    or `"refines"`), `fits` (`true` when the edge says what its kind of
    edge says in the tree, and `false` otherwise), `source` (the 1-based
    index of the source in `items`), `cited` (the 1-based index of the
    cited item in `items`), and, for a `supersedes` edge, `every-part`
    (`true` when `every-part` matches its citation entry, and `false`
    otherwise).
- `result`: no vector of the group has this member; these forms name no
  question for `result`.
- `values`: `{}` when `historical-paths` is not a valid path set;
  otherwise, a JSON object with one member, `findings`, a JSON array
  with one element for each `cycle` tree finding of the tree, in code
  point order of `subject`. Each element is a JSON object with `subject`
  (the subject of the finding), `path` (the valid path of the spot of
  the finding), `line` (the line number of the start of the spot of the
  finding), and `column` (the column of the start of the spot of the
  finding).

When `values` is `{}`, a conforming program gives no finding of the
class `cycle` for the tree. When `values` is not `{}` and a conforming
program gives the findings of the class `cycle` of the tree under the
bindings, that program gives one finding of that class for each element
of `findings`, with the subject that the element states, and gives no
other finding of that class; when that program gives the spot of such a
finding, the spot has the valid path and start position that the element
states.

### 6.5 Findings of the class `deleted-decision`

@schema deleted-decisions-vector=v1
@cites {
    rfc/8259,
    text#{
        conforming-program=v1, text=v1, character=v1,
        code-point-order=v1, sequence=v1, result=v1, code-span=v1,
    },
    files#{path-set=v1, valid-path-set=v1},
    data-forms#{group-form-list=v1, vector-meaning=v1, json-value=v1},
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        declared-item=v1, decision-record=v1, item-name=v1, tree=v1,
        finding-class=v1, parameter=v1,
    },
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

The input of each vector stands for a valid binding of `file-readers`
and a binding of `external-namespaces` for which a conforming program of
Identifiers gives the result "valid". Each vector checks a conforming
program only when the program reaches no limit of its own and no other
process changes these inputs while the program runs.

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
  `"design:"` followed by the name of the item of the kind design for
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
    text#{
        conforming-program=v1, text=v1, character=v1,
        code-point-order=v1, sequence=v1, result=v1, code-span=v1,
    },
    files#{path=v1, path-set=v1, valid-path-set=v1},
    data-forms#{
        group-form-list=v1, vector-meaning=v1, json-value=v1,
        hash-form=v1,
    },
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        declared-item=v1, item-name=v1, item-revision=v1, tree=v1,
        finding-class=v1, parameter=v1,
    },
    documents#{
        file-readers=v1, name-set=v1, extent-hash=v1, item-file=v1,
        tree-finding=v1,
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

The input of each vector stands for a valid binding of `file-readers`
and a binding of `external-namespaces` for which a conforming program of
Identifiers gives the result "valid". Each vector checks a conforming
program only when the program reaches no limit of its own and no other
process changes these inputs while the program runs.

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
  and `"decision"`), `hash` (the extent hash of the item, a text that
  fits the hash form), `path` (the valid path of the file of the item),
  optional `label` (the current revision of the item, omitted when it is
  a term with no label), and, when the item is in a set of names, `set`
  (`"shared"` for the shared set, or `"design:"` followed by the name of
  the item of the kind design for the set of that design).
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
