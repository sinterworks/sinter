<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Revisions
@design revisions=v1
@cites {
    conformance=v1, text=v1, identifiers=v1, files=v1, data-forms=v1,
    ontology=v1, object-store=v1, changes=v1, findings=v1,
    documents=v1,
}
Revision checks compare declared items between a tree and a base tree to flag altered items with unchanged revision labels, compare commit changes against their change bases, and flag pinned citation edges that no longer match a current declared item.

A revision label names one revised content of a declared item. Against
a base tree, `needs-revision` findings flag declared items that changed
without a new revision label. Within one tree, `suspect` findings flag
pinned citation edges whose target no longer matches a current declared
item. What a conforming program returns from a repository read that is
not undisturbed, or from a file that changes while the program reads
it, is a matter of quality of implementation.

## Definitions

### Base item

@term base-item=v1
@cites {
    ontology#{
        declared-item=v1, item-name=v1, same-item=v1, containment=v1,
        encoding=v1, tree=v1,
    },
    documents#name-set=v1,
    text#text=v1,
}

For two `tree`s `T` and `B` (each holding `declared-item`s in the text
`encoding`, in the `.sinter/` encoding, or in both, under
`containment`), the `name-set` of `B` that **corresponds** to a
`name-set` `N` of `T` is:

- for the shared set of `T`: the shared set of `B`;
- for the set of a declared item `D` of the kind `design` of `T`, when
  no other declared item of the kind `design` of `T` has the `item-name`
  of `D`: the set of the declared item of the kind `design` of `B` whose
  `item-name` equals the `item-name` of `D`, when `B` has exactly one
  such item.

Otherwise, `N` has no corresponding `name-set` in `B`.

The **base item** in `B` of a `declared-item` `d` of `T` is the
`declared-item` `e` of `B` that meets all four of these conditions:

1. `d` belongs to a `name-set` `N` of `T` that has a corresponding
   `name-set` `M` in `B`;
2. `e` belongs to `M` and is the `same-item` as `d` (their `item-name`
   values are equal `text`s, regardless of their kinds of item, their
   encodings, and their file paths);
3. `d` is the only declared item in `N` with that name;
4. `e` is the only declared item in `M` with that name.

Otherwise, `d` has no base item in `B`.

### Findings of the class `needs-revision`

@atom needs-revision-finding=v1
@cites {
    conformance#own-store=v1,
    files#path=v1,
    identifiers#{
        external-namespaces=v1, declaration=v1, tag-line-text=v1,
    },
    ontology#{
        declared-item=v1, item-name=v1, item-revision=v1,
        revised-content=v1, content-hash=v1, encoding=v1, parameter=v1,
        tree=v1,
    },
    object-store#{tree-object-store=v1, valid-object-file=v1},
    findings#location=v1,
    documents#{
        file-readers=v1, item-file=v1, kept-object-set=v1,
        canonical-object=v1, origin=v1, slice-location=v1,
        tree-finding=v1,
    },
    text#text=v1,
    #base-item=v1,
}

This atom is for a `tree` `T`, a base `tree` `B`, valid bindings of the
`parameter`s `file-readers` and `external-namespaces`, and a valid
`kept-object-set`. The `declared-item`s, their kinds, names
(`item-name`), current revisions (`item-revision`), canonical objects
(`canonical-object`), `content-hash` values (`revised-content`), and
files (`item-file`) of `T` and `B`, and the `base-item` in `B` of each
declared item of `T`, are those that `T` and `B` have under those
bindings and `kept-object-set`, across the text `encoding` and the
`.sinter/` encoding (when each tree's `tree-object-store` is valid), or
from a valid `own-store`.

Under those inputs, `T` has one `tree-finding` of the class
`needs-revision` against `B` for each `declared-item` `d` of `T` that
meets all three of these conditions:

1. `d` has a current revision (`item-revision`) in `T` and a `base-item`
   `e` in `B`;
2. `e` has a current revision in `B` that is the same `text` as the
   current revision of `d` in `T`;
3. `d` and `e` are of different kinds of item, or the `content-hash` of
   the `canonical-object` of `d` in `T` differs from the `content-hash`
   of the `canonical-object` of `e` in `B`.

The subject of that finding is the `item-name` of `d`. The `location` of
that finding follows the input from which `d` comes:

- when `d` is in the text encoding in `T`: the `slice-location` of the
  `origin` slice of the `tag-line-text` of the `declaration` of `d` in
  the text of the file of `d` in `T`;
- when `d` is in the `.sinter/` encoding in `T`: the valid `path` of the
  `valid-object-file` of `d` in `T` alone, with no span;
- when a program takes `d` from a valid `own-store` with no file in `T`:
  no location.

@example Suppose a design `billing` holds specification
`billing#invoices=v1`, which holds requirement `billing#size=v1`
([containment](sinter:ontology#containment=v1)), and `billing#size`
carries a trailing `@example` block
([example-block](sinter:documents#example-block=v1)).

- Changing a normative sentence of `billing#size` while both
  `billing#size` and `billing#invoices` keep label `v1` changes the
  [canonical object](sinter:documents#canonical-object=v1) and
  [content hash](sinter:ontology#content-hash=v1) of `billing#size`,
  which in turn changes the exact `items` edge target in the canonical
  object of `billing#invoices`. Both `billing#size` and
  `billing#invoices` get `needs-revision` findings, whereas `billing`
  holds no `items` edge ([object-kind](sinter:ontology#object-kind=v1))
  and gets no `needs-revision` finding.
- Editing only the trailing `@example` block of `billing#size` leaves
  the [hashed lines](sinter:documents#hashed-line=v1) and canonical
  object of `billing#size` unchanged (each `@example` block hashes
  separately as an anonymous `example` object with no revision label),
  so neither `billing#size` nor `billing#invoices` gets a
  `needs-revision` finding.

### Findings of the class `suspect`

@atom suspect-finding=v1
@refines ontology#suspect-edge=v1
@cites {
    conformance#own-store=v1,
    identifiers#{
        external-namespaces=v1, citation-entry=v1, inline-citation=v1,
    },
    data-forms#vector-line=v1,
    ontology#{
        edge=v1, pinned-edge=v1, declared-item=v1, object-kind=v1,
        content-id=v1, encoding=v1, parameter=v1, tree=v1, test=v1,
        site=v1, conformance-vector-group=v1,
    },
    object-store#tree-object-store=v1,
    findings#location=v1,
    documents#{
        file-readers=v1, vector-files=v1, vector-file=v1,
        kept-object-set=v1, example-block=v1, canonical-target=v1,
        canonical-object=v1, tree-edge=v1, origin=v1,
        origin-position=v1, position-subject=v1,
        edge-finding-subject=v1, slice-location=v1, tree-finding=v1,
    },
}

This atom is for a `tree`, valid bindings of the `parameter`s
`file-readers`, `vector-files`, and `external-namespaces`, a valid
`kept-object-set`, and a valid `tree-object-store` (or a valid
`own-store`). Under those inputs, the tree has `tree-finding`s of the
class `suspect` for the `pinned-edge`s among the `tree-edge`s of the
tree that are suspect in the tree (`ontology#suspect-edge`) and whose
target is not a missing part (`ontology#edge`, `canonical-target`).

Only citation edges (`cites`, `satisfies`, `verifies`, `refines`, and
`supersedes`) whose source is one of these five kinds produce `suspect`
findings:

- a current `declared-item` of the tree (in the text `encoding`, in the
  `.sinter/` encoding, or from a valid `own-store`);
- an `example` object (`object-kind`) of a text declared item
  (`example-block`, `canonical-object`), from accepted
  `inline-citation`s inside that example block;
- a `conformance-vector-group`, from a `vector-line` of a `vector-file`;
- a `test`; or
- a `site`.

Structural edges (`items`, `about`, `revises`), scope and record edges,
edges with no source, and edges of replaced or withdrawn declared-item
objects in `.sinter/` produce no `suspect` finding.

The count, subject, and `location` of `suspect` findings follow the
source of the edge:

- **Current declared item or `example` object** (whose
  `canonical-object` is not withheld): one `suspect` finding per
  distinct canonical citation edge
  `<source-content-id> <edge-kind> <target-content-id>` (`content-id`,
  such as `example:<32 hex> cites <target-content-id>` when the source
  is an `example` object). Its subject is its `edge-finding-subject`,
  and its `location` is its object edge location
  (`edge-finding-subject`).
- **Test or site** (from a `citation-entry` or `inline-citation`): one
  `suspect` finding per edge. Its subject is the `position-subject` of
  the `origin-position` of that citation entry or inline citation, and
  its `location` is the `slice-location` of its `origin` slice in the
  text of the file of the edge.
- **Group of conformance vectors** (from a `vector-line` in a
  `vector-file`): one `suspect` finding per edge. Its subject is the
  `position-subject` of the form position (`tree-edge`) of that edge in
  that vector file, and its `location` is the `slice-location` of the
  form slice (`tree-edge`) of that edge in the text of that vector file.

@example Suppose design `d` holds requirement `d#a` at current revision
`v2` and a kept object
([kept-object-set](sinter:documents#kept-object-set=v1)) holds
requirement `d#a` at `v1`. A trailing `@example` block
([example-block](sinter:documents#example-block=v1)) on `d#b` containing
`[a](sinter:#a=v1)` produces a `cites` edge on the `example` object
([canonical-object](sinter:documents#canonical-object=v1)) targeting the
kept `v1` object. That edge is suspect
([suspect-edge](sinter:ontology#suspect-edge=v1)) and produces one
`suspect` finding with subject `example:<32 hex> cites req:<32 hex>`
([edge-finding-subject](sinter:documents#edge-finding-subject=v1)) and
the [slice location](sinter:documents#slice-location=v1) of
`[a](sinter:#a=v1)`.

Likewise, when [vector-files](sinter:documents#vector-files=v1) maps `t`
to `t.test-vectors.jsonl`, schema `t#g-vector` is at `v2`, and a kept
object holds `t#g-vector` at `v1`, a
[vector line](sinter:data-forms#vector-line=v1) starting with
`{"form":"#g-vector=v1",...}` on line 1 produces one `suspect` finding
with [position subject](sinter:documents#position-subject=v1)
`t.test-vectors.jsonl@L1C10` and the slice location of its form slice
`#g-vector=v1` ([tree-edge](sinter:documents#tree-edge=v1)).

## Requirements

### Returning `needs-revision` findings

@req give-needs-revision-findings=v1
@cites {
    conformance#{
        conforming-program=v1, dependence=v1, own-store=v1,
        reject-invalid-inputs=v1, report-missing-parts=v1,
        give-results-over-canonical-objects=v1,
        read-defined-encodings=v1,
    },
    identifiers#external-namespaces=v1,
    ontology#{
        finding-class=v1, tree=v1, parameter=v1, edge=v1,
        declared-item=v1, computed-identity=v1,
    },
    object-store#{tree-object-store=v1, valid-object-file=v1},
    documents#{
        file-readers=v1, kept-object-set=v1, canonical-target=v1,
        canonical-object=v1, tree-finding=v1,
    },
    #{base-item=v1, needs-revision-finding=v1},
}

Given a `tree` `T`, a base `tree` `B`, valid bindings of the
`parameter`s `file-readers` and `external-namespaces`, a valid
`kept-object-set`, and valid object stores (`tree-object-store`) of `T`
and `B` (or valid `own-store`s), when a conforming program returns the
findings of the `finding-class` `needs-revision` of `T` against `B`
(`give-results-over-canonical-objects`, `read-defined-encodings`), the
program must return each `needs-revision-finding` (`tree-finding`) that
`T` has against `B` once, and must return no other finding of that
class.

When `file-readers`, `external-namespaces`, `kept-object-set`, or the
`tree-object-store` of `T` or `B` is invalid, a conforming program must
return no `needs-revision` finding (`reject-invalid-inputs`).

A `needs-revision` finding for a `declared-item` `d` of `T` needs
(`dependence`, `report-missing-parts`) a missing part of a citation
`edge` (`canonical-target`) only when computing the `canonical-object`
of `d` in `T` or of its `base-item` in `B` needs that part. That finding
does not need a `computed-identity` object missing from `.sinter/`
(`tree-object-store`) when the `valid-object-file` of `d` in `T` and of
its `base-item` in `B` already hold their `canonical-object`s.

### Returning `suspect` findings

@req give-suspect-findings=v1
@cites {
    conformance#{
        conforming-program=v1, dependence=v1, own-store=v1,
        reject-invalid-inputs=v1, report-missing-parts=v1,
        give-results-over-canonical-objects=v1,
        read-defined-encodings=v1,
    },
    identifiers#external-namespaces=v1,
    data-forms#vector-line=v1,
    ontology#{
        finding-class=v1, tree=v1, parameter=v1, edge=v1,
        suspect-edge=v1, declared-item=v1, computed-identity=v1,
        test=v1, site=v1,
    },
    object-store#tree-object-store=v1,
    documents#{
        file-readers=v1, vector-files=v1, kept-object-set=v1,
        example-block=v1, canonical-target=v1, canonical-object=v1,
        tree-finding=v1,
    },
    #suspect-finding=v1,
}

Given a `tree`, valid bindings of the `parameter`s `file-readers`,
`vector-files`, and `external-namespaces`, a valid `kept-object-set`,
and a valid `tree-object-store` (or a valid `own-store`), when a
conforming program returns the findings of the `finding-class` `suspect`
of that tree (`give-results-over-canonical-objects`,
`read-defined-encodings`), the program must return each
`suspect-finding` (`tree-finding`) that the tree has once, and must
return no other finding of that class.

Only a `suspect` finding for an edge produced by a `vector-line` depends
on (`dependence`) the binding of `vector-files`. When `vector-files` is
invalid while `file-readers`, `external-namespaces`, `kept-object-set`,
and `tree-object-store` are valid, a conforming program must withhold
every `suspect` finding for a vector-line edge (`reject-invalid-inputs`)
and must still return every `suspect` finding for edges from declared
items, `example` objects, `test`s, and `site`s. When `file-readers`,
`external-namespaces`, `kept-object-set`, or `tree-object-store` is
invalid, a conforming program must return no `suspect` finding
(`reject-invalid-inputs`).

A `suspect` finding for an edge needs (`dependence`,
`report-missing-parts`) a missing part (`ontology#edge`,
`canonical-target`, including a stored `pin:` edge in `.sinter/` whose
`pin` `computed-identity` object no input of the run supplies under
`tree-object-store` or whose resolution under `canonical-target` is a
missing part) when, and only when, one of these three conditions holds:

- the target of that edge is that missing part;
- the source of that edge is a `declared-item` or an `example` object
  (`example-block`) whose `canonical-object` that missing part
  withholds; or
- deciding whether that edge is suspect (`suspect-edge`) needs a
  `canonical-object` that that missing part withholds.

When another input of the run supplies a `computed-identity` object that
no file of `.sinter/` holds, a conforming program must withhold no
`suspect` finding because that file is absent (`tree-object-store`,
`canonical-target`).

### Comparing a commit change with its change base

@req compare-with-change-base=v1
@cites {
    conformance#{conforming-program=v1, reject-invalid-inputs=v1},
    ontology#{finding-class=v1, tree=v1, parameter=v1},
    changes#{
        default-branch-name=v1, commit=v1, commit-file=v1,
        commit-change=v1, change-base=v1, repository-read=v1,
        undisturbed-read=v1,
    },
    #give-needs-revision-findings=v1,
}

For a `commit` `h` of a git repository under a valid binding of the
`parameter` `default-branch-name`, when every `repository-read` from
which a conforming program reads whether `h` has a `change-base` (and,
when `h` has one, its `change-base` and the `commit-file`s of the `tree`
of `h` and of the `tree` of that change base) is undisturbed
(`undisturbed-read`):

- **When `h` has a `change-base` `b`:** When returning the findings of
  the `finding-class` `needs-revision` of the `commit-change` of `h`,
  the program must return the findings that
  `give-needs-revision-findings` obliges for the `tree` of `h` against
  the `tree` of `b`. When returning the `needs-revision` findings of the
  `commit-change` of `h`, or returning whether `h` has a `change-base`,
  the program must not return that `h` has no `change-base`.
- **When `h` has no `change-base`:** When returning the findings of the
  `finding-class` `needs-revision` of the `commit-change` of `h`, the
  program must return that `h` has no `change-base`, and must return no
  finding of the class `needs-revision`.

When `default-branch-name` is invalid, a conforming program must return
neither `needs-revision` findings for the `commit-change` of `h` nor
that `h` has no `change-base` (`reject-invalid-inputs`).

## Test vectors

@schema trees-vector=v1
@cites {
    conformance#{
        conforming-program=v1, reject-invalid-inputs=v1,
        report-missing-parts=v1,
    },
    text#{
        text=v1, byte-sequence=v1, valid-utf-8=v1, utf-8-text=v1,
        code-point-order=v1, slice=v1, span=v1,
    },
    files#{path=v1, path-set=v1},
    data-forms#{
        json-value=v1, hex-text=v1, line-object=v1, vector-line=v1,
        test-vector-set=v1, group-schema=v1, vector-meaning=v1,
    },
    identifiers#{external-namespaces=v1, slug=v1},
    ontology#{
        tree=v1, finding-class=v1, object=v1, declared-item=v1,
        computed-identity=v1, object-withdrawal=v1,
    },
    object-store#tree-object-store=v1,
    findings#{finding-subject=v1, location=v1},
    documents#{
        file-readers=v1, vector-files=v1, kept-object-set=v1,
        tree-finding=v1,
    },
    #{
        needs-revision-finding=v1, suspect-finding=v1,
        give-needs-revision-findings=v1, give-suspect-findings=v1,
    },
}

`trees-vector` is a `group-schema` for group `trees` in
[`revisions.test-vectors.jsonl`](revisions.test-vectors.jsonl) and tests
`give-needs-revision-findings` and `give-suspect-findings`. That file is
a `test-vector-set` of `vector-line` entries whose meaning follows
`vector-meaning`. Group `trees` omits `result`, uses no `needs`, and
stands for trees in which no list of persons is bound
(`object-withdrawal`). The `json-value` objects `input`, `values`, each
element of `values.findings`, and each `location` hold only the members
listed in this table, and each JSON string represents a `text`.

| field | type | meaning |
|---|---|---|
| `input.base` | object | base `tree`: maps each file's valid `path` to its content `byte-sequence`, as its `utf-8-text` string when `valid-utf-8` or `{"bytes": "<hex-text>"}` otherwise |
| `input.tree` | object | target `tree`, encoded in the same form as `input.base` |
| `input.file-readers` | array of arrays | binding of `file-readers` in pair order: each element is one `path-set` string array paired with reader `"markdown"` |
| `input.external-namespaces` | array of objects | binding of `external-namespaces` (order has no meaning): each element holds `namespace-name` and `id-pattern` strings |
| `input.vector-files` | object (optional) | binding of `vector-files`: maps target name strings to file path strings; defaults to `{}` when absent |
| `input.kept` | array of `line-object` (optional) | `kept-object-set` of valid canonical `object`s (`declared-item` and `computed-identity`, order has no meaning); defaults to empty when absent |
| `values.findings[]` | array of objects (optional) | present when `file-readers`, `external-namespaces`, and the `tree-object-store` of `input.tree` are valid; absent (`values` is `{}`) when any of those three is invalid; sorted in `code-point-order` of `class` then `subject` |
| `values.findings[].class` | string | `finding-class` `slug`: `"needs-revision"` or `"suspect"` |
| `values.findings[].subject` | string | `finding-subject` text |
| `values.findings[].location` | object (optional) | finding `location` (`path` string and optional `span` object with non-negative integer `from` and `to` `slice` boundaries of the file's text); absent when the finding has no location |

When `values` is `{}`, a conforming program returns no finding of either
class for `input.tree` (`reject-invalid-inputs`). Otherwise,
`values.findings` holds:

- each `needs-revision-finding` (`tree-finding`) of `input.tree` against
  `input.base` whose canonical objects need no missing part
  (`report-missing-parts`), except when the `tree-object-store` of
  `input.base` is invalid (in which case `values.findings` holds no
  `needs-revision` finding);
- each `suspect-finding` (`tree-finding`) of `input.tree` that needs no
  missing part (`give-suspect-findings`), except when
  `input.vector-files` is invalid (in which case `values.findings` holds
  no `suspect` finding for a vector-line edge).

When `values` is not `{}` and a conforming program returns findings of
one of these classes for `input.tree` (against `input.base` for
`needs-revision`), the program returns one finding per element of
`values.findings` of that class with its `subject` and no other finding
of that class. When the program returns a finding's `location`, the
program returns that element's `location` (with its `span` when present,
or no span when absent), and returns no location when that element omits
`location`.

@example Sample lines testing
[give-needs-revision-findings](sinter:#give-needs-revision-findings=v1)
and [give-suspect-findings](sinter:#give-suspect-findings=v1) on
trailing [example blocks](sinter:documents#example-block=v1)
([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#trees-vector=v1","group":"trees","input":{"base":{"d.md":"# D\n@design d=v1\n\n## R\n@req r=v1\nMust hold.\n\n@example Old example text.\n"},"external-namespaces":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"}],"file-readers":[["*.md"]],"tree":{"d.md":"# D\n@design d=v1\n\n## R\n@req r=v1\nMust hold.\n\n@example Updated example text.\n"}},"note":"editing a trailing @example block does not change its parent item canonical object and triggers no needs-revision finding","values":{"findings":[]}}
{"form":"#trees-vector=v1","group":"trees","input":{"base":{"d.md":"# D\n@design d=v1\n\n## A\n@req a=v1\nOld.\n\n## B\n@req b=v1\nNorm.\n\n@example Uses [a](sinter:#a=v1).\n"},"external-namespaces":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"}],"file-readers":[["*.md"]],"kept":[{"edges":[{"kind":"about","to":"name:75afe06bd08d5b6a5feb9de36f0ddcae"}],"kind":"req","label":"v1","name":"d#a","text":"paragraph: Old.\n","v":1}],"tree":{"d.md":"# D\n@design d=v1\n\n## A\n@req a=v2\nNew.\n\n## B\n@req b=v1\nNorm.\n\n@example Uses [a](sinter:#a=v1).\n"}},"note":"a stale inline citation inside a trailing @example block gives a suspect finding whose subject names the example object","values":{"findings":[{"class":"suspect","location":{"path":"d.md","span":{"from":75,"to":92}},"subject":"example:a4d87c91cdb3d644d9a6a3e771c854d8 cites req:008bbb08cb6a8ea9868e216a3b1e8770"}]}}
```
