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
items that cite that declared item can still name it, and effective
`supersedes` edges can point to in-force items that replace it. A
conforming program finds those successors, reports edges to retired
items, reports cycles of `supersedes` and `refines` edges, reports
decision records that a change deletes, and reports items that reuse a
label from the history of the default branch for other content. A
repository can also name historical paths so that historical files keep
their citations without giving findings of these classes.

From Text and notation (`text`), the design takes texts, characters,
spaces, tabs, line feeds, whole numbers, decimal numerals, boundaries,
runs, spans, positions, code point order, code spans, sequences, byte
sequences, UTF-8 encodings, and what a conforming program, an input, and
a result are. From Identifiers (`identifiers`), it takes declarations,
citations, citation lines with the production `every-part`, citation
entries, inline citations, tag line texts, the parameter
`external-namespaces` with its bindings, and the results that a
conforming program of Identifiers gives. From Files and paths (`files`),
it takes valid paths, path sets, valid path sets, and membership in the
set of a path set. From Data forms (`data-forms`), it takes JSON values,
indexes, hash forms, vector lines, test-vector sets, the forms of a
group, and the meaning of a vector. The file that holds the conformance
vectors of the design is a test-vector set. From RFC 8259, the design
takes JSON values, with their objects, members, arrays, strings,
numbers, and the literal names `true` and `false`.

From the Ontology (`ontology`), the design takes trees, declared items
and their kinds, decision records, containment, names, current
revisions, revised contents, same items across trees, vector sets,
groups of conformance vectors, external items, edges of all five kinds
and when an edge says what its kind of edge says, pinned edges,
effective `supersedes` edges, cycles of `supersedes` edges, retired
items, items in force, the default branch, the ledger, finding classes,
and parameters. From Changes (`changes`), it takes commits, the files of
the tree of a commit, shallow commits, the parameter
`default-branch-name` with its bindings, the commit of the default
branch, the change of a commit, the base of the change of a commit,
first-parent lines, repository reads, and undisturbed repository reads.
From Findings (`findings`), it takes spots, edits, edit sets, edited
trees, fixes, corrections, finding parts, same findings, and the
requirement `findings#limit-fix-edit-sets`.

From Documents (`documents`), the design takes the parameter
`file-readers` with its bindings, readers of valid paths, read files,
sets of stopped files, files of declared items, origins, origin
positions, extent hashes, vector files, the edges of a tree with their
form runs and form positions, position subjects, the order of positions,
the spots of runs, and tree findings. From Revisions (`revisions`), it
takes base items. From the Ledger (`ledger`), it takes stored ledgers,
ledger objects, and valid, broken, and newer ledgers. From Approval
(`approval`), it takes the parameter `approval-kinds` with its bindings
and in force under the bindings.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [tree](sinter:ontology#tree=v1) | a set of files, each a valid path with a content, such as the tree of a commit or the tree of a working tree |
| base tree | the earlier tree with which a conforming program compares a tree, such as the tree of the base of the change of a commit |
| [set of stopped files](sinter:documents#unreadable-file=v1) | a set of files of a tree that a program takes as an input of its own: the markdown files whose reading it stops for limits of its own, the code files for whose reading it gives the result "parse failure" for limits of its own, and the files of the tree whose content it stops reading as a test-vector set for limits of its own |
| [binding of `historical-paths`](sinter:#historical-paths=v1) | a path set; the files whose valid paths are in its set are the historical files |
| [historical file](sinter:#historical-file=v1) | a file of a tree whose valid path is in the set of a valid binding of `historical-paths` |
| [retired](sinter:ontology#retired-item=v1), [in force](sinter:ontology#in-force-item=v1) | a declared item is retired in a tree at a point of a ledger when it is deprecated, when it is the cited item of an effective `supersedes` edge and is on no cycle of `supersedes` edges, or when it belongs to a retired design or specification; a declared item is in force when it is not retired |
| [in force under the bindings](sinter:approval#bound-in-force-item=v1) | in force as the atom `ontology#in-force-item` gives it, under the bindings of `approval-kinds`, `default-branch-name`, `file-readers`, and `external-namespaces` and the sets of stopped files of the trees that it reads |
| [effective `supersedes` edge](sinter:ontology#effective-supersedes-edge=v1) | a `supersedes` edge that says what `supersedes` says, whose source and every item that holds its source are not deprecated, and whose source is approved |
| [direct replacement](sinter:#successor=v1) | a declared item y directly replaces a declared item x when an effective `supersedes` edge has y as its source and x as its cited item, or matches `every-part` and replaces x by y by part name |
| [successor](sinter:#successor=v1) | a declared item in force that replaces a retired declared item through one or more direct replacements, with every intermediate item retired |
| [cycle of `supersedes` and `refines` edges](sinter:#edge-cycle=v1) | a maximal non-empty set of declared items of a tree in which each member reaches each member (itself included) along one or more `supersedes` edges (including `every-part` part replacements, effective or not) and `refines` edges that say what their kind of edge says |
| [declaration order](sinter:#cycle-finding=v1) | the order of declared items of a tree by the valid path of each item's file in code point order, and then by the origin position of the text of the tag line of each item's declaration in the order of positions |
| [anchor member](sinter:#cycle-finding=v1) | among the members of a cycle of `supersedes` and `refines` edges whose name comes first in code point order, the member that comes first in declaration order |
| [base item](sinter:revisions#base-item=v1) | the one declared item of a base tree with the same name in the corresponding set of names, of any kind, when the declared item of the tree is also the one declared item with its name in its set of names |
| [item with a new label](sinter:#new-label-item=v1) | a declared item of a tree that has a current revision, whose file is not a historical file, and that either has no base item in the base tree or whose base item has no current revision or a different current revision |
| [cut history](sinter:#cut-history=v1) | a first-parent line of the commit of the default branch that cannot be read in full because a commit on the line is a shallow commit, a needed git object is missing from the repository and not fetched, or a read file of a tree on the line is in that tree's set of stopped files |
| [tree finding](sinter:documents#tree-finding=v1) | a finding of one tree, with a class, a subject, and either a spot or no spot, that is not ackable |
| [`retired`](sinter:#retired-finding=v1) | the finding class of `cites`, `satisfies`, `verifies`, and `refines` edges whose source counts, whose cited item counts as retired, and whose file is not a historical file |
| [`cycle`](sinter:#cycle-finding=v1) | the finding class of cycles of `supersedes` and `refines` edges whose anchor member is not in a historical file |
| [`deleted-decision`](sinter:#deleted-decision-finding=v1) | the finding class of decision records of a base tree that are the base item of no declared item of a tree |
| [`reused-label`](sinter:#reused-label-finding=v1) | the finding class of items with a new label whose label already appeared on the first-parent line of the default branch for a different kind or a different extent hash |

## 2. Retirement, cycles, and guarantees over time

### 2.1 Historical paths and historical files

A repository can bind the parameter `historical-paths` to a valid path
set (schema `historical-paths`). The empty path set is a valid binding
under which no file of any tree is historical. A file of a tree is a
historical file when its valid path is in the set of that binding (term
`historical-file`), whatever reads that file: a markdown file, a code
file, a vector file, or a file with no reader.

A historical file is still read as Documents specifies. Its declared
items still exist, and its citations still give edges. For example, when
`docs/devlog.md` is a historical file and holds `@cites d1=v1` where
`d2` supersedes `d1`, the edge still exists, and the tree has no
`retired` finding for that edge because its spot lies in a historical
file.

### 2.2 Successors of a retired item

A retired declared item can have zero, one, or several successors (term
`successor`). Only a retired declared item can have a successor. A
declared item that is in force has no successor, and an item that is not
a declared item, such as a group of conformance vectors or a vector set,
has no successor.

Each direct replacement follows an effective `supersedes` edge or one of
its `every-part` part replacements, and a chain of direct replacements
to a successor ends at a declared item that is in force. These examples
show how the rule works when every item is approved and no item carries
`@deprecated` unless stated:

1. **A chain.** Decision record `d2` has `@supersedes d1=v1`, and `d3`
   has `@supersedes d2=v1`. Both `d1` and `d2` are retired, and `d3` is
   in force. The only successor of `d1` is `d3`, and the only successor
   of `d2` is `d3`.
2. **A fork.** Both `d2` and `d3` have `@supersedes d1=v1`, and both are
   in force. The successors of `d1` are `d2` and `d3`.
3. **A diamond.** `d2` and `d3` both supersede `d1`, and `d4` supersedes
   both `d2` and `d3`. The only successor of `d1` is `d4`, given once.
4. **Every-part supersession and the cascade.** Design `billing-2` has
   `@supersedes billing=v1#*`. Design `billing` holds `billing#limit`
   and `billing#legacy`. Design `billing-2` holds `billing-2#limit` and
   no part named `legacy`. Both `billing#limit` and `billing#legacy` are
   retired by the cascade. The only successor of `billing#limit` is
   `billing-2#limit`. Because `billing-2` holds no part named `legacy`,
   `billing#legacy` has no successor.
5. **Deprecation.** Decision record `d1` carries `@deprecated`, and no
   effective `supersedes` edge cites `d1`. Then `d1` is retired and has
   no successor. When `d3` has `@supersedes d2=v1` and `d3` carries
   `@deprecated`, the edge from `d3` is not effective, so `d2` is in
   force and has no successor.
6. **A cycle inside a retired design.** Design `old` is superseded by
   `new`, so `old#p` and `old#q` are retired by the cascade. Inside
   `old`, `old#p` has `@supersedes old#q=v1` and `old#q` has
   `@supersedes old#p=v1`. Both edges stay effective because neither
   source nor `old` is deprecated. No chain of direct replacements from
   `old#p` or `old#q` reaches an item in force, so neither `old#p` nor
   `old#q` has a successor. If `new#q` also has an effective
   `@supersedes old#q=v1` and is in force, the only successor of both
   `old#p` and `old#q` is `new#q`.
7. **An edge into an in-force cycle.** Items `y` and `z` supersede each
   other and are neither deprecated nor in a retired design, so both `y`
   and `z` are in force. Item `y` also has an effective
   `@supersedes x=v1`, so `x` is retired. Because every intermediate
   item on a chain of direct replacements to a successor is retired, the
   only successor of `x` is `y`, and not `z`.

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
- a vector line in `billing.test-vectors.jsonl`, because the owning
  design `billing` is retired;
- a `@cites` edge to an external item such as `rfc/8259`, because an
  external item never counts as retired;
- an edge that does not say what its kind of edge says, such as
  `@satisfies d1=v1` to a retired decision record.

No requirement obliges a conforming program to offer a fix for a
`retired` finding. When a program does offer a fix for a `retired`
finding whose cited item has successors, the requirement
`limit-retired-fix-edit-sets` fixes its edit sets. For example, when
`docs/guide.md` holds `@cites billing#{limit=v1, window=v1}`,
`billing#limit` has the single successor `billing-2#limit` at `v1`, and
`billing#window` is in force, the offered fix has one edit set. That
edit set edits only that tag line so that it cites `billing-2#limit=v1`
and `billing#window=v1`, for example
`@cites {billing-2#limit=v1, billing#window=v1}`. When a citation has
two successors `d3` and `d4`, the fix has two edit sets, first for `d3`
and then for `d4`, in code point order of their names. When the original
edge is unpinned (`@cites billing#limit=*`), the replacement edge stays
unpinned (`@cites billing-2#limit=*`). When the cited item has no
successor (for example a `@deprecated` record or a retired vector
group), `limit-retired-fix-edit-sets` adds no condition beyond
`findings#limit-fix-edit-sets`.

In three cases, a successor of a retired item cannot be named by an edit
of the citation, so no edit set meets `limit-retired-fix-edit-sets` for
that successor, and a conforming program offers no fix for that finding:

1. **An unwritable form pin.** A vector line in
   `billing.test-vectors.jsonl` has `"form":"#row=v1"`, and schema
   `billing-2#row` (in another design) or `billing#spec-row` (in a
   specification of `billing` while the vector set is of `billing`
   itself) supersedes `billing#row`. By `ontology#edge`, a form pin in
   `billing.test-vectors.jsonl` can name only a schema that `billing`
   holds directly, so no edit of the form pin can cite that successor.
2. **A pinned citation to a term with no label.** Design `billing-2` has
   `@supersedes billing=v1#*` and declares `@term rate` with no label,
   while `docs/guide.md` holds `@cites billing#rate=v1`. Because
   `billing-2#rate` has no current revision, no edit can write its
   current revision in place of the pin.
3. **A successor with a duplicate name.** Two items in the same set of
   names share the name `d2`, and one or both supersede `d1`. Because a
   duplicated name names none of those items (`documents#named-item`),
   no edit of the citation can cite that successor.

The same consequence holds when a retired item has two successors and
only one of them fails one of these conditions: because a fix that meets
`limit-retired-fix-edit-sets` has one edit set for each successor, a
conforming program offers no fix for that finding.

### 2.4 Findings of the class `cycle`

The term `edge-cycle` defines a cycle of `supersedes` and `refines`
edges in a tree, and the atom `cycle-finding` gives the findings of the
class `cycle`. A `supersedes` edge counts in a cycle whether or not it
is effective, and an `every-part` `supersedes` edge contributes each of
its part replacements. An edge that does not say what its kind of edge
says takes no part in a cycle. Two declared items belong to one cycle
when each reaches the other along these steps, and a declared item with
a step to itself is a cycle by itself.

For example, each of these gives one `cycle` finding when its anchor
member is not in a historical file:

- `d1` has `@supersedes d2=v1` and `d2` has `@supersedes d1=v1` (subject
  `d1`);
- requirement `r` has `@supersedes r=v1` (subject `r`);
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
chooses the spot.

### 2.5 Deleted decision records

The atom `deleted-decision-finding` compares a tree against a base tree
and reports each decision record of the base tree that is the base item
of no declared item of the tree (term `revisions#base-item`).

For example, when a change deletes the file of `@decision rust-bridge=v1`,
or renames `@decision parser-bridge=v1` to `@decision wasm-bridge=v1`,
the tree has one `deleted-decision` finding (`rust-bridge` or
`parser-bridge`). Moving the file of a decision record to another folder
with the same name keeps its base item and gives no finding. Changing
`@decision x=v1` to `@req x=v1` in the shared set keeps `x` as the base
item of that requirement and gives no `deleted-decision` finding.

A `deleted-decision` finding has no spot, because the deleted record is
no longer in the tree. Therefore, no binding of `historical-paths`
removes a `deleted-decision` finding. For the change of a commit, the
base tree is the tree of the base of the change; when the change has no
base, a conforming program gives that the change has no base and gives
no `deleted-decision` finding.

### 2.6 Reused labels

The term `new-label-item` selects the declared items of a tree that the
atom `reused-label-finding` compares. That atom compares each such item
against a sequence of earlier trees by `revisions#base-item`. For the
change of a commit, that sequence is the trees of the commits of the
first-parent line of the commit of the default branch.

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

When the change of a commit has no base, a conforming program gives that
the change has no base and gives no `reused-label` finding. When the
change has a base and has no item with a new label, the program needs no
history and gives no `reused-label` finding, even in a shallow clone.
When the change has a base and has at least one item with a new label,
and the history of the default branch is cut (term `cut-history`) or the
program stops reading the first-parent line for limits of its own, the
program gives that it cannot see the whole history and gives no
`reused-label` finding.

### 2.7 Bindings, ledgers, concurrent changes, and program limits

All trees compared in one check are read under one binding of each
parameter. Under a binding of `file-readers` or `external-namespaces`
that is not valid, a conforming program gives no successors and no
findings of Standing's classes (requirement
`omit-results-under-invalid-reading-bindings`). Under a binding of
`historical-paths` that is not valid, a conforming program gives no
findings of Standing's classes (requirement
`omit-findings-under-invalid-historical-paths`), while successors do not
depend on `historical-paths`. Under a binding of `default-branch-name`
that is not a branch name, the default branch has no commit
(`changes#default-branch-commit`), so the change of a commit has no
base.

Successors and the class `retired` read in force under the bindings,
which reads the ledger. When the ledger of a git repository is broken or
newer, or when the git repository does not hold its ledger objects, a
conforming program gives no successors and no `retired` findings
(requirement `omit-results-from-invalid-ledgers`). When a git repository
lacks git objects that a tree of the first-parent line needs for
`approval#bound-in-force-item`, a conforming program gives the
successors or `retired` findings, or gives none. The classes `cycle`,
`deleted-decision`, and `reused-label` read no ledger.

A conforming program that refuses a graph of edges of a tree for limits
of its own gives no successors and no `retired` or `cycle` findings for
that tree. A conforming program that stops reading the first-parent line
for limits of its own, or puts a read file of a tree of that line in the
set of stopped files of that tree, gives that it cannot see the whole
history and no `reused-label` finding when at least one item with a new
label exists.

What a program gives while another process changes a file, a ref, or the
ledger is a matter of the quality of an implementation.

### 2.8 Findings

Each finding of Standing's four classes is a
[tree finding](sinter:documents#tree-finding=v1). No finding of any of
these classes is ackable.

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
    documents#{file-readers=v1, tree-edge=v1, unreadable-file=v1},
    approval#{approval-kinds=v1, bound-in-force-item=v1},
    text#{sequence=v1, code-span=v1},
}

This term is for a git repository R, a valid binding A of
`approval-kinds`, a binding D of `default-branch-name`, a valid binding
F of `file-readers`, a binding N of `external-namespaces`, a tree T, a
point P of the ledger of R, and a set of stopped files of each tree that
it reads: a set U of stopped files of T and, when the default branch of
R has a commit under D, a set of stopped files of the tree of each
commit of the first-parent line of that commit. Let S stand for these
sets of stopped files.

In this term, a declared item of T is in force in T at P under A, D, F,
N, and S when it is in force in T at P under A, D, F, N, and S (term
`approval#bound-in-force-item`), and is retired in T at P under A, D, F,
N, and S when it is not in force there. In this term, a `supersedes`
edge of T under F, N, and U is effective in T at P under A, D, F, N, and
S when that edge is effective in T at P (atom
`ontology#effective-supersedes-edge`) as the term
`approval#bound-in-force-item` reads status tags, edges, and the state
approved under A, D, F, N, and S.

A declared item y of T directly replaces a declared item x of T in T at
P under A, D, F, N, and S when, and only when, some `supersedes` edge of
T under F, N, and U is effective in T at P under A, D, F, N, and S and
says that y is to replace x: either y is the source and x is the cited
item of that edge, or the production `every-part` matches the citation
entry of that edge and that edge says that x is to be replaced by y.

For a declared item x of T that is retired in T at P under A, D, F, N,
and S, a declared item s of T is a successor of x in T at P under A, D,
F, N, and S when, and only when, both of these conditions hold:

1. s is in force in T at P under A, D, F, N, and S.
2. There is a finite sequence of one or more pairs (u, v) of declared
   items of T that meets all three of these conditions:
   - the first item of the first pair is x, and the second item of the
     last pair is s;
   - for each pair (u, v) of the sequence, v directly replaces u in T at
     P under A, D, F, N, and S;
   - for each pair before the last, its second item is the first item of
     the next pair, and that item is retired in T at P under A, D, F, N,
     and S.

A declared item of T that is in force in T at P under A, D, F, N, and S
has no successor. An item of T that is not a declared item, such as a
group of conformance vectors or a vector set, has no successor.

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
        conformance-vector-group=v1, external-item=v1,
        default-branch=v1, tree=v1, ledger=v1, parameter=v1,
    },
    changes#{
        commit=v1, default-branch-name=v1, default-branch-commit=v1,
        first-parent-line=v1,
    },
    ledger#{stored-ledger=v1},
    documents#{
        file-readers=v1, tree-edge=v1, origin=v1, origin-position=v1,
        position-subject=v1, run-spot=v1, tree-finding=v1,
        unreadable-file=v1,
    },
    approval#{approval-kinds=v1, bound-in-force-item=v1},
    text#{code-span=v1},
    #{historical-paths=v1, historical-file=v1},
}

This atom is for a git repository R, a valid binding A of
`approval-kinds`, a binding D of `default-branch-name`, a valid binding
F of `file-readers`, a binding N of `external-namespaces`, a valid
binding H of `historical-paths`, a point P of the ledger of R, a tree T,
and sets S of stopped files: a set U of stopped files of T and, when the
default branch of R has a commit under D, a set of stopped files of the
tree of each commit of the first-parent line of that commit.

A source of an edge of T under F, N, and U counts in T at P under A, D,
F, N, and S when, and only when, one of these three conditions holds:

1. The source is a declared item of T that is in force in T at P under
   A, D, F, N, and S (term `approval#bound-in-force-item`).
2. The source is a group of conformance vectors of a vector set of T,
   and the item of the kind design or of the kind specification of that
   vector set is in force in T at P under A, D, F, N, and S (term
   `approval#bound-in-force-item`).
3. The source is neither a declared item nor a group of conformance
   vectors.

A cited item of an edge of T under F, N, and U counts as retired in T at
P under A, D, F, N, and S when, and only when, one of these two
conditions holds:

1. The cited item is a declared item of T that is not in force in T at P
   under A, D, F, N, and S (term `approval#bound-in-force-item`).
2. The cited item is a group of conformance vectors or a vector set of
   T, and the item of the kind design or of the kind specification of
   that vector set is not in force in T at P under A, D, F, N, and S
   (term `approval#bound-in-force-item`).

An external item never counts as retired.

At P under A, D, F, N, H, and S, T has one tree finding of the class
`retired` for each edge e that T has under F, N, and U that meets all
four of these conditions:

1. e is of the kind `cites`, `satisfies`, `verifies`, or `refines`, and
   e says what its kind of edge says in T.
2. The source of e counts in T at P under A, D, F, N, and S.
3. The cited item of e counts as retired in T at P under A, D, F, N, and
   S.
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
    documents#{file-readers=v1, tree-edge=v1, unreadable-file=v1},
    text#{sequence=v1, code-span=v1},
}

This term is for a tree T, a valid binding F of `file-readers`, a
binding N of `external-namespaces`, and a set U of stopped files of T.
In T under F, N, and U, a pair (x, y) of declared items of T is a cycle
step when, and only when, either of these two conditions holds:

- some `supersedes` edge of T under F, N, and U says what the kind of
  edge `supersedes` says in T and says that x is to replace y (either
  because x is the source and y is the cited item of that edge, or
  because the production `every-part` matches the citation entry of that
  edge and that edge says that y is to be replaced by x);
- some `refines` edge of T under F, N, and U says what the kind of edge
  `refines` says in T, and x is the source and y is the cited item of
  that edge.

A declared item a of T reaches a declared item b of T along cycle steps
in T under F, N, and U when, and only when, there is a finite sequence
of one or more cycle steps of T whose first pair has a as its first
item, whose last pair has b as its second item, and in which, for each
pair before the last, its second item is the first item of the next
pair.

A cycle of `supersedes` and `refines` edges in T under F, N, and U is a
non-empty set C of declared items of T that meets both of these
conditions:

1. For each declared item a in C and each declared item b in C
   (including when a and b are the same declared item), a reaches b
   along cycle steps in T under F, N, and U.
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
        unreadable-file=v1,
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
`external-namespaces`, a valid binding H of `historical-paths`, and a
set U of stopped files of T, the anchor member of a cycle C of
`supersedes` and `refines` edges in T under F, N, and U is this: among
the declared items of C whose name in T comes first in code point order
among the names in T of all declared items of C, the declared item that
comes first in declaration order.

Under F, N, H, and U, T has one tree finding of the class `cycle` for
each text s that is the name in T of the anchor member of at least one
cycle of `supersedes` and `refines` edges in T under F, N, and U whose
anchor member has a file in T that is not a historical file of T under
H. The subject of that tree finding is s. Among all anchor members of
cycles of `supersedes` and `refines` edges in T under F, N, and U whose
name in T is s and whose file in T is not a historical file of T under
H, let d be the declared item that comes first in declaration order; the
spot of that tree finding is the spot of the run of the text of the tag
line of the declaration of d in the text of the file of d in T.

### 4.6 Findings of the class `deleted-decision`

@atom deleted-decision-finding=v1
@cites {
    identifiers#{external-namespaces=v1},
    ontology#{
        declared-item=v1, decision-record=v1, item-name=v1, tree=v1,
        parameter=v1,
    },
    documents#{file-readers=v1, tree-finding=v1, unreadable-file=v1},
    revisions#{base-item=v1},
    text#{text=v1, code-span=v1},
}

For a tree T and a base tree B, under a valid binding F of
`file-readers`, a binding N of `external-namespaces`, a set UT of
stopped files of T, and a set UB of stopped files of B, the declared
items, their kinds, and their names of T and of B, and the base items in
B of the declared items of T, are those that T and B have under F, N,
UT, and UB. Under F, N, UT, and UB, T has one tree finding of the class
`deleted-decision` against B for each text t that is the name in B of a
decision record e of B such that e is the base item in B of no declared
item of T. The subject of that tree finding is t. That tree finding has
no spot.

### 4.7 Items with new labels

@term new-label-item=v1
@cites {
    identifiers#{external-namespaces=v1},
    ontology#{
        declared-item=v1, item-revision=v1, tree=v1, parameter=v1,
    },
    documents#{file-readers=v1, item-file=v1, unreadable-file=v1},
    revisions#{base-item=v1},
    text#{text=v1, code-span=v1},
    #{historical-paths=v1, historical-file=v1},
}

For a tree T and a base tree B, under a valid binding F of
`file-readers`, a binding N of `external-namespaces`, a valid binding H
of `historical-paths`, a set UT of stopped files of T, and a set UB of
stopped files of B, a declared item d of T (under F, N, and UT) is an
item with a new label against B under F, N, H, UT, and UB when, and only
when, all three of these conditions hold:

1. d has a current revision in T.
2. The file of d in T is not a historical file of T under H.
3. Either d has no base item in B (under F, N, UT, and UB), or the base
   item e of d in B has no current revision in B or has a current
   revision in B that is not the same text as the current revision of d
   in T.

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
        run-spot=v1, tree-finding=v1, unreadable-file=v1,
    },
    revisions#{base-item=v1},
    text#{text=v1, sequence=v1, code-span=v1},
    #{historical-paths=v1, new-label-item=v1},
}

For a tree T, a base tree B, and a finite sequence L of trees, under a
valid binding F of `file-readers`, a binding N of `external-namespaces`,
a valid binding H of `historical-paths`, a set UT of stopped files of T,
a set UB of stopped files of B, and a set of stopped files of each
element of L, T has one tree finding of the class `reused-label` against
B and L for each declared item d of T that meets both of these
conditions:

1. d is an item with a new label against B under F, N, H, UT, and UB.
2. For at least one element K of L, with its set UK of stopped files, d
   has a base item e in K (under F, N, UT, and UK), e has a current
   revision in K that is the same text as the current revision of d in
   T, and either d and e are of different kinds of item or the extent
   hash of d in T (under F, N, and UT) is not the extent hash of e in K
   (under F, N, and UK).

The subject of that tree finding is the name of d in T. The spot of that
tree finding is the spot of the run of the text of the tag line of the
declaration of d in the text of the file of d in T.

### 4.9 Cut histories

@term cut-history=v1
@cites {
    ontology#{default-branch=v1, tree=v1, parameter=v1},
    changes#{
        commit=v1, commit-file=v1, shallow-commit=v1,
        default-branch-name=v1, default-branch-commit=v1,
        first-parent-line=v1, repository-read=v1,
    },
    documents#{file-readers=v1, read-file=v1, unreadable-file=v1},
    text#{code-span=v1},
}

This term is for a git repository R, the repository reads from which a
program takes the first-parent line of the commit of the default branch
and the files of the trees of its commits, a binding D of
`default-branch-name` under which the default branch of R has a commit
d, a valid binding F of `file-readers`, and, for each commit c of the
first-parent line of d, a set Uc of stopped files of the tree of c. In
this term, R holds a git object when R holds that git object at the end
of those repository reads. Thus R holds each git object that the program
fetches into R during those repository reads, and R does not hold a git
object that R lacks and that the program does not fetch. The history of
the default branch of R under D, F, and these sets is cut for those
repository reads when, and only when, one or more of these four
conditions holds:

1. A commit of the first-parent line of d is a shallow commit of R.
2. A commit of the first-parent line of d is not a shallow commit of R,
   and its commit object names as its first parent a git object that is
   not a commit of R.
3. For some commit c of the first-parent line of d, R does not hold the
   git tree object of c, does not hold a git tree object named by a
   tree entry under it, or does not hold the blob of a regular-file
   entry under it whose file in the tree of c is a read file of the
   tree of c under F.
4. For some commit c of the first-parent line of d, a read file of the
   tree of c under F is in Uc.

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
        commit=v1, default-branch-name=v1, default-branch-commit=v1,
        first-parent-line=v1, repository-read=v1, undisturbed-read=v1,
    },
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    documents#{file-readers=v1, unreadable-file=v1},
    approval#{approval-kinds=v1, bound-in-force-item=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{successor=v1},
}

This requirement applies for a git repository R whose ledger is valid
and that holds its ledger objects, under four bindings: a valid binding
A of `approval-kinds`, a binding D of `default-branch-name`, a valid
binding F of `file-readers`, and a binding N of `external-namespaces`
for which a conforming program of the design Identifiers gives the
result "valid". Under these bindings, this requirement applies when a
conforming program gives the successors of a declared item x of a tree T
at a point P of the ledger of R under A, D, F, N, and sets S of stopped
files (a set of stopped files of T and, when the default branch of R has
a commit under D, a set of stopped files of the tree of each commit of
the first-parent line of that commit), and each repository read from
which that program takes the ledger and the trees of the first-parent
line is undisturbed.

When R lacks git objects that a tree of the first-parent line of the
commit of the default branch needs for `approval#bound-in-force-item`,
the program must give each successor of x in T at P under A, D, F, N,
and S once and no other item, or must give no successor of x. Otherwise,
the program must give each successor of x in T at P under A, D, F, N,
and S once and no other item, except that when the program refuses a
graph of edges of T for limits of its own, the program must give no
successor for T.

### 5.2 Findings of the class `retired`

@req give-retired-findings=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        finding-class=v1, default-branch=v1, tree=v1, ledger=v1,
        parameter=v1,
    },
    changes#{
        commit=v1, default-branch-name=v1, default-branch-commit=v1,
        first-parent-line=v1, repository-read=v1, undisturbed-read=v1,
    },
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    documents#{file-readers=v1, tree-finding=v1, unreadable-file=v1},
    approval#{approval-kinds=v1, bound-in-force-item=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{historical-paths=v1, retired-finding=v1},
}

This requirement applies for a git repository R whose ledger is valid
and that holds its ledger objects, under five bindings: a valid binding
A of `approval-kinds`, a binding D of `default-branch-name`, a valid
binding F of `file-readers`, a binding N of `external-namespaces` for
which a conforming program of the design Identifiers gives the result
"valid", and a valid binding H of `historical-paths`. Under these
bindings, this requirement applies when a conforming program gives the
findings of the class `retired` of a tree T at a point P of the ledger
of R under A, D, F, N, H, and sets S of stopped files (a set of stopped
files of T and, when the default branch of R has a commit under D, a set
of stopped files of the tree of each commit of the first-parent line of
that commit), and each repository read from which that program takes the
ledger and the trees of the first-parent line is undisturbed.

When R lacks git objects that a tree of the first-parent line of the
commit of the default branch needs for `approval#bound-in-force-item`,
the program must give each tree finding of the class `retired` that T
has at P under A, D, F, N, H, and S once and no other finding of that
class, or must give no finding of that class for T. Otherwise, the
program must give each tree finding of the class `retired` that T has at
P under A, D, F, N, H, and S once and no other finding of that class,
except that when the program refuses a graph of edges of T for limits of
its own, the program must give no finding of that class for T.

### 5.3 Offered fixes of `retired` findings

@req limit-retired-fix-edit-sets=v1
@cites {
    files#{path=v1},
    identifiers#{
        external-namespaces=v1, validate-bindings=v1, citation=v1,
        citation-entry=v1, inline-citation=v1, tag-line-text=v1,
    },
    data-forms#{vector-line=v1, test-vector-set=v1},
    ontology#{
        declared-item=v1, item-name=v1, item-revision=v1, same-item=v1,
        edge=v1, pinned-edge=v1, site=v1, default-branch=v1, tree=v1,
        ledger=v1, parameter=v1,
    },
    changes#{
        commit=v1, default-branch-name=v1, default-branch-commit=v1,
        first-parent-line=v1, repository-read=v1, undisturbed-read=v1,
    },
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    findings#{
        spot=v1, edit=v1, edit-set=v1, edited-tree=v1, fix=v1,
        finding-part=v1, limit-fix-edit-sets=v1,
    },
    documents#{
        file-readers=v1, tree-edge=v1, origin=v1, tree-finding=v1,
        unreadable-file=v1, vector-file=v1,
    },
    approval#{approval-kinds=v1},
    text#{
        conforming-program=v1, result=v1, boundary=v1, span=v1, run=v1,
        code-point-order=v1, text=v1, code-span=v1,
    },
    #{historical-paths=v1, successor=v1, retired-finding=v1},
}

This requirement applies for a git repository R whose ledger is valid
and that holds its ledger objects, a tree T, a point P of the ledger of
R, a valid binding A of `approval-kinds`, a binding D of
`default-branch-name`, a valid binding F of `file-readers`, a binding N
of `external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", a valid binding H of
`historical-paths`, sets S of stopped files (a set U of stopped files of
T and, when the default branch of R has a commit under D, a set of
stopped files of the tree of each commit of the first-parent line of
that commit), and undisturbed repository reads.

Let E be the edge of a tree finding f of the class `retired` that T has
at P under A, D, F, N, H, and S, and let c be the cited item of E. When
c has one or more successors in T at P under A, D, F, N, and S, and a
conforming program gives a fix for f, that fix must meet all three of
these conditions:

1. The fix has exactly one edit set for each successor of c in T at P
   under A, D, F, N, and S, in the code point order of the names of
   those successors in T.
2. For each edit set of the fix, every edit of that edit set has a spot
   whose valid path is the valid path of the file of E in T, and whose
   span starts and ends at boundaries of:
   - when a citation entry gives E, the run of the text of the tag line
     of the citation of E in the text of that file (term
     `documents#origin`);
   - when an inline citation gives E, the run of that inline citation in
     the text of that file;
   - when a vector line gives E, the form run of E in the text of that
     vector file.
3. For each successor s of c, let T′ be the edited tree of the edit set
   for s, read under F, N, and the set U′ of stopped files of T′ that
   holds every file of T′ whose valid path is the valid path of a file
   in U (the file of E is not in U). In T′ under F, N, and U′:
   - when a citation entry or an inline citation gives E, the file of E
     in T′ can be read; when a vector line gives E, the content of the
     vector file of E in T′ is a test-vector set;
   - the edited citation, edited inline citation, or edited vector line
     in that file gives an edge E′ of the same kind of edge as E, whose
     source is the same item as the source of E (or is a site when the
     source of E is a site), whose cited item is the same item as s,
     and that is pinned with the current revision of s in T as its label
     when E is pinned, and is not pinned when E is not pinned;
   - when a citation entry gives E, each edge that a citation gives is
     represented by three properties: its kind of edge; its pinned
     label, or that it is not pinned; and its target, which is its cited
     item (as the same item) when the edge has a cited item, and the
     entry name of its citation entry when the edge has no cited item.
     Taken by these three properties, the set of edges that the edited
     citation gives in T′ is the set of edges that the citation of E
     gave in T with E replaced by E′.

### 5.4 Findings of the class `cycle`

@req give-cycle-findings=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{finding-class=v1, tree=v1, parameter=v1},
    documents#{file-readers=v1, tree-finding=v1, unreadable-file=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{historical-paths=v1, cycle-finding=v1},
}

This requirement applies under a valid binding F of `file-readers`, a
binding N of `external-namespaces` for which a conforming program of the
design Identifiers gives the result "valid", and a valid binding H of
`historical-paths`. When a conforming program gives the findings of the
class `cycle` of a tree T under F, N, H, and a set U of stopped files of
T, that program must give each tree finding of that class that T has
under F, N, H, and U once, and must give no other finding of that class,
except that when the program refuses a graph of edges of T for limits of
its own, the program must give no finding of that class for T.

### 5.5 Findings of the class `deleted-decision`

@req give-deleted-decision-findings=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{finding-class=v1, tree=v1, parameter=v1},
    documents#{file-readers=v1, tree-finding=v1, unreadable-file=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{historical-paths=v1, deleted-decision-finding=v1},
}

This requirement applies under a valid binding F of `file-readers`, a
binding N of `external-namespaces` for which a conforming program of the
design Identifiers gives the result "valid", and a valid binding H of
`historical-paths`. When a conforming program gives the findings of the
class `deleted-decision` of a tree T against a base tree B under F, N,
H, a set UT of stopped files of T, and a set UB of stopped files of B,
that program must give each tree finding of that class that T has
against B under F, N, UT, and UB once, and must give no other finding of
that class.

### 5.6 Findings of the class `reused-label`

@req give-reused-label-findings=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{finding-class=v1, tree=v1, parameter=v1},
    documents#{file-readers=v1, tree-finding=v1, unreadable-file=v1},
    text#{conforming-program=v1, result=v1, sequence=v1, code-span=v1},
    #{historical-paths=v1, reused-label-finding=v1},
}

This requirement applies under a valid binding F of `file-readers`, a
binding N of `external-namespaces` for which a conforming program of the
design Identifiers gives the result "valid", and a valid binding H of
`historical-paths`. When a conforming program gives the findings of the
class `reused-label` of a tree T against a base tree B and a finite
sequence L of trees under F, N, H, a set UT of stopped files of T, a set
UB of stopped files of B, and a set of stopped files of each element of
L, that program must give each tree finding of that class that T has
against B and L under F, N, H, and these sets once, and must give no
other finding of that class.

### 5.7 No result under bindings of reading that are not valid

@req omit-results-under-invalid-reading-bindings=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{finding-class=v1, declared-item=v1, tree=v1, parameter=v1},
    documents#{file-readers=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{successor=v1},
}

Under a binding of `file-readers` that is not valid, or under a binding
of `external-namespaces` for which a conforming program of the design
Identifiers gives the result "invalid", a conforming program must give
no successor of any declared item of any tree, and must give no finding
of the classes `retired`, `cycle`, `deleted-decision`, and
`reused-label` of any tree.

### 5.8 No finding under a binding of `historical-paths` that is not valid

@req omit-findings-under-invalid-historical-paths=v1
@cites {
    ontology#{finding-class=v1, tree=v1, parameter=v1},
    text#{conforming-program=v1, code-span=v1},
    #{historical-paths=v1},
}

Under a binding of `historical-paths` that is not valid, a conforming
program must give no finding of the classes `retired`, `cycle`,
`deleted-decision`, and `reused-label` of any tree.

### 5.9 No result from a ledger that is not valid

@req omit-results-from-invalid-ledgers=v1
@cites {
    ontology#{
        declared-item=v1, finding-class=v1, tree=v1, ledger=v1,
    },
    changes#{repository-read=v1, undisturbed-read=v1},
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    text#{conforming-program=v1, code-span=v1},
    #{successor=v1, retired-finding=v1},
}

For a git repository R, when each repository read from which a
conforming program reads the ledger of R is undisturbed, and when that
ledger is broken or newer or R does not hold its ledger objects, that
program must give no successor of any declared item of any tree and must
give no finding of the class `retired` of any tree at any point of that
ledger.

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
    documents#{file-readers=v1, tree-finding=v1, unreadable-file=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{historical-paths=v1, deleted-decision-finding=v1},
}

This requirement applies for a commit h under four bindings: a binding D
of `default-branch-name` under which the change of h has a base, a valid
binding F of `file-readers`, a binding N of `external-namespaces` for
which a conforming program of the design Identifiers gives the result
"valid", and a valid binding H of `historical-paths`. Under these
bindings, this requirement applies when a conforming program meets two
conditions. First, that program gives the findings of the class
`deleted-decision` of the change of h under these bindings, a set UT of
stopped files of the tree of h, and a set UB of stopped files of the
tree of the base of the change of h. Second, each repository read from
which that program takes the base of the change of h and the files of
the tree of h and of the tree of that base is undisturbed. Under these
bindings and when both conditions hold, that program must give each tree
finding of that class that the tree of h has against the tree of the
base of the change of h under F, N, UT, and UB once, and must give no
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
    documents#{file-readers=v1, tree-finding=v1, unreadable-file=v1},
    text#{conforming-program=v1, result=v1, sequence=v1, code-span=v1},
    #{
        historical-paths=v1, new-label-item=v1, reused-label-finding=v1,
        cut-history=v1,
    },
}

This requirement applies for a commit h of a git repository R under four
bindings: a binding D of `default-branch-name` under which the change of
h has a base (so the default branch of R has a commit d under D), a
valid binding F of `file-readers`, a binding N of `external-namespaces`
for which a conforming program of the design Identifiers gives the
result "valid", and a valid binding H of `historical-paths`. Under these
bindings, let UT be a set of stopped files of the tree of h, let UB be a
set of stopped files of the tree of the base of the change of h, and for
each commit c of the first-parent line of d, let Uc be a set of stopped
files of the tree of c. Let L be the sequence of the trees of the
commits of the first-parent line of d, in the order of that line.

This requirement applies when a conforming program meets three
conditions. First, that program gives the findings of the class
`reused-label` of the change of h under D, F, N, H, UT, UB, and the sets
Uc. Second, each repository read from which that program takes the base
of the change of h, the first-parent line of d, and the files of the
trees of h, of that base, and of the commits of that line is
undisturbed. Third, either the tree of h has no item with a new label
against the tree of the base of the change of h under F, N, H, UT, and
UB, or both of these hold: the history of the default branch of R under
D, F, and the sets Uc is not cut for those repository reads, and that
program does not stop reading the first-parent line of d for limits of
its own.

When the tree of h has no item with a new label against the tree of the
base of the change of h under F, N, H, UT, and UB, that program must
give no finding of the class `reused-label`. Otherwise, that program
must give each tree finding of the class `reused-label` that the tree of
h has against the tree of the base of the change of h and L under F, N,
H, UT, UB, and the sets Uc once, and must give no other finding of that
class.

### 5.12 The change of a commit with no base

@req report-missing-base=v1
@cites {
    ontology#{finding-class=v1, parameter=v1},
    changes#{
        commit=v1, default-branch-name=v1, change-of-a-commit=v1,
        change-base=v1, repository-read=v1, undisturbed-read=v1,
    },
    text#{conforming-program=v1, code-span=v1},
}

This requirement applies for a commit h under a binding of
`default-branch-name` under which the change of h has no base, when a
conforming program meets two conditions. First, that program gives the
findings of the class `deleted-decision` or of the class `reused-label`
of the change of h under that binding. Second, each repository read from
which that program takes that the change of h has no base is
undisturbed. Under that binding and when both conditions hold, that
program must give that the change of h has no base, and must give no
finding of that class.

### 5.13 The change of a commit with a base

@req omit-missing-base-report=v1
@cites {
    ontology#{finding-class=v1, parameter=v1},
    changes#{
        commit=v1, default-branch-name=v1, change-of-a-commit=v1,
        change-base=v1, repository-read=v1, undisturbed-read=v1,
    },
    text#{conforming-program=v1, code-span=v1},
}

This requirement applies for a commit h under a binding of
`default-branch-name` under which the change of h has a base, when a
conforming program meets two conditions. First, that program gives the
findings of the class `deleted-decision` or of the class `reused-label`
of the change of h under that binding, or gives whether the change of h
has a base under that binding. Second, each repository read from which
that program takes whether the change of h has a base is undisturbed.
Under that binding and when both conditions hold, that program must not
give that the change of h has no base.

### 5.14 When the first-parent line is cut or stopped for limits

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
    documents#{file-readers=v1, unreadable-file=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{historical-paths=v1, new-label-item=v1, cut-history=v1},
}

This requirement applies for a commit h of a git repository R under four
bindings: a binding D of `default-branch-name` under which the change of
h has a base (so the default branch of R has a commit d under D), a
valid binding F of `file-readers`, a binding N of `external-namespaces`
for which a conforming program of the design Identifiers gives the
result "valid", and a valid binding H of `historical-paths`. Under these
bindings, let UT be a set of stopped files of the tree of h, let UB be a
set of stopped files of the tree of the base of the change of h, and for
each commit c of the first-parent line of d, let Uc be a set of stopped
files of the tree of c.

This requirement applies when a conforming program meets four
conditions. First, that program gives the findings of the class
`reused-label` of the change of h under D, F, N, H, UT, UB, and the sets
Uc. Second, each repository read from which that program takes the base
of the change of h, the first-parent line of d, and the files of the
trees of h, of that base, and of the commits of that line is
undisturbed. Third, the tree of h has at least one item with a new label
against the tree of the base of the change of h under F, N, H, UT, and
UB. Fourth, either the history of the default branch of R under D, F,
and the sets Uc is cut for those repository reads, or that program stops
reading the first-parent line of d for limits of its own. When all four
conditions hold, that program must give that it cannot see the whole
history, and must give no finding of the class `reused-label`.

### 5.15 When the first-parent line is complete or no label is new

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
    documents#{file-readers=v1, unreadable-file=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{historical-paths=v1, new-label-item=v1, cut-history=v1},
}

This requirement applies for a commit h of a git repository R under four
bindings: a binding D of `default-branch-name` under which the change of
h has a base (so the default branch of R has a commit d under D), a
valid binding F of `file-readers`, a binding N of `external-namespaces`
for which a conforming program of the design Identifiers gives the
result "valid", and a valid binding H of `historical-paths`. Under these
bindings, let UT be a set of stopped files of the tree of h, let UB be a
set of stopped files of the tree of the base of the change of h, and for
each commit c of the first-parent line of d, let Uc be a set of stopped
files of the tree of c.

This requirement applies when a conforming program meets three
conditions. First, that program gives the findings of the class
`reused-label` of the change of h under D, F, N, H, UT, UB, and the sets
Uc. Second, each repository read from which that program takes the base
of the change of h, the first-parent line of d, and the files of the
trees of h, of that base, and of the commits of that line is
undisturbed. Third, either the tree of h has no item with a new label
against the tree of the base of the change of h under F, N, H, UT, and
UB, or the history of the default branch of R under D, F, and the sets
Uc is not cut for those repository reads and that program does not stop
reading the first-parent line of d for limits of its own. When all three
conditions hold, that program must not give that it cannot see the whole
history.

## 6. Conformance

A program, or a part of a program, conforms to this design when it is a
conforming program of this design: when it meets every requirement of
section 5.

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
`omit-results-under-invalid-reading-bindings`,
`omit-results-from-invalid-ledgers`,
`compare-change-for-deleted-decisions`,
`compare-change-for-reused-labels`, `report-missing-base`,
`omit-missing-base-report`, `report-cut-history`, and
`omit-cut-history-report`.

By the schemas below, each vector checks a program only when the set of
[stopped files](sinter:documents#unreadable-file=v1) of the program for
each tree of the vector is empty, when the program does not refuse the
graph of edges for limits of its own, and when no other process changes
the inputs while the program runs.

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
        supersedes-edge=v1, effective-supersedes-edge=v1, tree=v1,
        ledger=v1, parameter=v1,
    },
    changes#{
        default-branch-name=v1, default-branch-commit=v1,
        first-parent-line=v1,
    },
    documents#{file-readers=v1, tree-edge=v1, unreadable-file=v1},
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    approval#{approval-kinds=v1, bound-in-force-item=v1},
    #{successor=v1, give-successors=v1},
}

The group `successors` holds the vectors of the requirement
`give-successors`. Each vector gives the declared items of a tree (with
their kinds, owning designs, and whether each is in force), the
`supersedes` edges of the tree (with whether each edge is effective and
whether `every-part` matches its citation entry), and one declared item
of that tree. The vector gives the successors of that declared item in
the tree at a point of a ledger. The group uses no need, so these forms
give no need names.

The input of each vector stands for a valid ledger of a git repository
that holds its ledger objects and holds every git object that
`approval#bound-in-force-item` needs; for valid bindings of
`approval-kinds` and `file-readers`; for a binding of
`external-namespaces` for which a conforming program of Identifiers
gives the result "valid"; for one binding of `default-branch-name`; and
for empty sets of stopped files. No other process changes these inputs
while the program runs.

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
at the point under the bindings and empty sets of stopped files, that
program gives the declared item at each index in `successors` once and
gives no other item.

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
        conformance-vector-group=v1, external-item=v1, tree=v1,
        ledger=v1, finding-class=v1, parameter=v1,
    },
    changes#{
        default-branch-name=v1, default-branch-commit=v1,
        first-parent-line=v1,
    },
    documents#{
        file-readers=v1, tree-edge=v1, position-subject=v1,
        tree-finding=v1, unreadable-file=v1,
    },
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    approval#{approval-kinds=v1, bound-in-force-item=v1},
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
that holds its ledger objects and holds every git object that
`approval#bound-in-force-item` needs; for valid bindings of
`approval-kinds` and `file-readers`; for a binding of
`external-namespaces` for which a conforming program of Identifiers
gives the result "valid"; for one binding of `default-branch-name`; and
for empty sets of stopped files. No other process changes these inputs
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
    otherwise), `source-kind` (one of `"declared"`, `"group"`, and
    `"other"`), `source-in-force` (present when `source-kind` is
    `"declared"` or `"group"`: `true` when that declared item, or the
    owning design or specification of that group's vector set, is in
    force in the tree at the point under the bindings, and `false`
    otherwise), `cited-kind` (one of `"declared"`, `"group"`,
    `"vector-set"`, and `"external"`), `cited-in-force` (present when
    `cited-kind` is `"declared"`, `"group"`, or `"vector-set"`: `true`
    when that declared item, or the owning design or specification of
    that vector set, is in force in the tree at the point under the
    bindings, and `false` otherwise), `path` (the valid path of the file
    of the edge), and `at` (the position subject of the edge).
- `result`: no vector of the group has this member; these forms name no
  question for `result`.
- `values`: `{}` when `historical-paths` is not a valid path set;
  otherwise, a JSON object with one member, `findings`, a JSON array of
  the subjects (`at`) of the `retired` tree findings of the tree, each
  once, in code point order.

When `values` is `{}`, a conforming program gives no finding of the
class `retired` for the tree. When `values` is not `{}` and a conforming
program gives the findings of the class `retired` of the tree at the
point under the bindings and empty sets of stopped files, that program
gives one finding of that class with each subject in `findings` and
gives no other finding of that class.

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
        vector-line=v1,
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
        default-branch-name=v1, default-branch-commit=v1,
        first-parent-line=v1,
    },
    findings#{fix=v1, edit=v1, edit-set=v1, spot=v1},
    documents#{
        file-readers=v1, tree-edge=v1, origin=v1, named-item=v1,
        tree-finding=v1, unreadable-file=v1,
    },
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    approval#{approval-kinds=v1},
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
that holds its ledger objects; for valid bindings of `approval-kinds`,
`file-readers`, and `historical-paths` (under which the file of the edge
is not historical); for a binding of `external-namespaces` for which a
conforming program of Identifiers gives the result "valid"; for one
binding of `default-branch-name`; and for empty sets of stopped files.
No other process changes these inputs while the program runs.

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
  holding `successor` (the successor's name), `pinned` (whether the
  replacement edge is pinned), optional `label` (when `pinned` is
  `true`, the current revision that the replacement edge pins), `path`
  (the valid path within which every edit of that edit set has its
  spot), and `run` (a JSON object with `from` and `to`, the start and
  end boundaries in `text` of the run within which every edit of that
  edit set has its spot).

When `fix-allowed` is `false`, a conforming program gives no fix for the
`retired` finding. When `fix-allowed` is `true`, a conforming program
need not give a fix; when that program gives a fix for the `retired`
finding, that fix has as many edit sets as `edit-sets` has elements, in
the same order, where each edit set edits only `path` within `run`,
gives in its edited tree the replacement edge to that element's
`successor` (with `label` when `pinned` is `true`, and unpinned when
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
        position-order=v1, tree-finding=v1, unreadable-file=v1,
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
kinds, owning designs, file paths, and declaration origin positions),
and the `supersedes` and `refines` edges of the tree. The vector gives
the `cycle` findings of the tree by subject and declaration origin
position, or `{}` when the binding of `historical-paths` is not valid.
The group uses no need, so these forms give no need names.

The input of each vector stands for a valid binding of `file-readers`, a
binding of `external-namespaces` for which a conforming program of
Identifiers gives the result "valid", and the empty set of stopped
files. No other process changes these inputs while the program runs.

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
bindings and the empty set of stopped files, that program gives one
finding of that class for each element of `findings`, with the subject
that the element states, and gives no other finding of that class; when
that program gives the spot of such a finding, the spot has the valid
path and start position that the element states.

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
    documents#{
        file-readers=v1, name-set=v1, tree-finding=v1,
        unreadable-file=v1,
    },
    revisions#{base-item=v1},
    #{
        historical-paths=v1, deleted-decision-finding=v1,
        give-deleted-decision-findings=v1,
        omit-findings-under-invalid-historical-paths=v1,
    },
}

The group `deleted-decisions` holds the vectors of the requirements
`give-deleted-decision-findings` and
`omit-findings-under-invalid-historical-paths`. Each vector gives a
binding of `historical-paths`, the declared items of a base tree, and
the declared items of a tree. The vector gives the subjects of the
`deleted-decision` findings of the tree against the base tree, or `{}`
when the binding of `historical-paths` is not valid. The group uses no
need, so these forms give no need names.

The input of each vector stands for a valid binding of `file-readers`, a
binding of `external-namespaces` for which a conforming program of
Identifiers gives the result "valid", and empty sets of stopped files.
No other process changes these inputs while the program runs.

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
- `values`: `{}` when `historical-paths` is not a valid path set;
  otherwise, a JSON object with one member, `findings`, a JSON array of
  the subjects of the `deleted-decision` tree findings of the tree
  against the base tree, each once, in code point order.

When `values` is `{}`, a conforming program gives no finding of the
class `deleted-decision` for the tree. When `values` is not `{}` and a
conforming program gives the findings of the class `deleted-decision` of
the tree against the base tree under the bindings and empty sets of
stopped files, that program gives one finding of that class with no spot
for each subject in `findings` and gives no other finding of that class.

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
        tree-finding=v1, unreadable-file=v1,
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
declared items of a tree, and a finite sequence of history trees. The
vector gives the subjects of the `reused-label` findings of the tree
against the base tree and that sequence, or `{}` when the binding of
`historical-paths` is not valid. The group uses no need, so these forms
give no need names.

The input of each vector stands for a valid binding of `file-readers`, a
binding of `external-namespaces` for which a conforming program of
Identifiers gives the result "valid", and empty sets of stopped files.
No other process changes these inputs while the program runs.

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
  - `history`: the finite sequence of history trees, as a JSON array in
    which each element is the sequence of declared items of that history
    tree.
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
tree against the base tree and `history` under the bindings and empty
sets of stopped files, that program gives one finding of that class with
each subject in `findings` and gives no other finding of that class.
