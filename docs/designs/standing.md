<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Standing
@design standing=v1
@cites {
    conformance=v1, text=v1, files=v1, data-forms=v1, identifiers=v1,
    ontology=v1, object-store=v1, changes=v1, findings=v1, documents=v1,
    revisions=v1, approval=v1,
}
Standing checks trace in-force successors of retired declared items, constrain offered fixes for references to retired items, and return findings for retired references, edge cycles, deleted decision records, and reused revision labels.

Declared items change over time as authors deprecate them, replace them
through `supersedes` edges, or assign new revision labels to altered
content. Standing checks read text files, `.sinter/` object stores, or
valid program's own stores against default-branch history and configured
historical paths.

## Parameters

### Historical paths

@schema historical-paths=v1
@cites {files#path-set=v1, ontology#parameter=v1}

A binding of the `parameter` `historical-paths` is a `path-set`. A
binding meets the schema `historical-paths` when that path set is valid
(including the empty path set). Otherwise, the binding is invalid.

## Definitions

### Historical files

@term historical-file=v1
@cites {
    conformance#own-store=v1,
    files#{path=v1, path-set=v1, path-set-membership=v1},
    object-store#store-file=v1,
    ontology#{declared-item=v1, parameter=v1, tree=v1},
    #historical-paths=v1,
}

Under a valid binding `H` of the `parameter` `historical-paths` (a valid
`path-set`), a file of a `tree` is a **historical file** of that tree
under `H` when both of these conditions hold:

1. The valid `path` of that file is in the set of `H`
   (`path-set-membership`).
2. That file is neither a store file nor a local file of that tree
   (`store-file`).

A `declared-item` read from a valid program's own store (`own-store`)
with no file is never in a historical file of any tree under any binding
of `historical-paths`.

## Retirement and successors

@spec retirement=v1

Declared items retire over time when authors deprecate them or replace
them with newer items. In-force declared items can replace a retired
item through effective `supersedes` edges, while existing citations in
documents, examples, code, tests, and test-vector files can still refer
to the retired item.

Retirement analysis computes the in-force successors of retired items,
returns `retired` findings for references outside historical files, and
constrains optional in-place fixes that rewrite retired references.
When default-branch history is incomplete or the default branch name is
invalid, approval completions decide which results a program returns and
which results the program omits.

### Definitions

#### Successor

@term successor=v1
@cites {
    conformance#own-store=v1,
    identifiers#external-namespaces=v1,
    ontology#{
        declared-item=v1, item=v1, edge=v1, supersedes-edge=v1,
        effective-supersedes-edge=v1, retired-item=v1,
        deprecated-item=v1, containment=v1, object-withdrawal=v1,
        vector-set=v1, conformance-vector-group=v1, tree=v1,
        parameter=v1, encoding=v1,
    },
    object-store#tree-object-store=v1,
    changes#default-branch-name=v1,
    documents#{
        file-readers=v1, kept-object-set=v1, tree-edge=v1,
        tree-containment=v1,
    },
    approval#{
        approval-kinds=v1, persons=v1, merge-dependent-edge=v1,
        in-force-item=v1,
    },
}

This term applies for a git repository `R`, a `tree` `T` whose
`tree-object-store` is valid (or a valid `own-store`), valid bindings of
the `parameter`s `approval-kinds` (`A`), `file-readers` (`F`), and
`external-namespaces` (`N`), `persons` unbound or bound to a valid
binding `L`, a valid `kept-object-set` `K`, and—when `T` holds a
`merge-dependent-edge` under `A`—a valid binding `D` of
`default-branch-name`.

In this term, `declared-item`s (neither withdrawn nor replaced under
`object-withdrawal`), status tags (in text and from member `status` in
`.sinter/` per `deprecated-item`), `containment` (`tree-containment`),
and citation edges (`tree-edge`, whose targets are neither missing parts
nor ambiguous pins under `edge`) come from both encodings (`encoding`)
of `T` (or from a valid `own-store`) under `F`, `N`, `K`, and `persons`.
Whether a declared item of `T` is in force or retired under these inputs
follows `in-force-item` (`retired-item`). A `supersedes-edge` of `T` is
effective under these inputs when it meets `effective-supersedes-edge`
as `in-force-item` evaluates it. Only `supersedes` edges enter direct
replacement; `revises`, `items`, `about`, and record or `scope` edges
never enter direct replacement.

A declared item `y` of `T` **directly replaces** a declared item `x` of
`T` when an effective `supersedes` edge of `T` has `y` as its source and
`x` as its cited item.

For a declared item `x` of `T` that is retired under these inputs, a
declared item `s` of `T` is a **successor** of `x` in `T` when both of
these conditions hold:

1. `s` is in force in `T` under these inputs.
2. A finite sequence of one or more pairs `(u, v)` of declared items of
   `T` meets all three of these conditions:
   - the first item of the first pair is `x`, and the second item of the
     last pair is `s`;
   - for each pair `(u, v)` in the sequence, `v` directly replaces `u`
     in `T`;
   - for each pair before the last, its second item equals the first
     item of the next pair and is retired in `T`.

A declared item of `T` that is in force under these inputs has no
successor. An `item` of `T` that is not a declared item, such as a
`vector-set` or a `conformance-vector-group`, has no successor.

@example Assume every item is approved and no item is
[deprecated](sinter:ontology#deprecated-item=v1), so every
[supersedes edge](sinter:ontology#supersedes-edge=v1) is
[effective](sinter:ontology#effective-supersedes-edge=v1):

- **Diamond:** `d2` and `d3` each supersede `d1`, and `d4` supersedes
  both `d2` and `d3`. Both `d2` and `d3` are
  [retired](sinter:ontology#retired-item=v1) and `d4` is in force, so
  `d1` has the single successor `d4`.
- **Cycle inside a retired design:** design `new` supersedes design
  `old`, so `old#p` and `old#q` are retired by
  [containment](sinter:ontology#containment=v1). Inside `old`, `old#p`
  and `old#q` supersede each other; neither reaches an in-force item, so
  neither has a successor. If an in-force `new#q` supersedes `old#q`,
  both `old#p` and `old#q` have the single successor `new#q`.
- **Edge into an in-force cycle:** `y` and `z` supersede each other and
  stay in force ([retired-item](sinter:ontology#retired-item=v1)), while
  `y` also supersedes `x`. Because `y` is in force, direct replacement
  from `x` stops at `y`: `y` is the only successor of `x`, and `z` is
  not a successor of `x`.

#### Findings of the class `retired`

@atom retired-finding=v1
@refines ontology#retired-item=v1
@cites {
    conformance#own-store=v1,
    identifiers#{
        external-namespaces=v1, citation-entry=v1, inline-citation=v1,
    },
    data-forms#vector-line=v1,
    ontology#{
        declared-item=v1, edge=v1, cites-edge=v1, satisfies-edge=v1,
        verifies-edge=v1, refines-edge=v1, vector-set=v1,
        conformance-vector-group=v1, test=v1, site=v1, object-kind=v1,
        content-id=v1, tree=v1, parameter=v1, encoding=v1,
    },
    object-store#tree-object-store=v1,
    changes#default-branch-name=v1,
    findings#{ackable-finding=v1, finding-part=v1, location=v1},
    documents#{
        file-readers=v1, vector-files=v1, vector-file=v1,
        kept-object-set=v1, example-block=v1, canonical-target=v1,
        canonical-object=v1, tree-edge=v1, origin=v1,
        origin-position=v1, position-subject=v1,
        edge-finding-subject=v1, slice-location=v1,
    },
    approval#{
        approval-kinds=v1, persons=v1, merge-dependent-edge=v1,
        in-force-item=v1,
    },
    #{historical-paths=v1, historical-file=v1, successor=v1},
}

This atom applies for a git repository `R`, a `tree` `T` whose
`tree-object-store` is valid (or a valid `own-store`), valid bindings of
the `parameter`s `approval-kinds` (`A`), `file-readers` (`F`),
`vector-files` (`V`), `external-namespaces` (`N`), and
`historical-paths` (`H`), `persons` unbound or bound to a valid binding
`L`, a valid `kept-object-set` `K`, and—when `T` holds a
`merge-dependent-edge` under `A`—a valid binding `D` of
`default-branch-name`.

In this atom, the edges of `T` are the citation edges (`tree-edge`)
across both encodings (`encoding`, or from a valid `own-store`) under
`F`, `V`, `N`, `K`, and `persons`, whose targets are neither missing
parts nor ambiguous pins (`edge`, `canonical-target`,
`canonical-object`). Structural edges (`items`, `about`, `revises`),
record and `scope` edges, and edges of replaced or withdrawn
declared-item objects in `.sinter/` produce no `retired` finding.

A source of an edge of `T` **counts** in `T` under these inputs when one
of these four conditions holds:

1. The source is a `declared-item` of `T` that is in force in `T`
   (`in-force-item`).
2. The source is an `example` object (`object-kind`, `example-block`,
   `canonical-object`) whose parent text declared item (named by its
   `about` edge) is in force in `T` (`in-force-item`).
3. The source is a `conformance-vector-group` of a `vector-set` of `T`,
   and the item of the kind `design` or of the kind `spec` of that
   vector set is in force in `T` (`in-force-item`).
4. The source is a `test` or a `site`.

A cited item of an edge of `T` **counts as retired** in `T` under these
inputs when one of these two conditions holds:

1. The cited item is a `declared-item` of `T` that is not in force in
   `T` (`in-force-item`).
2. The cited item is a `vector-set` of `T`, or a
   `conformance-vector-group` of a `vector-set` of `T`, and the item of
   the kind `design` or of the kind `spec` of that vector set is not in
   force in `T` (`in-force-item`).

Under these inputs, `T` has one finding of the class `retired`
(`finding-part`, with tree `T` and finding class `retired`):

- for each distinct canonical citation edge `e`
  (`<source-content-id> <edge-kind> <target-content-id>`, `content-id`)
  whose source is a `declared-item` of `T` (whose `canonical-object` is
  not withheld) and that meets all four of these conditions:
  1. `e` has kind `cites`, `satisfies`, `verifies`, or `refines`, and
     fits its kind in `T` (`cites-edge`, `satisfies-edge`,
     `verifies-edge`, `refines-edge`);
  2. the source of `e` counts in `T`;
  3. the cited item of `e` counts as retired in `T`;
  4. at least one declared item of `T` whose canonical object equals
     the canonical object of the source of `e` is in force in `T` and is
     not in a `historical-file` of `T` under `H` (a stored declared item
     in `.sinter/` or a declared item from a valid `own-store` is never
     in a historical file);
- for each distinct canonical `cites` edge `e`
  (`example:<32 hex> cites <target-content-id>`, `content-id`) whose
  source is an `example` object of `T` (whose `canonical-object` is not
  withheld) and that meets all four of these conditions:
  1. `e` has kind `cites` and fits its kind in `T` (`cites-edge`);
  2. the source of `e` counts in `T`;
  3. the cited item of `e` counts as retired in `T`;
  4. at least one text declared item of `T` whose `example-block`
     produces that `example` object is in force in `T` and is not in a
     `historical-file` of `T` under `H`;
- for each edge `e` whose source is a `test`, a `site`, or a
  `conformance-vector-group` (from a `vector-line` in a `vector-file`)
  and that meets all four of these conditions:
  1. `e` has kind `cites`, `satisfies`, `verifies`, or `refines`, and
     fits its kind in `T`;
  2. the source of `e` counts in `T`;
  3. the cited item of `e` counts as retired in `T`;
  4. the file of `e` in `T` is not a `historical-file` of `T` under `H`.

The subject and `location` of that finding follow the source of `e`:

- **Declared item or `example` object source:** the subject is the
  `edge-finding-subject` of `e` (such as
  `example:<32 hex> cites <target-content-id>` for an `example` object),
  and the `location` is the object edge location of `e` in `T`
  (`edge-finding-subject`).
- **Test or site source** (from a `citation-entry` or
  `inline-citation`): the subject is the `position-subject` of the
  `origin-position` of that citation entry or inline citation, and the
  `location` is the `slice-location` of its `origin` slice in the text
  of the file of `e`.
- **Group of conformance vectors source** (from a `vector-line` in a
  `vector-file`): the subject is the `position-subject` of the form
  position (`tree-edge`) of `e` in that vector file, and the `location`
  is the `slice-location` of the form slice (`tree-edge`) of `e` in the
  text of that vector file.

The message, mark, related messages, and fix of that finding are chosen
by the program that returns the finding (`finding-part`). That finding
is `ackable` (`ackable-finding`) when, and only when, one of these two
conditions holds:

1. The cited item of `e` is a `declared-item` of `T` and has no
   `successor` in `T` under these inputs.
2. The cited item of `e` is a `vector-set` of `T`, or a
   `conformance-vector-group` of a `vector-set` of `T`, and the item of
   the kind `design` or of the kind `spec` of that vector set has no
   `successor` in `T` under these inputs.

Otherwise, that finding is not ackable.

@example Suppose in-force `billing-2` supersedes `billing`, in-force
`billing-2#limit` supersedes `billing#limit`, and `old-spec` is
[deprecated](sinter:ontology#deprecated-item=v1) with no
[successor](sinter:#successor=v1):

- A trailing [example block](sinter:documents#example-block=v1) on an
  in-force item containing `[limit](sinter:billing#limit=v1)` produces
  one non-ackable `retired` finding with
  [edge finding subject](sinter:documents#edge-finding-subject=v1)
  `example:<32 hex> cites <target-content-id>` and the
  [slice location](sinter:documents#slice-location=v1) of that inline
  citation. The same inline citation inside an example block of a
  retired item, or in a [historical file](sinter:#historical-file=v1),
  produces no `retired` finding.
- A [test](sinter:ontology#test=v1) with `@verifies billing[limits]`
  produces a non-ackable `retired` finding (because `billing` has
  successor `billing-2`), whereas `@verifies old-spec[rows]` produces an
  ackable `retired` finding (because `old-spec` has no successor).
- A stored `cites` edge in `.sinter/` from an in-force item to
  `billing#limit` still produces a `retired` finding even when
  [historical-paths](sinter:#historical-paths=v1) is `["**"]`, because
  no [store file](sinter:object-store#store-file=v1) is ever a
  historical file.

#### Approval completions

@term approval-completion=v1
@cites {
    conformance#own-store=v1,
    identifiers#external-namespaces=v1,
    ontology#{
        item=v1, declared-item=v1, subject-of-approval=v1,
        approval-state=v1, deprecated-item=v1, containment=v1,
        content-id=v1, revised-content=v1, edge=v1, supersedes-edge=v1,
        effective-supersedes-edge=v1, retired-item=v1,
        default-branch=v1, tree=v1, parameter=v1, encoding=v1,
    },
    object-store#tree-object-store=v1,
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
        repository-read=v1,
    },
    documents#{
        file-readers=v1, vector-files=v1, kept-object-set=v1,
        tree-edge=v1, tree-containment=v1,
    },
    approval#{
        approval-kinds=v1, persons=v1, latest-judgment=v1,
        judgment-conflict=v1, merged-content=v1,
        incomplete-first-parent-line=v1,
    },
    #{historical-paths=v1, successor=v1, retired-finding=v1},
}

This term applies for a git repository `R`, a `tree` `T` whose
`tree-object-store` is valid (or a valid `own-store`), valid bindings of
the `parameter`s `approval-kinds` (`A`), `file-readers` (`F`),
`external-namespaces` (`N`), and (when reading `retired` findings)
`vector-files` (`V`), `persons` unbound or bound to a valid binding `L`,
a binding `D` of `default-branch-name` (valid or invalid), a valid
`kept-object-set` `K`, and the `repository-read`s from which a program
reads the `default-branch-commit` of `R` under `D` (when `D` is valid),
its `first-parent-line`, and the files of the trees of its commits
(`commit-file`).

For each `subject-of-approval` `S` of `T` (across both encodings under
`F`, `N`, `K`, and `persons`, or from a valid `own-store`), with
declared-item canonical object `content-id` `t`, `S` is either
**decided** (known approved or known not approved) or **undecided** in
`T` under these inputs for those repository reads:

- When `S` needs approval under `A` (`approval-kinds`), `S` is decided:
  let `J` be the set of latest counting judgments of `t` in `T` under
  `persons` (`latest-judgment`); `S` is known approved when `J` is not
  empty and every element of `J` has kind `"approval"`, and `S` is known
  not approved otherwise (including when `J` is empty or
  `judgment-conflict` holds).
- When `S` does not need approval under `A` and `D` is not a valid
  binding of `default-branch-name`, `S` is undecided.
- When `S` does not need approval under `A`, `D` is a valid binding of
  `default-branch-name`, and the `default-branch` of `R` has no `commit`
  under `D`, `S` is decided and is known not approved.
- When `S` does not need approval under `A`, `D` is a valid binding of
  `default-branch-name`, the default branch of `R` has a commit `d`
  under `D`, and the `first-parent-line` of `d` under `F` is not
  incomplete for those repository reads (`incomplete-first-parent-line`),
  `S` is decided: `S` is known approved when the `revised-content` of
  `S` in `T` merged into the default branch of `R` under `D`, `F`, and
  `N` (`merged-content`), and `S` is known not approved otherwise.
- When `S` does not need approval under `A`, `D` is a valid binding of
  `default-branch-name`, the default branch of `R` has a commit `d`
  under `D`, and the `first-parent-line` of `d` under `F` is incomplete
  for those repository reads (`incomplete-first-parent-line`): `S` is
  decided and is known approved when the `revised-content` of `S` in `T`
  visibly merged in `R` under `D`, `F`, and `N` for those repository
  reads (`incomplete-first-parent-line`); otherwise, `S` is undecided.

An **approval completion** `M` of `T` under these inputs for those
repository reads is an assignment of either `approved` or `not approved`
to each `subject-of-approval` `S` of `T` such that every decided subject
of approval receives its known state and every undecided subject of
approval receives either `approved` or `not approved`.

Under an approval completion `M` (reading declared items, status tags in
text and member `status` in `.sinter/` per `deprecated-item`,
`containment` under `tree-containment`, and citation edges (`tree-edge`)
from both encodings (`encoding`) of `T`):

- A `declared-item` of `T` is **approved under `M`** when it is approved
  under `approval-state`, with each subject of approval of `T` taking
  the state assigned by `M`.
- A `supersedes-edge` of `T` is **effective under `M`** when it meets
  `effective-supersedes-edge`, with approved read as approved under `M`.
- A `declared-item` of `T` is **retired under `M`** when it meets
  `retired-item`, with effective `supersedes` edges read as effective
  under `M`; otherwise it is **in force under `M`** (`retired-item`).
- For a declared item `x` of `T`, a declared item `s` of `T` is a
  **successor of `x` under `M`** by the rules of `successor`, with in
  force, retired, and effective `supersedes` edges read under `M`. A
  declared item of `T` that is in force under `M`, or an `item` of `T`
  that is not a declared item, has no successor under `M`.
- Under a valid binding `H` of `historical-paths`, an `edge` `e` of `T`
  produces a **`retired` finding under `M`** when `e` meets the
  conditions of `retired-finding` with in force read as in force under
  `M`; its subject, its location, and whether it is ackable are those
  that `retired-finding` defines for `e` with in force and successors
  read under `M`.

### Returning successors

@req give-successors=v1
@cites {
    conformance#{
        conforming-program=v1, dependence=v1, reject-invalid-inputs=v1,
        report-missing-parts=v1, give-results-over-canonical-objects=v1,
        read-defined-encodings=v1, own-store=v1,
    },
    identifiers#external-namespaces=v1,
    ontology#{declared-item=v1, edge=v1, tree=v1, parameter=v1},
    object-store#tree-object-store=v1,
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
        repository-read=v1, undisturbed-read=v1,
    },
    documents#{file-readers=v1, kept-object-set=v1},
    approval#{approval-kinds=v1, persons=v1, listed-person=v1},
    #{successor=v1, approval-completion=v1},
}

For a git repository `R`, a `tree` `T` whose `tree-object-store` is
valid (or a valid `own-store`), valid bindings of the `parameter`s
`approval-kinds` (`A`), `file-readers` (`F`), and `external-namespaces`
(`N`), a valid `kept-object-set` `K`, `persons` unbound or bound, and a
binding `D` of `default-branch-name` (valid or invalid), this
requirement applies when a conforming program returns the `successor`s
of a `declared-item` `x` of `T` (`give-results-over-canonical-objects`,
`read-defined-encodings`) and each `repository-read` from which the
program reads the `default-branch-commit` under `D` (when `D` is valid),
its `first-parent-line`, and the files of the trees of its commits
(`commit-file`) is undisturbed (`undisturbed-read`).

When `persons` is unbound or bound to a valid binding `L`, let `C` be
the set of approval completions of `T` under these inputs for those
repository reads (`approval-completion`):

- When every approval completion in `C` produces the same set of
  successors of `x` in `T`, the program must return each item of that
  set once, must return no other item, and must not return that the
  program cannot see the whole history for the successors of `x`.
- When two approval completions in `C` produce different sets of
  successors of `x` in `T`, the program must return no successor of `x`.
  When `D` is a valid binding of `default-branch-name`, the program must
  return that the program cannot see the whole history for the
  successors of `x`; when `D` is invalid, the program must not return
  that the program cannot see the whole history for the successors of
  `x` (`reject-invalid-inputs`).

When `persons` is bound to an invalid value (one that does not meet
`persons`), if every valid binding of `persons` and unbound `persons`
produce the same set of successors of `x` in `T` (under the rules of
this requirement for unbound or valid bindings of `persons`, with no
disagreement across approval completions for any of them), the program
must return each item of that set once, must return no other item, and
must not return that the program cannot see the whole history for the
successors of `x`. Otherwise, the program must return no successor of
`x` (`dependence`, `listed-person`, `reject-invalid-inputs`), must
return that the program cannot see the whole history for the successors
of `x` only when `D` is a valid binding of `default-branch-name` and two
approval completions disagree for every valid binding of `persons` and
for unbound `persons`, and must not return that the program cannot see
the whole history otherwise.

The successors of `x` need (`dependence`, `report-missing-parts`) a
missing part of an `edge` (including an ambiguous pin or a missing
computed identity object under `tree-object-store`) only when the set of
successors of `x` depends on that edge or on the canonical object of an
item that needs that part. When another valid input of the run supplies
a missing computed identity object or its key, the run does not lack
that part.

### Returning `retired` findings

@req give-retired-findings=v1
@cites {
    conformance#{
        conforming-program=v1, dependence=v1, reject-invalid-inputs=v1,
        report-missing-parts=v1, give-results-over-canonical-objects=v1,
        read-defined-encodings=v1, own-store=v1,
    },
    identifiers#external-namespaces=v1,
    data-forms#vector-line=v1,
    ontology#{
        finding-class=v1, edge=v1, vector-set=v1,
        conformance-vector-group=v1, tree=v1, parameter=v1,
    },
    object-store#tree-object-store=v1,
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
        repository-read=v1, undisturbed-read=v1,
    },
    findings#{ackable-finding=v1, finding-part=v1},
    documents#{
        file-readers=v1, vector-files=v1, kept-object-set=v1,
        example-block=v1, canonical-target=v1, canonical-object=v1,
        tree-edge=v1,
    },
    approval#{approval-kinds=v1, persons=v1, listed-person=v1},
    #{historical-paths=v1, retired-finding=v1, approval-completion=v1},
}

For a git repository `R`, a `tree` `T` whose `tree-object-store` is
valid (or a valid `own-store`), valid bindings of the `parameter`s
`approval-kinds` (`A`), `file-readers` (`F`), and `external-namespaces`
(`N`), a valid `kept-object-set` `K`, `persons` unbound or bound, and
bindings `V` of `vector-files`, `H` of `historical-paths`, and `D` of
`default-branch-name` (each valid or invalid), this requirement applies
when a conforming program returns the findings of the `finding-class`
`retired` of `T` (`give-results-over-canonical-objects`,
`read-defined-encodings`) and each `repository-read` from which the
program reads the `default-branch-commit` under `D` (when `D` is valid),
its `first-parent-line`, and the files of the trees of its commits
(`commit-file`) is undisturbed (`undisturbed-read`).

When `H` and `V` are valid and `persons` is unbound or bound to a valid
binding `L`, let `C` be the set of approval completions of `T` under
these inputs for those repository reads (`approval-completion`):

- For each edge `e` (`tree-edge`) of `T` that produces a
  `retired-finding` (`finding-part`) under every approval completion in
  `C` under `H`, the program must return that finding once. When every
  approval completion in `C` agrees on whether that finding is `ackable`
  (`ackable-finding`), that finding has that ackability; when two
  approval completions in `C` disagree on whether that finding is
  ackable, the program must return nothing for whether that finding is
  ackable. The program must return no other finding of the class
  `retired` for `T`.
- When some edge `e` of `T` differs across `C` under `H` (produces a
  `retired` finding under some approval completion in `C` and none under
  another, or produces a `retired` finding under every approval
  completion in `C` whose ackability differs across two approval
  completions in `C`) and `D` is a valid binding of
  `default-branch-name`, the program must return that the program cannot
  see the whole history for the findings of the class `retired` of `T`.
  Otherwise, the program must not return that the program cannot see the
  whole history for the findings of the class `retired` of `T`.

When `H` and `V` are valid and `persons` is bound to an invalid value
(one that does not meet `persons`), the program must return once each
`retired` finding that holds under every valid binding of `persons` and
when `persons` is unbound (under the rules of this requirement for
unbound or valid bindings of `persons`), with its ackability when all of
those agree on whether it is ackable and returning nothing for whether
it is ackable when two of them disagree. The program must return no
finding of the class `retired` whose existence depends on `persons`
(`dependence`, `listed-person`, `reject-invalid-inputs`), and no other
finding of the class `retired` for `T`. The program must return that the
program cannot see the whole history for the findings of the class
`retired` of `T` only when `D` is a valid binding of
`default-branch-name` and some edge differs across approval completions
for every valid binding of `persons` and for unbound `persons`, and must
not return that the program cannot see the whole history otherwise.

When `H` is invalid (does not meet `historical-paths`), a conforming
program must return no finding of the class `retired` for `T` and must
not return that the program cannot see the whole history for the
findings of the class `retired` of `T` (`reject-invalid-inputs`).

Only a finding of the class `retired` for an edge produced by a
`vector-line` or whose cited item is a `vector-set` or a
`conformance-vector-group` depends on (`dependence`) the binding of
`vector-files`. When `V` is invalid, a conforming program must withhold
those `retired` findings (`reject-invalid-inputs`).

When an edge of `T` has a target that is an ambiguous pin or a missing
part (`edge`, `canonical-target`, including a missing computed identity
object under `tree-object-store`), only the findings of the class
`retired` that depend on that edge or on the `canonical-object` of a
declared item or `example` object (`example-block`) that needs that part
need that missing part (`dependence`, `report-missing-parts`); every
other finding of the class `retired` of `T` does not need that part.
When another valid input of the run supplies a missing computed identity
object or its key, the run does not lack that part.

### Limiting offered fixes of `retired` findings

@req limit-retired-fix-edit-sets=v1
@cites {
    conformance#{conforming-program=v1, own-store=v1},
    files#path=v1,
    identifiers#{
        external-namespaces=v1, tag-line=v1, citation=v1,
        citation-entry=v1, inline-citation=v1, tag-line-text=v1,
    },
    data-forms#{vector-line=v1, test-vector-set=v1},
    ontology#{
        item-name=v1, item-revision=v1, same-item=v1, external-item=v1,
        edge=v1, pinned-edge=v1, site=v1, object-kind=v1, tree=v1,
        parameter=v1,
    },
    object-store#{store-file=v1, tree-object-store=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
        repository-read=v1, undisturbed-read=v1,
    },
    findings#{
        location=v1, edit=v1, edit-set=v1, edited-text=v1,
        edited-tree=v1, fix=v1, limit-fix-edit-sets=v1,
        apply-no-fixes-on-unreadable-files=v1,
    },
    documents#{
        file-readers=v1, vector-files=v1, kept-object-set=v1,
        tag-text=v1, accepted-input=v1, example-block=v1,
        unreadable-file=v1, vector-file=v1, tree-edge=v1, origin=v1,
    },
    approval#{approval-kinds=v1, persons=v1},
    text#{character=v1, line=v1, slice=v1, span=v1, code-point-order=v1},
    #{
        historical-paths=v1, successor=v1, retired-finding=v1,
        approval-completion=v1, give-retired-findings=v1,
    },
}

For a git repository `R`, a `tree` `T` whose `tree-object-store` is
valid (or a valid `own-store`), valid bindings of the `parameter`s
`approval-kinds` (`A`), `file-readers` (`F`), `vector-files` (`V`),
`external-namespaces` (`N`), and `historical-paths` (`H`), a valid
`kept-object-set` `K`, `persons` unbound or bound, and a binding `D` of
`default-branch-name` (valid or invalid), this requirement applies when
each `repository-read` from which a conforming program reads the
`default-branch-commit` under `D` (when `D` is valid), its
`first-parent-line`, and the files of the trees of its commits
(`commit-file`) is undisturbed (`undisturbed-read`).

`apply-no-fixes-on-unreadable-files` applies to every `fix` of a
`retired` finding.

For a `retired` finding of `T`, a conforming program must return no
`fix` that holds an `edit` whose `location` has a valid `path` that is a
store path or a local path (`store-file`).

For each `retired` finding `f` (`retired-finding`) of `T` returned for
an edge `E` (`tree-edge`) under `give-retired-findings`:

- When `E` is an edge of a stored declared item in `.sinter/`, when the
  source of `E` comes from a valid `own-store` with no file, or when `f`
  has no `location` (or its location has no `span`), a conforming
  program must return no `fix` for `f`.
- Otherwise (when `f` has a `location` with a `span` in a read file or a
  `vector-file` of `T`), let `c` be the cited item of `E`. When
  `persons` is unbound or bound to a valid binding `L`, let `C` be the
  set of approval completions of `T` under these inputs for those
  repository reads (`approval-completion`); when `persons` is bound to
  an invalid value (one that does not meet `persons`), let `C` be the
  union of those sets of approval completions across every valid binding
  of `persons` and unbound `persons`. When two approval completions in
  `C` produce different sets of `successor`s of `c` in `T`, a conforming
  program must return no `fix` for `f`. When every approval completion
  in `C` produces the same set `S` of successors of `c` in `T`, `S` has
  one or more items, and a conforming program returns a `fix` for `f`,
  that fix must meet all three of these conditions (in addition to
  `limit-fix-edit-sets`):

  1. The fix holds exactly one `edit-set` for each successor in `S`, in
     `code-point-order` of the names (`item-name`) of those successors
     in `T`.
  2. Let `W` be this non-empty set of `slice`s of the text of the file
     of `E` in `T`:
     - when a `citation-entry` produces `E`: the single `origin` slice
       of the `tag-line-text` of the `citation` of `E` in that file's
       text;
     - when an `inline-citation` produces `E`: the single `origin` slice
       of that inline citation in that file's text;
     - when a `vector-line` produces `E`: the form slice (`tree-edge`)
       of each vector line of the group of the vector line of `E` in
       that `vector-file` (`test-vector-set`).

     For each edit set of the fix, every `edit` of that edit set has a
     `location` whose valid `path` is the valid path of the file of `E`
     in `T`, and whose `span` starts and ends at boundaries (`slice`) of
     one slice in `W`.
  3. For each successor `s` in `S`, let `T'` be the `edited-tree` of the
     edit set for `s`, read under `F`, `V`, `N`, `K`, and `persons`, and
     let `t'` be the `edited-text` of the file of `E` for that edit set.
     Because every edit stays inside slices of `W`, the text outside `W`
     remains unchanged. In `T'` under these inputs:
     - when a `citation-entry` produces `E` (with single slice `r` in
       `W`, and `r'` the replacement slice in `t'` between the unchanged
       prefix before `r` and the unchanged suffix after `r`): the file
       of `E` in `T'` is readable (`unreadable-file`), `r'` contains the
       `origin` slice of the `tag-line-text` of one `accepted-input`
       `citation` of that file (the **edited citation**), every
       `character` of `r'` outside that origin slice is a space (U+0020)
       or a tab (U+0009), and no other `tag-line` of any `tag-text` of
       that file has a character index of its `origin` in `r'`;
     - when an `inline-citation` produces `E` (with single slice `r` in
       `W`, and `r'` the replacement slice in `t'` between the unchanged
       prefix before `r` and the unchanged suffix after `r`): the file
       of `E` in `T'` is readable (`unreadable-file`), and `r'` is the
       `origin` slice of one `accepted-input` `inline-citation` of that
       file (the **edited inline citation**);
     - when a `citation-entry` or an `inline-citation` produces `E`, the
       edited citation or edited inline citation in that file produces
       an edge `E'` (`tree-edge`) of the same kind of edge as `E`, whose
       cited item is the `same-item` as `s`, that is pinned
       (`pinned-edge`) with the current revision (`item-revision`) of
       `s` in `T` as its label when `E` is pinned and is not pinned when
       `E` is not pinned, and whose source in `T'` matches the source of
       `E`:
       - when the source of `E` is an item other than a `site`, the
         source of `E'` is the `same-item` as the source of `E`;
       - when the source of `E` is a `site`, the source of `E'` is a
         `site`;
       - when the source of `E` is an `example` object (`object-kind`,
         `example-block`) of a parent text declared item `P` at 1-based
         `index` `i`, the source of `E'` in `T'` is the `example` object
         of a parent text declared item that is the `same-item` as `P`
         at the same 1-based `index` `i`;
     - when a `citation-entry` produces `E`, represent each edge that a
       citation produces by three properties: its kind of edge; its
       pinned label, or that it is not pinned; and its target, which is
       its cited item (up to `same-item`) when the edge has a cited item
       that is not an `external-item`, and is the entry name
       (`citation-entry`) of its citation entry when its cited item is
       an `external-item` or when the edge has no cited item. Taken by
       these three properties, the set of edges that the edited citation
       produces in `T'` equals the set of edges that the citation of `E`
       produced in `T` with `E` replaced by `E'`;
     - when a `vector-line` produces `E`, the content of the
       `vector-file` of `E` in `T'` is a `test-vector-set`, and for each
       vector line `L` of the group of the vector line of `E` in that
       vector file in `T` (with form slice `rL` in `W`, and `rL'` the
       replacement slice on the same 1-based `line` number of `t'`
       between the unchanged prefix of that line before `rL` and the
       unchanged suffix of that line after `rL`), `rL'` is the form
       slice of an edge `EL'` that a vector line of that vector file
       produces in `T'`, where `EL'` has kind `cites`, its source is the
       `same-item` as the source of `E`, its cited item is the
       `same-item` as `s`, and `EL'` is pinned with the current revision
       (`item-revision`) of `s` in `T` as its label.

@example Four cases allow no fix meeting `limit-retired-fix-edit-sets`
(and when a retired item has several successors and even one successor
fails a condition, no fix is allowed):

1. **Form pin outside the vector owner's scope:** in a vector file
   mapped by [vector-files](sinter:documents#vector-files=v1) to design
   `billing`, `"form":"#row=v1"` cannot rewrite to successor schema
   `billing-2#row` in another design; likewise, in a vector file mapped
   to specification `billing#invoices`, `"form":"#row=v1"` cannot
   rewrite to a successor schema held outside `billing#invoices`
   ([edge](sinter:ontology#edge=v1),
   [tree-edge](sinter:documents#tree-edge=v1)). (In a vector file mapped
   to design `billing`, a successor schema held anywhere in `billing`,
   directly or through a specification of `billing`, stays in scope.)
2. **Pinned citation to an unlabeled term:** when `billing#rate=v1` is
   superseded by `@term billing-2#rate` with no
   [current revision](sinter:ontology#item-revision=v1), no edit can
   write a pinned label for `billing-2#rate`.
3. **Successor with a duplicate name:** when two declared items share
   the name `d2`, no edge can cite `d2`
   ([edge](sinter:ontology#edge=v1)).
4. **Stored, own-store, or unlocated finding:** a stored edge in
   `.sinter/` ([store-file](sinter:object-store#store-file=v1)), an edge
   from a valid [own-store](sinter:conformance#own-store=v1), or a
   duplicated canonical edge with no object edge location
   ([edge-finding-subject](sinter:documents#edge-finding-subject=v1))
   has no editable text span.

By contrast, editing a retired
[inline citation](sinter:identifiers#inline-citation=v1) inside a
trailing [example block](sinter:documents#example-block=v1) of parent
item `P` at 1-based `index` 1 changes the anonymous `example` object's
content hash, and still satisfies the source check because the edited
inline citation stays in the `example` object of the
[same parent item](sinter:ontology#same-item=v1) `P` at 1-based `index`
1.

### Test vectors

The groups `successors`, `retired`, and `retired-fixes` are in the
design-level test-vector file
[standing.test-vectors.jsonl](standing.test-vectors.jsonl), a
test-vector set under [test-vectors](sinter:data-forms#test-vectors=v1).
None of the three groups uses `needs` or `result`.

#### Successors vectors

@schema successors-vector=v1
@cites {
    conformance#conforming-program=v1,
    text#{text=v1, decimal-numeral=v1},
    data-forms#{
        index=v1, json-value=v1, vector-line=v1, group-schema=v1,
        vector-meaning=v1,
    },
    identifiers#external-namespaces=v1,
    ontology#{
        declared-item=v1, containment=v1, item-name=v1, edge=v1,
        supersedes-edge=v1, effective-supersedes-edge=v1,
        retired-item=v1, default-branch=v1, tree=v1,
    },
    object-store#tree-object-store=v1,
    changes#{
        default-branch-name=v1, default-branch-commit=v1,
        first-parent-line=v1, repository-read=v1, undisturbed-read=v1,
    },
    documents#file-readers=v1,
    approval#{
        approval-kinds=v1, persons=v1, in-force-item=v1,
        incomplete-first-parent-line=v1,
    },
    #{successor=v1, give-successors=v1},
}

`successors-vector` is a `group-schema` for group `successors` and tests
`give-successors`. Each line is a `vector-line` (with `json-value`
strings as `text`s and integers as `decimal-numeral`s) whose meaning
follows `vector-meaning`. Each vector stands for undisturbed
`repository-read`s (`undisturbed-read`) over a git repository whose
`default-branch` `first-parent-line` (when the default branch has a
`default-branch-commit`) is not incomplete
(`incomplete-first-parent-line`), a `tree` with a valid
`tree-object-store`, `persons` unbound, and valid bindings of
`approval-kinds`, `default-branch-name`, `file-readers`, and
`external-namespaces`.

| field | type | meaning |
|---|---|---|
| `input.items` | array of objects | `declared-item`s of the tree in sequence |
| `input.items[].name` | string | `item-name` of the declared item |
| `input.items[].kind` | string | declared-item kind: `"design"`, `"spec"`, `"schema"`, `"req"`, `"atom"`, `"term"`, or `"decision"` |
| `input.items[].in-force` | boolean | `true` when in force (`in-force-item`), `false` when retired (`retired-item`) |
| `input.items[].design` | string (optional) | `item-name` of the `design` that holds the item (`containment`); absent when no design holds the item |
| `input.edges` | array of objects | `supersedes-edge`s of the tree that fit their kind (`edge`) |
| `input.edges[].source` | integer (`>= 1`) | 1-based `index` of the source in `input.items` |
| `input.edges[].cited` | integer (`>= 1`) | 1-based `index` of the cited item in `input.items` |
| `input.edges[].effective` | boolean | `true` when effective (`effective-supersedes-edge`), `false` otherwise |
| `input.target` | integer (`>= 1`) | 1-based `index` in `input.items` of the declared item whose successors are queried |
| `values.successors` | array of integers | 1-based `index` values in `input.items` of the `successor`s of `input.target`, each once, in increasing numerical order |

Each object in `input` and `values` holds only the members listed in
this table. When a `conforming-program` returns the successors of
`input.target` under `give-successors`, the program returns the declared
item at each index in `values.successors` once and returns no other
item.

@example Sample lines testing
[give-successors](sinter:#give-successors=v1) and
[successor](sinter:#successor=v1) on a diamond and on a cycle inside a
retired design with an in-force exit
([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#successors-vector=v1","group":"successors","input":{"edges":[{"cited":1,"effective":true,"source":2},{"cited":1,"effective":true,"source":3},{"cited":2,"effective":true,"source":4},{"cited":3,"effective":true,"source":4}],"items":[{"in-force":false,"kind":"decision","name":"d1"},{"in-force":false,"kind":"decision","name":"d2"},{"in-force":false,"kind":"decision","name":"d3"},{"in-force":true,"kind":"decision","name":"d4"}],"target":1},"note":"diamond reports the single final successor once","values":{"successors":[4]}}
{"form":"#successors-vector=v1","group":"successors","input":{"edges":[{"cited":1,"effective":true,"source":4},{"cited":3,"effective":true,"source":2},{"cited":2,"effective":true,"source":3},{"cited":3,"effective":true,"source":5}],"items":[{"in-force":false,"kind":"design","name":"old"},{"design":"old","in-force":false,"kind":"req","name":"old#p"},{"design":"old","in-force":false,"kind":"req","name":"old#q"},{"in-force":true,"kind":"design","name":"new"},{"design":"new","in-force":true,"kind":"req","name":"new#q"}],"target":2},"note":"cycle inside a retired design with an exit reaches the in-force exit","values":{"successors":[5]}}
```

#### Retired finding vectors

@schema retired-vector=v1
@cites {
    conformance#{conforming-program=v1, own-store=v1},
    text#{text=v1, code-point-order=v1},
    files#{path=v1, path-set=v1},
    data-forms#{
        json-value=v1, vector-line=v1, group-schema=v1,
        vector-meaning=v1,
    },
    identifiers#external-namespaces=v1,
    ontology#{
        declared-item=v1, edge=v1, vector-set=v1,
        conformance-vector-group=v1, test=v1, site=v1,
        external-item=v1, object-kind=v1, default-branch=v1, tree=v1,
        finding-class=v1,
    },
    object-store#{store-file=v1, tree-object-store=v1},
    changes#{
        default-branch-name=v1, default-branch-commit=v1,
        first-parent-line=v1, repository-read=v1, undisturbed-read=v1,
    },
    findings#{ackable-finding=v1, finding-part=v1},
    documents#{
        file-readers=v1, vector-files=v1, example-block=v1,
        tree-edge=v1, position-subject=v1, edge-finding-subject=v1,
    },
    approval#{
        approval-kinds=v1, persons=v1, in-force-item=v1,
        incomplete-first-parent-line=v1,
    },
    #{
        historical-paths=v1, successor=v1, retired-finding=v1,
        give-retired-findings=v1,
    },
}

`retired-vector` is a `group-schema` for group `retired` and tests
`give-retired-findings`. Each line is a `vector-line` (with `json-value`
strings as `text`s) whose meaning follows `vector-meaning`. Each vector
stands for undisturbed `repository-read`s (`undisturbed-read`) over a
git repository whose `default-branch` `first-parent-line` (when the
default branch has a `default-branch-commit`) is not incomplete
(`incomplete-first-parent-line`), a `tree` with a valid
`tree-object-store` (or a valid `own-store`), `persons` unbound, and
valid bindings of `approval-kinds`, `default-branch-name`,
`file-readers`, `vector-files`, and `external-namespaces`.

| field | type | meaning |
|---|---|---|
| `input.historical-paths` | array of strings | binding of `historical-paths` (`path-set`), holding its path set members in order (valid or invalid) |
| `input.edges` | array of objects | citation edges of the tree (`tree-edge`) |
| `input.edges[].kind` | string | edge kind: `"cites"`, `"satisfies"`, `"verifies"`, `"refines"`, or `"supersedes"` |
| `input.edges[].fits` | boolean | `true` when the edge fits its kind (`edge`), `false` otherwise |
| `input.edges[].source-kind` | string | `"declared"` for a `declared-item`, `"example"` for an `example` object (`object-kind`, `example-block`), `"group"` for a `conformance-vector-group`, and `"other"` for a `test` or `site` |
| `input.edges[].source-in-force` | boolean (optional) | present when `source-kind` is `"declared"`, `"example"`, or `"group"` (absent for `"other"`): `true` when that declared item, the parent text declared item of that `example` object, or the `design` or `spec` of that group's `vector-set` is in force (`in-force-item`), `false` otherwise |
| `input.edges[].cited-kind` | string | `"declared"` for a `declared-item`, `"group"` for a `conformance-vector-group`, `"vector-set"` for a `vector-set`, and `"external"` for an `external-item` or when the edge has no cited item |
| `input.edges[].cited-in-force` | boolean (optional) | present when `cited-kind` is `"declared"`, `"group"`, or `"vector-set"` (absent for `"external"`): `true` when that declared item, or the `design` or `spec` of that vector set (for `"group"`, the group's vector set), is in force (`in-force-item`), `false` otherwise |
| `input.edges[].cited-has-successor` | boolean (optional) | present when `cited-kind` is `"declared"`, `"group"`, or `"vector-set"` (absent for `"external"`): `true` when that declared item, or the `design` or `spec` of that vector set, has one or more `successor`s, `false` otherwise |
| `input.edges[].path` | string (optional) | valid `path` of the file of the edge: present for `"example"`, `"group"`, and `"other"`, and for `"declared"` when the source stands in a text file or a valid object file of `.sinter/` (`store-file`); absent when a `"declared"` source comes from a valid `own-store` with no file |
| `input.edges[].subject` | string | `edge-finding-subject` when `source-kind` is `"declared"` or `"example"`, or `position-subject` when `source-kind` is `"group"` or `"other"` |
| `values.findings` | array of objects (optional) | present when `input.historical-paths` is a valid `path-set` (one element per `retired-finding` of the tree, in `code-point-order` of `subject`); absent (`values` is `{}`) when `input.historical-paths` is invalid |
| `values.findings[].subject` | string | finding subject (`finding-part`) |
| `values.findings[].ackable` | boolean | `true` when the finding is `ackable` (`ackable-finding`), `false` otherwise |

Each object in `input` and `values` holds only the members listed in
this table. When `values` is `{}`, a `conforming-program` returns no
finding of the `finding-class` `retired` for the tree. When `values` is
not `{}` and a conforming program returns the `retired` findings of the
tree under `give-retired-findings`, the program returns one `retired`
finding per element of `values.findings`, with its `subject` and
`ackable` value, and returns no other finding of that class.

@example Sample lines testing
[give-retired-findings](sinter:#give-retired-findings=v1) and
[retired-finding](sinter:#retired-finding=v1) on an `example` object
source ([example-block](sinter:documents#example-block=v1)) and on an
invalid [historical-paths](sinter:#historical-paths=v1) binding
([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#retired-vector=v1","group":"retired","input":{"edges":[{"cited-has-successor":true,"cited-in-force":false,"cited-kind":"declared","fits":true,"kind":"cites","path":"docs/guide.md","source-in-force":true,"source-kind":"example","subject":"example:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee cites req:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}],"historical-paths":[]},"note":"inline citation inside an example block of an in-force item to a retired item gives a finding","values":{"findings":[{"ackable":false,"subject":"example:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee cites req:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}]}}
{"form":"#retired-vector=v1","group":"retired","input":{"edges":[{"cited-has-successor":true,"cited-in-force":false,"cited-kind":"declared","fits":true,"kind":"cites","path":"docs/guide.md","source-kind":"other","subject":"docs/guide.md@L3C1"}],"historical-paths":["!docs/archive/**"]},"note":"invalid historical-paths binding gives empty values","values":{}}
```

#### Offered fix vectors

@schema retired-fix-vector=v1
@cites {
    conformance#{conforming-program=v1, own-store=v1},
    text#{text=v1, decimal-numeral=v1, slice=v1, code-point-order=v1},
    files#path=v1,
    data-forms#{
        json-value=v1, vector-line=v1, test-vector-set=v1,
        group-schema=v1, vector-meaning=v1,
    },
    identifiers#{
        external-namespaces=v1, citation=v1, citation-entry=v1,
        inline-citation=v1, tag-line-text=v1,
    },
    ontology#{
        declared-item=v1, containment=v1, item-name=v1,
        item-revision=v1, edge=v1, pinned-edge=v1, vector-set=v1,
        default-branch=v1, tree=v1,
    },
    object-store#{store-file=v1, tree-object-store=v1},
    changes#{
        default-branch-name=v1, default-branch-commit=v1,
        first-parent-line=v1, repository-read=v1, undisturbed-read=v1,
    },
    findings#{location=v1, edit=v1, edit-set=v1, fix=v1},
    documents#{
        file-readers=v1, vector-files=v1, tree-edge=v1, origin=v1,
    },
    approval#{
        approval-kinds=v1, persons=v1, incomplete-first-parent-line=v1,
    },
    #{
        historical-paths=v1, successor=v1, retired-finding=v1,
        limit-retired-fix-edit-sets=v1,
    },
}

`retired-fix-vector` is a `group-schema` for group `retired-fixes` and
tests `limit-retired-fix-edit-sets`. Each line is a `vector-line` (with
`json-value` strings as `text`s and boundaries as `decimal-numeral`s)
whose meaning follows `vector-meaning`. Each vector stands for
undisturbed `repository-read`s (`undisturbed-read`) over a git
repository whose `default-branch` `first-parent-line` (when the default
branch has a `default-branch-commit`) is not incomplete
(`incomplete-first-parent-line`), a `tree` with a valid
`tree-object-store`, `persons` unbound, and valid bindings of
`approval-kinds`, `default-branch-name`, `file-readers`, `vector-files`,
`external-namespaces`, and `historical-paths` (under which the file of
edge `E` is not historical), for a `retired-finding` whose cited item
has one or more `successor`s.

| field | type | meaning |
|---|---|---|
| `input.origin-kind` | string | `"citation-entry"`, `"inline-citation"`, `"vector-line"`, `"stored"`, or `"store"` |
| `input.path` | string (optional) | valid `path` of the file of edge `E` (a store path under `store-file` when `origin-kind` is `"stored"`); absent when `origin-kind` is `"store"` (an `own-store` source) |
| `input.text` | string (optional) | `text` of that file in the tree; present when `origin-kind` is `"citation-entry"`, `"inline-citation"`, or `"vector-line"`, absent otherwise |
| `input.edge-kind` | string | `"cites"`, `"satisfies"`, `"verifies"`, or `"refines"` |
| `input.pinned` | boolean | `true` when `E` is pinned (`pinned-edge`), `false` otherwise |
| `input.slice` | object (optional) | present when `origin-kind` is `"citation-entry"`, `"inline-citation"`, or `"vector-line"`, absent otherwise: `slice` in `input.text` with non-negative integer boundaries `from` and `to` (`origin` slice of the citation's `tag-line-text` for `"citation-entry"`, of the `inline-citation` for `"inline-citation"`, or the form slice under `tree-edge` for `"vector-line"`) |
| `input.cited` | string | `item-name` of the retired cited item of `E` |
| `input.successors` | array of objects | one or more `successor`s of `input.cited` |
| `input.successors[].name` | string | `item-name` of the successor |
| `input.successors[].kind` | string | declared-item kind (`declared-item`): `"design"`, `"spec"`, `"schema"`, `"req"`, `"atom"`, `"term"`, or `"decision"` |
| `input.successors[].duplicate` | boolean | `true` when two or more declared items of the tree share its name (so no edge has it as its cited item under `edge`), `false` otherwise |
| `input.successors[].label` | string (optional) | current revision (`item-revision`) of the successor; absent when it is a `term` with no label |
| `input.successors[].in-vector-owner` | boolean (optional) | present when `origin-kind` is `"vector-line"`, absent otherwise: for a `vector-set` of a `design` `D`, `true` when the successor is a `schema` that `D` holds (`containment`, directly or through a `spec` that belongs to `D`) and `false` otherwise; for a `vector-set` of a `spec` `S`, `true` when the successor is a `schema` that `S` holds (`containment`) and `false` otherwise |
| `values.fix-allowed` | boolean | `true` when a `fix` meeting `limit-retired-fix-edit-sets` exists, `false` otherwise |
| `values.edit-sets` | array of objects (optional) | present when `values.fix-allowed` is `true`, absent otherwise: one element per successor in `code-point-order` of successor names |
| `values.edit-sets[].successor` | string | successor's `item-name` |
| `values.edit-sets[].pinned` | boolean | `true` when the replacement edge `E'` is pinned, `false` otherwise |
| `values.edit-sets[].label` | string (optional) | present when `values.edit-sets[].pinned` is `true`: the current revision pinned by `E'` |
| `values.edit-sets[].path` | string | valid `path` within which every `edit` of that `edit-set` has its `location` |
| `values.edit-sets[].slices` | array of objects | one or more `slice` objects (`from` and `to` boundaries in `input.text`, in increasing numerical order of `from`) bounding every edit of that edit set |

Each object in `input` and `values` holds only the members listed in
this table. When `values.fix-allowed` is `false`, a `conforming-program`
returns no fix for the `retired` finding. When `values.fix-allowed` is
`true`, returning a fix is optional; any fix that a conforming program
returns holds one `edit-set` per element of `values.edit-sets` in the
same order, edits only `path` within the slices of `slices`, produces in
its edited tree the replacement edge `E'` to `successor` (for every
vector line of the group in the `test-vector-set` when `origin-kind` is
`"vector-line"`, pinned with `label` when `pinned` is `true` and
unpinned otherwise), and keeps every other edge of the `citation`
(`citation-entry`).

@example Sample lines testing
[limit-retired-fix-edit-sets](sinter:#limit-retired-fix-edit-sets=v1) on
an [inline citation](sinter:identifiers#inline-citation=v1) inside an
[example block](sinter:documents#example-block=v1) and on a
[vector line](sinter:data-forms#vector-line=v1) form pin in a linked
vector file ([vector-files](sinter:documents#vector-files=v1)):

```json
{"form":"#retired-fix-vector=v1","group":"retired-fixes","input":{"cited":"billing#limit","edge-kind":"cites","origin-kind":"inline-citation","path":"docs/guide.md","pinned":true,"slice":{"from":30,"to":62},"successors":[{"duplicate":false,"kind":"req","label":"v1","name":"billing-2#limit"}],"text":"@req #r=v1\nBody.\n@example See [limit](sinter:billing#limit=v1).\n"},"note":"inline citation inside an example block allows a fix bounded to its inline-citation slice","values":{"edit-sets":[{"label":"v1","path":"docs/guide.md","pinned":true,"slices":[{"from":30,"to":62}],"successor":"billing-2#limit"}],"fix-allowed":true}}
{"form":"#retired-fix-vector=v1","group":"retired-fixes","input":{"cited":"billing#old","edge-kind":"cites","origin-kind":"vector-line","path":"vectors/billing-cases.jsonl","pinned":true,"slice":{"from":9,"to":16},"successors":[{"duplicate":false,"in-vector-owner":true,"kind":"schema","label":"v1","name":"billing#new"}],"text":"{\"form\":\"#old=v1\",\"group\":\"g\",\"input\":{},\"values\":{}}\n"},"note":"vector line form pin in a linked vector file without a test-vectors filename allows a fix","values":{"edit-sets":[{"label":"v1","path":"vectors/billing-cases.jsonl","pinned":true,"slices":[{"from":9,"to":16}],"successor":"billing#new"}],"fix-allowed":true}}
```

## Edge cycles

@spec cycles=v1

Replacement (`supersedes`) and specialization (`refines`) edges link
declared items across the text and `.sinter/` encodings of a tree. A
`cycle` finding reports a loop that those edges form.

### Definitions

#### Cycle findings

@atom cycle-finding=v1
@cites {
    conformance#own-store=v1,
    text#code-point-order=v1,
    files#path=v1,
    identifiers#{
        external-namespaces=v1, declaration=v1, tag-line-text=v1,
    },
    ontology#{
        declared-item=v1, item-name=v1, edge=v1, supersedes-edge=v1,
        refines-edge=v1, object-withdrawal=v1, tree=v1, parameter=v1,
        encoding=v1,
    },
    object-store#{valid-object-file=v1, tree-object-store=v1},
    findings#location=v1,
    documents#{
        file-readers=v1, kept-object-set=v1, item-file=v1, tree-edge=v1,
        origin=v1, slice-location=v1, tree-finding=v1,
    },
    approval#{persons=v1, listed-person=v1},
    #{historical-paths=v1, historical-file=v1},
}

This atom applies to a `tree` `T` with a valid `tree-object-store` (or a
valid `own-store`), valid bindings of the `parameter`s `file-readers`,
`external-namespaces`, and `historical-paths`, a valid `kept-object-set`,
and `persons` unbound or bound to a valid binding (`approval#persons`).
Under those inputs, the `declared-item`s of `T` are its declared items
across both `encoding`s under `item-file`, or come from a valid
`own-store`. The binding of `persons` (`listed-person`) decides which
`"void"` statements count under `object-withdrawal`.

A pair `(x, y)` of `declared-item`s of `T` (including when `x` and `y`
are the same declared item) is a **cycle step** in `T` when, and only
when, some `tree-edge` of `T` whose cited item is not withheld
(`tree-edge`) is of the kind `supersedes` (`supersedes-edge`) or
`refines` (`refines-edge`), fits its kind (`ontology#edge`), and has `x`
as its source and `y` as its cited item.

A `declared-item` `a` of `T` **reaches** a `declared-item` `b` of `T`
along cycle steps when a finite sequence of one or more cycle steps of
`T` has `a` as the first item of its first pair, has `b` as the second
item of its last pair, and has the second item of each pair before the
last equal to the first item of the next pair.

An **edge cycle** in `T` under those inputs is a non-empty set `C` of
`declared-item`s of `T` that meets both of these conditions:

1. For every `declared-item` `a` in `C` and every `declared-item` `b` in
   `C` (including when `a` and `b` are the same declared item), `a`
   reaches `b` along cycle steps in `T`.
2. No set of `declared-item`s of `T` that holds every `declared-item` of
   `C` and at least one other `declared-item` of `T` meets condition 1.

The **anchor member** of an edge cycle `C` in `T` is the `declared-item`
of `C` whose `item-name` in `T` comes first in `code-point-order` among
the names of all `declared-item`s of `C`.

Under those inputs, `T` has one `tree-finding` of the class `cycle` for
each edge cycle `C` in `T` whose anchor member `d` does not stand in a
`historical-file` of `T` under the binding of `historical-paths`. The
subject of that `tree-finding` is the `item-name` of `d` in `T`. The
`location` of that `tree-finding` follows the input from which `d`
comes:

- when `d` is a text `declared-item` in `T` (`item-file`): the
  `slice-location` of the `origin` slice of the `tag-line-text` of the
  `declaration` of `d` in the text of the file of `d` in `T`;
- when `d` is a stored `declared-item` in `.sinter/` of `T`
  (`item-file`): the valid `path` of the `valid-object-file` of `d` in
  `T` alone, with no span;
- when `d` comes from a valid `own-store` with no file in `T`: no
  location.

@example Two scenarios illustrate cycle merging and historical-anchor
handling:

1. Decision records `a` and `b` supersede each other
   ([supersedes-edge](sinter:ontology#supersedes-edge=v1)) while `b` and
   `c` refine each other
   ([refines-edge](sinter:ontology#refines-edge=v1)). Every member of
   `{a, b, c}` reaches every other member along cycle steps, so they
   form one maximal edge cycle and produce one `cycle`
   [tree finding](sinter:documents#tree-finding=v1) with subject `a`.
2. Requirements `old#p` and `old#q` supersede each other, making `old#p`
   the anchor member in
   [code-point order](sinter:text#code-point-order=v1). When `old#p`
   stands in a [historical file](sinter:#historical-file=v1) under
   [historical-paths](sinter:#historical-paths=v1) and `old#q` does not,
   the cycle produces no `cycle` finding. When only `old#q` stands in a
   historical file, the tree still has one `cycle` finding anchored at
   `old#p`. When `old#p` is a stored
   [declared item](sinter:ontology#declared-item=v1) in a
   [valid object file](sinter:object-store#valid-object-file=v1) of
   `.sinter/`, `historical-paths` never makes that file historical, and
   the finding carries that valid [path](sinter:files#path=v1) alone as
   its [location](sinter:findings#location=v1).

### Returning cycle findings

@req give-cycle-findings=v1
@cites {
    conformance#{
        conforming-program=v1, dependence=v1, reject-invalid-inputs=v1,
        report-missing-parts=v1, give-results-over-canonical-objects=v1,
        read-defined-encodings=v1, own-store=v1,
    },
    identifiers#external-namespaces=v1,
    ontology#{
        finding-class=v1, declared-item=v1, computed-identity=v1,
        object-withdrawal=v1, edge=v1, tree=v1, parameter=v1,
    },
    object-store#tree-object-store=v1,
    findings#location=v1,
    documents#{
        file-readers=v1, kept-object-set=v1, canonical-target=v1,
        canonical-object=v1, tree-finding=v1,
    },
    approval#{persons=v1, listed-person=v1},
    #{historical-paths=v1, cycle-finding=v1},
}

This requirement applies for a `tree` `T` with a valid
`tree-object-store` (or a valid `own-store`), valid bindings of the
`parameter`s `file-readers` and `external-namespaces`, a valid
`kept-object-set`, a binding of `historical-paths` (valid or invalid),
and `persons` unbound or bound (`approval#persons`).

When a `conforming-program` returns the findings of the `finding-class`
`cycle` of `T` under those inputs (`give-results-over-canonical-objects`,
`read-defined-encodings`):

- When `historical-paths` is bound to a valid binding and `persons` is
  unbound or bound to a valid binding, the program must return once each
  `cycle-finding` (`tree-finding`) that `T` has under those inputs, and
  must return no other finding of the class `cycle`.
- When `historical-paths` is bound to a valid binding and `persons` is
  bound to a value that does not meet `approval#persons`, the program
  must return once each `cycle` finding of `T` whose existence and
  `location` (including having no location) do not depend on `persons`
  (`dependence`, `listed-person`, `object-withdrawal`), and must return
  no other finding of that class (`reject-invalid-inputs`).
- When `historical-paths` is bound to a value that does not meet
  `historical-paths`, the program must return no finding of the class
  `cycle` for `T` (`reject-invalid-inputs`).

A `cycle` finding needs (`dependence`, `report-missing-parts`) a missing
part of an `edge` (`ontology#edge`, `canonical-target`, including an
ambiguous pin or a missing `computed-identity` object under
`tree-object-store`) only when the existence or `location` of that
finding depends on that edge or on the `canonical-object` of a
`declared-item` that needs that part; every other `cycle` finding of `T`
does not need that part. When another valid input of the run supplies a
missing `computed-identity` object or its key (`canonical-target`), the
run does not lack that part.

### Test vectors

@schema cycles-vector=v1
@cites {
    conformance#{conforming-program=v1, own-store=v1},
    text#{text=v1, code-point-order=v1, position=v1, span=v1},
    files#{path=v1, path-set=v1},
    data-forms#{
        index=v1, json-value=v1, vector-line=v1, test-vector-set=v1,
        group-schema=v1, vector-meaning=v1,
    },
    identifiers#{
        external-namespaces=v1, declaration=v1, tag-line-text=v1,
    },
    ontology#{
        declared-item=v1, item-name=v1, object-kind=v1, content-id=v1,
        edge=v1, supersedes-edge=v1, refines-edge=v1, tree=v1,
    },
    object-store#{object-path=v1, store-file=v1, tree-object-store=v1},
    findings#{finding-subject=v1, location=v1},
    documents#{
        file-readers=v1, kept-object-set=v1, canonical-object=v1,
        tree-edge=v1, origin-position=v1,
    },
    approval#persons=v1,
    #{historical-paths=v1, cycle-finding=v1, give-cycle-findings=v1},
}

`cycles-vector` is a `group-schema` for group `cycles` in the
design-level test-vector file
[standing.test-vectors.jsonl](standing.test-vectors.jsonl) and tests
`give-cycle-findings`. That file is a `test-vector-set` of `vector-line`
entries whose meaning follows `vector-meaning`. Group `cycles` uses no
`needs` and omits `result`. Each vector stands for a `tree` with a valid
`tree-object-store` (or a valid `own-store`), `persons` unbound
(`approval#persons`), valid bindings of `file-readers` and
`external-namespaces`, and a valid `kept-object-set`, where no other
process changes the inputs during the run, and `input.items` and
`input.edges` hold the `declared-item`s and the `supersedes` and
`refines` `tree-edge`s of that tree.

| field | type | meaning |
|---|---|---|
| `input.historical-paths` | array of strings | binding of `historical-paths`, as a `path-set` of `text` members in order |
| `input.items` | array of objects | `declared-item`s of the `tree`, indexed from `1` (`index`) |
| `input.items[].name` | string | `item-name` of the declared item |
| `input.items[].kind` | string | declared item kind (`"design"`, `"spec"`, `"schema"`, `"req"`, `"atom"`, `"term"`, or `"decision"`, matching the object kind word of `id` under `object-kind`) |
| `input.items[].id` | string | `content-id` of the `canonical-object` of the declared item |
| `input.items[].path` | string (optional) | valid `path` of the file of the declared item (an `object-path` matching `id` when a store path under `store-file`, and never a local path); absent when the item comes from a valid `own-store` with no file |
| `input.items[].line` | integer (`>= 1`, optional) | 1-based line number of the `origin-position` of the `tag-line-text` of the `declaration` of the item; present with `column` when, and only when, `path` is present and is not a store path (`store-file`) |
| `input.items[].column` | integer (`>= 1`, optional) | 1-based column of that `origin-position`; present with `line` under the same condition |
| `input.edges` | array of objects | `supersedes` (`supersedes-edge`) and `refines` (`refines-edge`) `tree-edge`s of the tree |
| `input.edges[].kind` | string | `"supersedes"` or `"refines"` |
| `input.edges[].fits` | boolean | `true` when the edge fits its kind (`ontology#edge`) in the tree, `false` otherwise |
| `input.edges[].source` | integer (`>= 1`) | 1-based `index` in `input.items` of the source of the edge |
| `input.edges[].cited` | integer (`>= 1`) | 1-based `index` in `input.items` of the cited item of the edge |
| `values.findings` | array of objects (optional) | present when `input.historical-paths` is a valid `path-set` (one element per `cycle` finding of the tree (`cycle-finding`), in `code-point-order` of `subject`); absent (`values` is `{}`) when `input.historical-paths` is invalid |
| `values.findings[].subject` | string | `finding-subject` of the finding |
| `values.findings[].path` | string (optional) | valid `path` of the finding's `location`; absent when the finding has no location |
| `values.findings[].line` | integer (`>= 1`, optional) | 1-based line number of the start `position` of the finding's `location`; present with `column` when, and only when, that location has a `span` |
| `values.findings[].column` | integer (`>= 1`, optional) | 1-based column of the start `position` of the finding's `location`; present with `line` when, and only when, that location has a `span` |

Each `json-value` object in `input` and `values` holds only the members
listed in this table, and each JSON string represents a `text`.

When `values` is `{}`, a `conforming-program` returns no finding of the
class `cycle` for the tree under `give-cycle-findings`. When `values` is
not `{}` and a conforming program returns findings of the class `cycle`
of the tree under those bindings, the program returns one finding of
that class for each element of `values.findings`, with its `subject`,
and no other finding of that class; when the program returns a finding's
`location`, that location has the `path` (and start `position` given by
`line` and `column` when present, or no `span` when `line` and `column`
are absent) that the element states, and no location when `path` is
absent.

@example Sample lines testing
[give-cycle-findings](sinter:#give-cycle-findings=v1) and
[cycle-finding](sinter:#cycle-finding=v1) on a mixed
[supersedes](sinter:ontology#supersedes-edge=v1) and
[refines](sinter:ontology#refines-edge=v1) cycle and on an invalid
binding of [historical-paths](sinter:#historical-paths=v1)
([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#cycles-vector=v1","group":"cycles","input":{"edges":[{"cited":2,"fits":true,"kind":"supersedes","source":1},{"cited":1,"fits":true,"kind":"refines","source":2}],"historical-paths":[],"items":[{"column":1,"id":"req:000000000000000000000000000001cd","kind":"req","line":5,"name":"d#r1","path":"docs/d.md"},{"column":1,"id":"req:000000000000000000000000000001ce","kind":"req","line":12,"name":"d#r2","path":"docs/d.md"},{"column":1,"id":"design:000000000000000000000000000001cf","kind":"design","line":2,"name":"d","path":"docs/d.md"}]},"note":"mixed cycle of one supersedes edge and one refines edge","values":{"findings":[{"column":1,"line":5,"path":"docs/d.md","subject":"d#r1"}]}}
{"form":"#cycles-vector=v1","group":"cycles","input":{"edges":[{"cited":1,"fits":true,"kind":"supersedes","source":1}],"historical-paths":["docs/**","docs/**"],"items":[{"column":1,"id":"decision:00000000000000000000000000000227","kind":"decision","line":2,"name":"d1","path":"docs/d1.md"}]},"note":"invalid historical-paths binding gives empty values","values":{}}
```

## Label and decision permanence

@spec history-guarantees=v1

Decision records document standing choices and practices of a
repository, so authors revise or supersede a decision record instead of
deleting it. Comparing a tree against a base tree flags decision records
whose names disappeared from the shared set.

Revision labels tie pinned citations to one revised content of a
declared item. Comparing a tree against a base tree and earlier trees
from the default branch flags items that adopt a label previously used
for a different kind or different content.

### Definitions

#### Findings of the class `deleted-decision`

@atom deleted-decision-finding=v1
@cites {
    conformance#own-store=v1,
    identifiers#external-namespaces=v1,
    ontology#{
        declared-item=v1, item-name=v1, same-item=v1,
        object-withdrawal=v1, computed-identity=v1, tree=v1,
        parameter=v1, encoding=v1,
    },
    object-store#tree-object-store=v1,
    findings#location=v1,
    documents#{file-readers=v1, item-file=v1, name-set=v1, tree-finding=v1},
    approval#{persons=v1, listed-person=v1},
    text#text=v1,
    #historical-paths=v1,
}

This atom is for a `tree` `T`, a base `tree` `B`, valid bindings of the
`parameter`s `file-readers` and `external-namespaces`, and `persons`
unbound or bound to a valid binding. The `declared-item`s, their kinds,
their `item-name`s, and the `name-set`s of `T` and `B` are those that
`T` and `B` hold under those bindings (`item-file`, `listed-person`,
`object-withdrawal`), across the text `encoding` and the `.sinter/`
encoding (when each tree's `tree-object-store` is valid), or from valid
`own-store`s. A `computed-identity` object (such as a `"name"` object in
`.sinter/`) is not a `declared-item` and never enters the shared set of
`T`. A decision record (`declared-item` of kind `"decision"`) stored in
`.sinter/` of `B` that a counting void withdraws in `T`
(`object-withdrawal`, under `listed-person`) is not a declared item of
`T`.

Under those inputs, `T` has one `tree-finding` of the class
`deleted-decision` against `B` for each `text` `t` that is the
`item-name` in `B` of a decision record of `B` such that no
`declared-item` in the shared set (`name-set`) of `T` (of any kind and
in either encoding, `same-item`) has an `item-name` in `T` equal to `t`.

The subject of that `tree-finding` is `t`. That `tree-finding` has no
`location`. The `deleted-decision` findings of `T` against `B` do not
depend on `historical-paths`.

@example When a change deletes the text file of
`@decision rust-bridge=v1`, withdraws a `.sinter/` decision record
`rust-bridge` with a counting void
([object-withdrawal](sinter:ontology#object-withdrawal=v1)), or leaves
its file with invalid UTF-8 content, the tree has one `deleted-decision`
finding with subject `rust-bridge` and no
[location](sinter:findings#location=v1). A leftover `"name"`
[computed identity](sinter:ontology#computed-identity=v1) object in
`.sinter/` is not a [declared item](sinter:ontology#declared-item=v1)
and never keeps `rust-bridge` in the shared set
([name-set](sinter:documents#name-set=v1)). By contrast, moving a
decision record between directories or between the text
[encoding](sinter:ontology#encoding=v1) and `.sinter/`, or replacing
`@decision x=v1` with `@req x=v1` in the shared set
([same-item](sinter:ontology#same-item=v1)), keeps the name in the
shared set and produces no `deleted-decision` finding.

#### Items with new labels

@term new-label-item=v1
@cites {
    conformance#own-store=v1,
    identifiers#external-namespaces=v1,
    ontology#{
        declared-item=v1, item-name=v1, item-revision=v1,
        object-withdrawal=v1, containment=v1, tree=v1, parameter=v1,
        encoding=v1,
    },
    object-store#tree-object-store=v1,
    documents#{
        file-readers=v1, item-file=v1, name-set=v1,
        tree-containment=v1,
    },
    revisions#base-item=v1,
    approval#{persons=v1, listed-person=v1},
    text#text=v1,
    #{historical-paths=v1, historical-file=v1},
}

This term is for a `tree` `T`, a base `tree` `B`, valid bindings of the
`parameter`s `file-readers`, `external-namespaces`, and
`historical-paths` (`H`), and `persons` unbound or bound to a valid
binding, where `T` and `B` have valid `tree-object-store`s (or come from
valid `own-store`s). Under those inputs, a `declared-item` `d` of `T`
(across both encodings under `file-readers`, `external-namespaces`, and
`persons`, with `object-withdrawal`, `listed-person`, `item-file`,
`name-set`, `containment`, and `tree-containment`) is an **item with a
new label** against `B` when all four of these conditions hold:

1. `d` has a current revision (`item-revision`) in `T`.
2. `d` is not in a `historical-file` of `T` under `H` (a stored declared
   item in `.sinter/` or a declared item from a valid `own-store` is
   never in a historical file).
3. For each `name-set` of `T` to which `d` belongs, no other declared
   item in that name set has an `item-name` in `T` equal as a `text` to
   the `item-name` of `d` in `T`.
4. Either `d` has no `base-item` in `B`, or the `base-item` `e` of `d`
   in `B` has no current revision (`item-revision`) in `B` or has a
   current revision in `B` that is not the same `text` as the current
   revision of `d` in `T`.

Otherwise, `d` is not an item with a new label against `B` under those
inputs.

#### Findings of the class `reused-label`

@atom reused-label-finding=v1
@cites {
    conformance#own-store=v1,
    files#path=v1,
    identifiers#{
        external-namespaces=v1, declaration=v1, tag-line-text=v1,
    },
    ontology#{
        declared-item=v1, item-name=v1, item-revision=v1,
        revised-content=v1, object=v1, content-hash=v1, same-item=v1,
        containment=v1, object-withdrawal=v1, tree=v1, parameter=v1,
        encoding=v1,
    },
    object-store#{valid-object-file=v1, tree-object-store=v1},
    findings#location=v1,
    documents#{
        file-readers=v1, kept-object-set=v1, item-file=v1,
        canonical-object=v1, origin=v1, slice-location=v1,
        tree-finding=v1,
    },
    revisions#base-item=v1,
    approval#{persons=v1, listed-person=v1},
    text#text=v1,
    #{historical-paths=v1, new-label-item=v1},
}

This atom is for a `tree` `T`, a base `tree` `B`, a finite sequence `L`
of `tree`s, valid bindings of the `parameter`s `file-readers`,
`external-namespaces`, and `historical-paths`, a valid
`kept-object-set`, and `persons` unbound or bound to a valid binding,
where `T`, `B`, and each element of `L` have valid `tree-object-store`s
(or come from valid `own-store`s). Under those inputs, `T` has one
`tree-finding` of the class `reused-label` against `B` and `L` for each
`declared-item` `d` of `T` (across both encodings under those bindings,
with `object-withdrawal`, `listed-person`, `containment`, and
`same-item`) that meets both of these conditions:

1. `d` is a `new-label-item` against `B` under those inputs.
2. For at least one element `M` of `L`, `d` has a `base-item` `e` in
   `M`, `e` has a current revision (`item-revision`) in `M` that is the
   same `text` as the current revision of `d` in `T`, and either `d` and
   `e` are of different kinds of item or the `content-hash` of the
   `canonical-object` (`object`, `revised-content`) of `d` in `T`
   differs from the `content-hash` of the `canonical-object` of `e` in
   `M`.

The subject of that `tree-finding` is the `item-name` of `d` in `T`. The
`location` of that `tree-finding` follows the input from which `d`
comes:

- when `d` is in the text `encoding` in `T`: the `slice-location` of the
  `origin` slice of the `tag-line-text` of the `declaration` of `d` in
  the text of the file (`item-file`) of `d` in `T`;
- when `d` is in the `.sinter/` encoding in `T`: the valid `path` of the
  `valid-object-file` of `d` in `T` alone, with no span;
- when a program takes `d` from a valid `own-store` with no file in `T`:
  no location.

@example Suppose `L` holds an earlier tree where `@req billing#size` had
label `v2` with canonical
[content hash](sinter:ontology#content-hash=v1) `X1`, and a later tree
(also the base tree `B`) where `billing#size` moved to `v3` with content
hash `X2`:

- Moving `billing#size` back to `v2` with a new content hash `X3`
  produces one `reused-label` finding with subject `billing#size`.
- Moving `billing#size` back to `v2` with the same kind and exact
  content hash `X1` (even after moving between text and `.sinter/`)
  produces no `reused-label` finding.
- An untouched item `billing#old=v1` that keeps its base label is not a
  [new-label-item](sinter:#new-label-item=v1) and produces no finding,
  even when an earlier tree in `L` held `billing#old=v1` with different
  content.
- A [historical file](sinter:#historical-file=v1) in an earlier tree of
  `L` still supplies items for [base-item](sinter:revisions#base-item=v1)
  comparison against a live item in `T`;
  [historical-paths](sinter:#historical-paths=v1) suppresses findings
  only for text items whose file in `T` is historical, and never
  suppresses findings for stored items in `.sinter/` or items from a
  program's own store ([own-store](sinter:conformance#own-store=v1)).

### Returning `deleted-decision` findings

@req give-deleted-decision-findings=v1
@cites {
    conformance#{
        conforming-program=v1, dependence=v1, own-store=v1,
        reject-invalid-inputs=v1, report-missing-parts=v1,
        give-results-over-canonical-objects=v1,
        read-defined-encodings=v1,
    },
    identifiers#external-namespaces=v1,
    ontology#{
        finding-class=v1, computed-identity=v1, object-withdrawal=v1,
        tree=v1, parameter=v1,
    },
    object-store#tree-object-store=v1,
    documents#{file-readers=v1, tree-finding=v1},
    approval#{persons=v1, listed-person=v1},
    #{historical-paths=v1, deleted-decision-finding=v1},
}

This requirement applies for a `tree` `T`, a base `tree` `B`, bindings
of the `parameter`s `file-readers` and `external-namespaces` (each valid
or invalid), `tree-object-store`s of `T` and `B` (each valid or invalid,
or valid `own-store`s), `persons` unbound or bound, and
`historical-paths` unbound or bound (valid or invalid), when a
conforming program returns the findings of the `finding-class`
`deleted-decision` of `T` against `B`
(`give-results-over-canonical-objects`, `read-defined-encodings`).

When `file-readers`, `external-namespaces`, and the `tree-object-store`s
of `T` and `B` (or `own-store`s) are valid (regardless of whether
`historical-paths` is unbound, valid, or invalid):

- When `persons` is unbound or bound to a valid binding, the program
  must return each `deleted-decision-finding` (`tree-finding`) that `T`
  has against `B` once, and must return no other finding of that class.
- When `persons` is bound to an invalid binding (a value that does not
  meet `persons`), the program must return once each
  `deleted-decision-finding` that `T` has against `B` that does not
  depend on `persons` (`dependence`, `listed-person`,
  `object-withdrawal`), and must return no other finding of that class
  (`reject-invalid-inputs`).

A `deleted-decision` finding does not depend (`dependence`) on
`historical-paths`. When `file-readers`, `external-namespaces`, or the
`tree-object-store` of `T` or `B` is invalid, a conforming program must
return no `deleted-decision` finding (`reject-invalid-inputs`).

A finding of the class `deleted-decision` does not need any
`computed-identity` object missing from the `tree-object-store` of `T`
or `B` (`dependence`, `report-missing-parts`).

### Returning `reused-label` findings

@req give-reused-label-findings=v1
@cites {
    conformance#{
        conforming-program=v1, dependence=v1, own-store=v1,
        reject-invalid-inputs=v1, report-missing-parts=v1,
        give-results-over-canonical-objects=v1,
        read-defined-encodings=v1,
    },
    identifiers#external-namespaces=v1,
    ontology#{
        finding-class=v1, declared-item=v1, edge=v1,
        computed-identity=v1, object-withdrawal=v1, tree=v1,
        parameter=v1,
    },
    object-store#{tree-object-store=v1, valid-object-file=v1},
    changes#commit-change=v1,
    findings#location=v1,
    documents#{
        file-readers=v1, kept-object-set=v1, canonical-target=v1,
        canonical-object=v1, tree-finding=v1,
    },
    revisions#base-item=v1,
    approval#{persons=v1, listed-person=v1},
    #{historical-paths=v1, reused-label-finding=v1},
}

This requirement applies for a `tree` `T`, a base `tree` `B`, a finite
sequence `L` of `tree`s, bindings of the `parameter`s `file-readers`,
`external-namespaces`, and `historical-paths` (each valid or invalid), a
`kept-object-set` (valid or invalid), `tree-object-store`s of `T`, `B`,
and each element of `L` (each valid or invalid, or valid `own-store`s),
and `persons` unbound or bound, when a conforming program returns the
findings of the `finding-class` `reused-label` of `T` against `B` and
`L` (`give-results-over-canonical-objects`, `read-defined-encodings`).
This requirement does not apply when a conforming program returns the
findings of the `finding-class` `reused-label` of a `commit-change`.

When `file-readers`, `external-namespaces`, `historical-paths`,
`kept-object-set`, and the `tree-object-store`s of `T`, `B`, and each
element of `L` (or `own-store`s) are valid:

- When `persons` is unbound or bound to a valid binding, the program
  must return each `reused-label-finding` (`tree-finding`) that `T` has
  against `B` and `L` once, and must return no other finding of that
  class.
- When `persons` is bound to an invalid binding (a value that does not
  meet `persons`), the program must return once each
  `reused-label-finding` that `T` has against `B` and `L` whose
  existence and `location` (including having no location) do not depend
  on `persons` (`dependence`, `listed-person`, `object-withdrawal`), and
  must return no other finding of that class (`reject-invalid-inputs`).

When `historical-paths`, `file-readers`, `external-namespaces`,
`kept-object-set`, or the `tree-object-store` of `T`, `B`, or any
element of `L` is invalid, a conforming program must return no
`reused-label` finding for `T` (`reject-invalid-inputs`).

A finding of the class `reused-label` for a `declared-item` `d` of `T`
needs (`dependence`, `report-missing-parts`) a missing part of an `edge`
(`canonical-target`) only when computing the `canonical-object` of `d`
in `T`, of its `base-item` in `B`, or of its `base-item` in an element
of `L` needs that part. That finding does not need a `computed-identity`
object missing from `.sinter/` (`tree-object-store`) when the
`valid-object-file`s already hold their `canonical-object`s.

### Comparing a commit change for deleted decisions

@req compare-change-for-deleted-decisions=v1
@cites {
    conformance#{conforming-program=v1, reject-invalid-inputs=v1},
    ontology#{finding-class=v1, tree=v1, parameter=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        commit-change=v1, change-base=v1, repository-read=v1,
        undisturbed-read=v1,
    },
    #give-deleted-decision-findings=v1,
}

For a `commit` `h` of a git repository under a valid binding of the
`parameter` `default-branch-name` under which `h` has a `change-base`
`b`, when every `repository-read` from which a conforming program reads
`b` and the `commit-file`s of the `tree` of `h` and of the `tree` of `b`
is undisturbed (`undisturbed-read`), when the program returns the
findings of the `finding-class` `deleted-decision` of the
`commit-change` of `h`, the program must return the findings that
`give-deleted-decision-findings` obliges for the `tree` of `h` against
the `tree` of `b`.

When `default-branch-name` is invalid, a conforming program must return
no `deleted-decision` finding for the `commit-change` of `h`
(`reject-invalid-inputs`).

### Comparing a commit change for reused labels

@req compare-change-for-reused-labels=v1
@cites {
    conformance#{
        conforming-program=v1, dependence=v1, report=v1,
        reject-invalid-inputs=v1, report-missing-parts=v1,
        give-results-over-canonical-objects=v1,
        read-defined-encodings=v1,
    },
    identifiers#external-namespaces=v1,
    ontology#{
        finding-class=v1, declared-item=v1, edge=v1,
        computed-identity=v1, object-withdrawal=v1, default-branch=v1,
        tree=v1, parameter=v1,
    },
    object-store#{tree-object-store=v1, valid-object-file=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, commit-change=v1, change-base=v1,
        first-parent-line=v1, repository-read=v1, undisturbed-read=v1,
    },
    findings#location=v1,
    documents#{
        file-readers=v1, kept-object-set=v1, canonical-target=v1,
        canonical-object=v1, tree-finding=v1,
    },
    revisions#base-item=v1,
    approval#{
        persons=v1, listed-person=v1, incomplete-first-parent-line=v1,
    },
    #{
        historical-paths=v1, new-label-item=v1, reused-label-finding=v1,
    },
}

For a `commit` `h` of a git repository `R`, a valid binding `D` of the
`parameter` `default-branch-name` under which `h` has a `change-base`
`b` (so the `default-branch` of `R` has a `default-branch-commit` `d`
under `D`), bindings `F` of `file-readers`, `N` of
`external-namespaces`, and `H` of `historical-paths` (each valid or
invalid), a `kept-object-set` `K` (valid or invalid), `persons` unbound
or bound, and the `tree-object-store`s of the `tree` of `h` and of the
`tree` of `b` (`commit-file`, each valid or invalid), let `L` be the
finite sequence of the `tree`s of the commits of the `first-parent-line`
of `d`, in the order of that line.

Under that binding `D`, these four rules apply for a conforming program:

1. **When the program does not return findings of the `finding-class`
   `reused-label` of the `commit-change` of `h`:** when every
   `repository-read` from which the program reads `b` is undisturbed
   (`undisturbed-read`), the program must not return a
   `conformance#report` stating that the program cannot see the whole
   history for the `commit-change` of `h`.
2. **When `F`, `N`, `H`, and the `tree-object-store`s of the `tree`s of
   `h` and `b` are valid, `persons` is unbound or bound to a valid
   binding, the program returns findings of the `finding-class`
   `reused-label` of the `commit-change` of `h`
   (`give-results-over-canonical-objects`, `read-defined-encodings`), and
   every `repository-read` from which the program reads `b`, the
   `first-parent-line` of `d`, and the `commit-file`s of the `tree`s of
   `h`, `b`, and the commits of that line is undisturbed
   (`undisturbed-read`):**
   - When the `tree` of `h` has no `new-label-item` against the `tree`
     of `b` under `F`, `N`, `persons`, and `H`, the program must return
     no `reused-label` finding for the `commit-change` of `h` and must
     not return a `conformance#report` stating that the program cannot
     see the whole history for the `commit-change` of `h`.
   - When the `tree` of `h` has at least one `new-label-item` against
     the `tree` of `b` under `F`, `N`, `persons`, and `H`, and the
     `first-parent-line` of `d` under `F` is incomplete for those
     repository reads (`incomplete-first-parent-line`), the program must
     return one `conformance#report` stating that the program cannot see
     the whole history for the `commit-change` of `h` (as the report for
     that missing part under `report-missing-parts`), and must return no
     `reused-label` finding for the `commit-change` of `h`.
   - When the `tree` of `h` has at least one `new-label-item` against
     the `tree` of `b` under `F`, `N`, `persons`, and `H`, the
     `first-parent-line` of `d` under `F` is not incomplete for those
     repository reads, `K` is valid, and each element of `L` has a valid
     `tree-object-store`, the program must return once each
     `reused-label-finding` (`tree-finding`) that the `tree` of `h` has
     against the `tree` of `b` and `L` under `F`, `N`, `K`, `persons`,
     and `H`, must return no other finding of that class, and must not
     return a `conformance#report` stating that the program cannot see
     the whole history for the `commit-change` of `h`.
3. **When `F`, `N`, `H`, and the `tree-object-store`s of the `tree`s of
   `h` and `b` are valid and `persons` is bound to an invalid binding**
   (a value that does not meet `persons`, under the same undisturbed
   reads as rule 2, while the program returns `reused-label` findings of
   the `commit-change` of `h`): the program must return once each
   `reused-label-finding` and each incomplete-history
   `conformance#report` that rule 2 obliges whose emission (and, for a
   finding, `location`) does not depend on `persons` (`dependence`,
   `listed-person`, `object-withdrawal`), and must return no other
   `reused-label` finding and no incomplete-history report whose
   emission depends on `persons` (`reject-invalid-inputs`).
4. **When `H`, `F`, `N`, `K`, or a `tree-object-store` is invalid:**
   when `H`, `F`, `N`, or the `tree-object-store` of `h` or `b` is
   invalid—or when `H`, `F`, `N`, and the `tree-object-store`s of `h`
   and `b` are valid, the `first-parent-line` of `d` under `F` is not
   incomplete, and `K` or the `tree-object-store` of an element of `L`
   is invalid—a conforming program must return no `reused-label` finding
   and no `conformance#report` stating that the program cannot see the
   whole history for the `commit-change` of `h`
   (`reject-invalid-inputs`).

When `default-branch-name` is invalid, a conforming program must return
no `reused-label` finding and no `conformance#report` stating that the
program cannot see the whole history for the `commit-change` of any
`commit` `h` (`reject-invalid-inputs`).

A `reused-label` finding for a `declared-item` `x` of the `tree` of `h`
needs (`dependence`, `report-missing-parts`) a missing part of an `edge`
(`canonical-target`) only when computing the `canonical-object` of `x`
in the `tree` of `h`, of its `base-item` in the `tree` of `b`, or of its
`base-item` in an element of `L` needs that part. That finding does not
need a `computed-identity` object missing from `.sinter/`
(`tree-object-store`) when the `valid-object-file`s already hold their
`canonical-object`s.

### Reporting a commit change with no base

@req report-change-missing-base=v1
@cites {
    conformance#{
        conforming-program=v1, report=v1, reject-invalid-inputs=v1,
    },
    ontology#{finding-class=v1, parameter=v1},
    changes#{
        commit=v1, default-branch-name=v1, commit-change=v1,
        change-base=v1, repository-read=v1, undisturbed-read=v1,
    },
    #{deleted-decision-finding=v1, reused-label-finding=v1},
}

For a `commit` `h` of a git repository under a valid binding `D` of the
`parameter` `default-branch-name`, when every `repository-read` from
which a conforming program reads whether `h` has a `change-base` under
`D` is undisturbed (`undisturbed-read`):

- **When `h` has no `change-base` under `D`:** When a conforming program
  returns the findings of the `finding-class` `deleted-decision`
  (`deleted-decision-finding`), of the `finding-class` `reused-label`
  (`reused-label-finding`), or of both classes for the `commit-change`
  of `h` under `D`, the program must return that `h` has no
  `change-base`, must return no finding of the class or classes whose
  findings the program returns, and must not return a
  `conformance#report` stating that the program cannot see the whole
  history for the `commit-change` of `h`.
- **When `h` has a `change-base` under `D`:** When a conforming program
  returns the findings of the `finding-class` `deleted-decision` or of
  the `finding-class` `reused-label` for the `commit-change` of `h`
  under `D`, or returns whether `h` has a `change-base` under `D`, the
  program must not return that `h` has no `change-base`.

When `default-branch-name` is invalid, a conforming program must not
return that `h` has no `change-base` (`reject-invalid-inputs`).

### Test vectors

The groups `deleted-decisions` and `reused-labels` are in the
design-level test-vector file
[standing.test-vectors.jsonl](standing.test-vectors.jsonl), a
test-vector set under [test-vectors](sinter:data-forms#test-vectors=v1).
Neither group uses `needs` or `result`. The commit-change requirements
[compare-change-for-deleted-decisions](sinter:#compare-change-for-deleted-decisions=v1),
[compare-change-for-reused-labels](sinter:#compare-change-for-reused-labels=v1),
and [report-change-missing-base](sinter:#report-change-missing-base=v1)
have no test vectors in that file.

#### Deleted-decision vectors

@schema deleted-decisions-vector=v1
@cites {
    conformance#{conforming-program=v1, own-store=v1},
    text#{text=v1, code-point-order=v1},
    files#path-set=v1,
    data-forms#{group-schema=v1, vector-line=v1, vector-meaning=v1},
    identifiers#external-namespaces=v1,
    ontology#{
        declared-item=v1, item-name=v1, tree=v1, finding-class=v1,
        parameter=v1,
    },
    object-store#tree-object-store=v1,
    findings#{finding-subject=v1, location=v1},
    documents#{file-readers=v1, name-set=v1, tree-finding=v1},
    approval#persons=v1,
    #{
        historical-paths=v1, deleted-decision-finding=v1,
        give-deleted-decision-findings=v1,
    },
}

`deleted-decisions-vector` is a `group-schema` for group
`deleted-decisions` and tests `give-deleted-decision-findings`. Each
line is a `vector-line` whose meaning follows `vector-meaning`. Each
vector stands for undisturbed `tree`s with valid `tree-object-store`s
(or valid `own-store`s), `persons` unbound, and valid bindings of the
`parameter`s `file-readers` and `external-namespaces`. Each JSON string
represents a `text`.

| field | type | meaning |
|---|---|---|
| `input.historical-paths` | array of strings | binding of `historical-paths` (`path-set`, valid or invalid): path set members in order |
| `input.base` | array of objects | sequence of `declared-item`s of the base `tree` |
| `input.tree` | array of objects | sequence of `declared-item`s of the target `tree` |
| `input.base[].name`, `input.tree[].name` | string | `item-name` of the declared item |
| `input.base[].kind`, `input.tree[].kind` | string | object kind word of the declared item: one of `"design"`, `"spec"`, `"schema"`, `"req"`, `"atom"`, `"term"`, and `"decision"` |
| `input.base[].set`, `input.tree[].set` | string (optional) | `name-set` of the declared item when it belongs to one: `"shared"` for the shared set, or `"design:"` followed by the `item-name` of the `design` item for that design's set; absent when the item belongs to no name set |
| `values.findings` | array of strings | `finding-subject` values of all `deleted-decision-finding` (`tree-finding`) findings of `input.tree` against `input.base`, each once, in `code-point-order`, whether or not `input.historical-paths` is a valid `path-set` |

The objects `input`, `values`, and each element of `input.base` and
`input.tree` hold only the members listed in this table. When a
`conforming-program` returns the findings of the `finding-class`
`deleted-decision` of `input.tree` against `input.base` under those
bindings, the program returns one `deleted-decision-finding` with no
`location` for each subject in `values.findings` and returns no other
finding of that class.

@example Sample lines testing
[give-deleted-decision-findings](sinter:#give-deleted-decision-findings=v1)
and [deleted-decision-finding](sinter:#deleted-decision-finding=v1) on a
deleted decision record and under an invalid
[historical-paths](sinter:#historical-paths=v1) binding
([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#deleted-decisions-vector=v1","group":"deleted-decisions","input":{"base":[{"kind":"decision","name":"rust-bridge","set":"shared"}],"historical-paths":[],"tree":[]},"note":"deleted decision record gives one finding","values":{"findings":["rust-bridge"]}}
{"form":"#deleted-decisions-vector=v1","group":"deleted-decisions","input":{"base":[{"kind":"decision","name":"rust-bridge","set":"shared"}],"historical-paths":["!docs/**"],"tree":[]},"note":"invalid historical-paths binding still gives deleted-decision findings","values":{"findings":["rust-bridge"]}}
```

#### Reused-label vectors

@schema reused-labels-vector=v1
@cites {
    conformance#{conforming-program=v1, own-store=v1},
    text#{text=v1, code-point-order=v1},
    files#{path=v1, path-set=v1},
    data-forms#{
        group-schema=v1, vector-line=v1, vector-meaning=v1,
        hash-form=v1,
    },
    identifiers#{external-namespaces=v1, label=v1},
    ontology#{
        declared-item=v1, item-name=v1, item-revision=v1,
        content-hash=v1, tree=v1, finding-class=v1, parameter=v1,
    },
    object-store#{store-file=v1, tree-object-store=v1},
    findings#finding-subject=v1,
    documents#{
        file-readers=v1, kept-object-set=v1, name-set=v1, item-file=v1,
        tree-finding=v1,
    },
    approval#persons=v1,
    #{
        historical-paths=v1, reused-label-finding=v1,
        give-reused-label-findings=v1,
    },
}

`reused-labels-vector` is a `group-schema` for group `reused-labels` and
tests `give-reused-label-findings`. Each line is a `vector-line` whose
meaning follows `vector-meaning`. Each vector stands for undisturbed
`tree`s with valid `tree-object-store`s (or valid `own-store`s),
`persons` unbound, valid bindings of the `parameter`s `file-readers` and
`external-namespaces`, and a valid `kept-object-set`. Each JSON string
represents a `text`.

| field | type | meaning |
|---|---|---|
| `input.historical-paths` | array of strings | binding of `historical-paths` (`path-set`, valid or invalid): path set members in order |
| `input.base` | array of objects | sequence of `declared-item`s of the base `tree` |
| `input.tree` | array of objects | sequence of `declared-item`s of the target `tree` |
| `input.history` | array of arrays | finite sequence `L` of `tree`s, each element holding the sequence of `declared-item`s of that tree |
| `input.base[].name`, `input.tree[].name`, `input.history[][].name` | string | `item-name` of the declared item |
| `input.base[].kind`, `input.tree[].kind`, `input.history[][].kind` | string | object kind word of the declared item: one of `"design"`, `"spec"`, `"schema"`, `"req"`, `"atom"`, `"term"`, and `"decision"` |
| `input.base[].hash`, `input.tree[].hash`, `input.history[][].hash` | string | `content-hash` of the canonical object of the item, a `text` that matches the hash form (`hash-form`) |
| `input.base[].path`, `input.tree[].path`, `input.history[][].path` | string (optional) | valid `path` of the file of the item (`item-file`, a `store-file` path when in `.sinter/`); absent when the item comes from a valid `own-store` with no file |
| `input.base[].label`, `input.tree[].label`, `input.history[][].label` | string (optional) | current revision (`item-revision`, a `label`) of the item; absent when the item is a `term` with no label |
| `input.base[].set`, `input.tree[].set`, `input.history[][].set` | string (optional) | `name-set` of the item when it belongs to one: `"shared"` for the shared set, or `"design:"` followed by the `item-name` of the `design` item for that design's set; absent when the item belongs to no name set |
| `values.findings` | array of strings (optional) | present when `input.historical-paths` is a valid `path-set`: `finding-subject` values of all `reused-label-finding` (`tree-finding`) findings of `input.tree` against `input.base` and `input.history`, each once, in `code-point-order`; absent (`values` is `{}`) when `input.historical-paths` is invalid |

The objects `input`, `values`, and each declared-item object in
`input.base`, `input.tree`, and `input.history` hold only the members
listed in this table. When `values` is `{}`, a `conforming-program`
returns no finding of the `finding-class` `reused-label` for
`input.tree`. When `values` is not `{}` and a conforming program returns
the findings of the `finding-class` `reused-label` of `input.tree`
against `input.base` and `input.history` under those bindings, the
program returns one `reused-label-finding` for each subject in
`values.findings` and returns no other finding of that class.

@example Sample lines testing
[give-reused-label-findings](sinter:#give-reused-label-findings=v1) and
[reused-label-finding](sinter:#reused-label-finding=v1) on a reused
label with different content and under an invalid
[historical-paths](sinter:#historical-paths=v1) binding
([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#reused-labels-vector=v1","group":"reused-labels","input":{"base":[{"hash":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","kind":"design","label":"v1","name":"billing","path":"docs/billing.md","set":"shared"},{"hash":"2222222222222222222222222222222222222222222222222222222222222222","kind":"req","label":"v3","name":"billing#size","path":"docs/billing.md","set":"design:billing"}],"historical-paths":[],"history":[[{"hash":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","kind":"design","label":"v1","name":"billing","path":"docs/billing.md","set":"shared"},{"hash":"2222222222222222222222222222222222222222222222222222222222222222","kind":"req","label":"v3","name":"billing#size","path":"docs/billing.md","set":"design:billing"}],[{"hash":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","kind":"design","label":"v1","name":"billing","path":"docs/billing.md","set":"shared"},{"hash":"1111111111111111111111111111111111111111111111111111111111111111","kind":"req","label":"v2","name":"billing#size","path":"docs/billing.md","set":"design:billing"}]],"tree":[{"hash":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","kind":"design","label":"v1","name":"billing","path":"docs/billing.md","set":"shared"},{"hash":"3333333333333333333333333333333333333333333333333333333333333333","kind":"req","label":"v2","name":"billing#size","path":"docs/billing.md","set":"design:billing"}]},"note":"moving back to an old label with a different content hash gives a finding","values":{"findings":["billing#size"]}}
{"form":"#reused-labels-vector=v1","group":"reused-labels","input":{"base":[{"hash":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","kind":"design","label":"v1","name":"billing","path":"docs/billing.md","set":"shared"}],"historical-paths":["docs/a.md","docs/a.md"],"history":[[{"hash":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","kind":"design","label":"v1","name":"billing","path":"docs/billing.md","set":"shared"},{"hash":"1111111111111111111111111111111111111111111111111111111111111111","kind":"req","label":"v1","name":"billing#size","path":"docs/billing.md","set":"design:billing"}]],"tree":[{"hash":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","kind":"design","label":"v1","name":"billing","path":"docs/billing.md","set":"shared"},{"hash":"2222222222222222222222222222222222222222222222222222222222222222","kind":"req","label":"v1","name":"billing#size","path":"docs/billing.md","set":"design:billing"}]},"note":"invalid historical-paths binding gives empty values","values":{}}
```
