<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Revisions
@design revisions=v1
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
@cites rfc/8259
Specifies the base items of declared items, the finding classes `needs-revision` and `suspect`, the base tree of the change of a commit, and requirements for conforming programs that give the findings of these classes and whether the change of a commit has a base.

A label says which revised content of a declared item a citation rests
on. When the revised content or kind of a declared item changes, the
label of that item must change too, so that each pinned citation of the
item becomes suspect and a person checks that citation again. A
conforming program compares the canonical declared items of a tree with
those of a base tree, such as the tree of the base of the change of a
commit, across the text encoding, the `.sinter/` encoding, and any valid
program's own store. It reports each declared item whose content hash or
kind changed while its label stayed the same. It also reports each
suspect citation edge of a tree.

From the Ontology (`ontology`), the design takes trees and their files,
objects and their object kinds (`object-kind`), content hashes, content
ids, computed identity objects, declared items and their kinds,
containment, names, labels, current revisions, revised contents, same
items across trees, object withdrawal and replacement, edges, pinned
edges, suspect edges, kept objects of the log branch, encodings,
findings, finding classes, and parameters. From Object store
(`object-store`), it takes store files, valid object files, needed
identity files, and the object store of a tree, including missing
computed identity objects. From Documents (`documents`), it takes the
declared items of a tree and their files, the origins of the runs of the
text of a file, the origin positions of citation entries and inline
citations, sets of names, vector files, the edges of a tree, the form
runs and form positions of the edges that vector lines give, position
subjects, edge subjects of declared items, the spots of runs, tree
findings, and bindings of the parameters `file-readers` (with their
readers) and `vector-paths`. From Changes (`changes`), it takes commits,
the files of the tree of a commit, the change of a commit, the base of
the change of a commit under a binding of the parameter
`default-branch-name`, and undisturbed repository reads. From Data forms
(`data-forms`), it takes line objects, canonical byte sequences, hashes,
test-vector sets, vector lines, the forms of a group, the meaning of a
vector, and hex texts. From Findings (`findings`), it takes the
subjects, spots, messages, marks, related messages, and fixes of
findings, and ackable findings. From Identifiers (`identifiers`), it
takes declarations, the production `label`, the texts of tag lines,
citation entries, inline citations, slugs, bindings of the parameter
`external-namespaces` with their namespace names and id patterns, and
the result "valid" of such a binding. From Files and paths (`files`), it
takes valid paths and path sets. From Text and notation (`text`), it
takes characters, texts, spaces, boundaries, spans, valid UTF-8, code
point order, code spans, decimal numerals, and what a result is. From
Conformance (`conformance`), it takes conforming programs, inputs, valid
program's own stores, and the general requirements that bind every
conforming program, including `end-runs-at-limits`,
`reject-invalid-inputs`, `report-missing-parts`,
`give-results-over-canonical-objects`, and `read-defined-encodings`.
From RFC 8259, it takes JSON values, with their objects, members,
arrays, strings, and numbers.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [tree](sinter:ontology#tree=v1) | a set of files, each a valid path with a content, such as the tree of a commit or the tree of a working tree |
| base tree | the tree with which a conforming program compares a tree, such as the tree of the base of the change of a commit |
| [object](sinter:ontology#object=v1) | an entity of one of the twenty-five kinds in `ontology#object-kind`, with one canonical form as a line object without an `id` member |
| [content hash](sinter:ontology#content-hash=v1) | the SHA-256 hash of the canonical byte sequence of an object, with no member `id` and no final line feed |
| [content id](sinter:ontology#content-id=v1) | the object kind word of an object, `:`, and the first 32 lowercase hex digits of its content hash |
| [computed identity](sinter:ontology#computed-identity=v1) | an object of one of the five kinds `name`, `pin`, `ext`, `vector-set`, and `vector-group`, holding only `kind`, `v` (1), and its key |
| [counting void](sinter:ontology#object-withdrawal=v1), [withdrawn](sinter:ontology#object-withdrawal=v1), [replaced](sinter:ontology#object-withdrawal=v1) | a `void` object in `.sinter/` that meets its acceptance rule, carries no `agent`, matches any bound list of persons, and meets the copy rule; an object named by a counting void's `withdraws` edge; a declared-item object in `.sinter/` named by a `revises` edge of a non-withdrawn declared-item object of the same name or of a counting void of a declared-item kind |
| [object store of a tree](sinter:object-store#tree-object-store=v1) | the set of all store files of a tree, valid when every store file of that tree is a valid object file |
| [kept object](sinter:ontology#log-branch=v1) | a copy of a declared item merged into the default branch, or a copy of a computed identity object named by an edge of a kept declared item other than its own `name` object, held on the log branch with no `seq` and no `by` |
| [label](sinter:ontology#revised-content=v1) | for a declared item in the text encoding, the text that `label` of Identifiers matches in its declaration, such as `v2` in `@req size=v2`; in the `.sinter/` encoding and in canonical form, the value of its member `label` when present |
| [current revision](sinter:ontology#item-revision=v1) | the label of the current declared-item object of a declared item in a tree; a term with no label has no current revision |
| [revised content](sinter:ontology#revised-content=v1) | the content that the canonical object of a declared item represents; two revised contents of the same declared item are the same when, and only when, their canonical objects have the same content hash |
| [set of names](sinter:documents#name-set=v1) | one of the sets of declared items of a tree in which names are looked up: the shared set and the set of each item of the kind design |
| [base item](sinter:#base-item=v1) | the declared item of the base tree with which a declared item of the tree is compared: the one declared item that is the same item in the corresponding set of names, of any kind and in either encoding, when the item of the tree is also the one declared item with its name in its set of names |
| [pinned edge](sinter:ontology#pinned-edge=v1) | over canonical objects, a citation edge whose target content id names a declared-item object or a `pin` object |
| [form run](sinter:documents#tree-edge=v1), [form position](sinter:documents#tree-edge=v1) | for an edge that a vector line gives, the run of the text of its vector file between the opening and closing quotes of the JSON string of the value of `form`, and the position where that run starts |
| [suspect edge](sinter:ontology#suspect-edge=v1) | a pinned edge whose target object has member `name` n where a declared item with name n exists in the tree, and either the edge names an exact declared-item object other than the current declared-item object of n in the tree (or n has no current declared-item object in the tree), or the edge names a `pin` object whose label differs from the label of the current declared-item object of n in the tree (or n has no current declared-item object in the tree, or that current declared-item object has no label) |
| [tree finding](sinter:documents#tree-finding=v1) | a finding of one tree, with a class, a subject, and a spot or no spot, that is not ackable |
| [`needs-revision`](sinter:#needs-revision-finding=v1) | the class of the findings of a declared item of a tree whose content hash or kind changed against the base tree while its label stayed the same |
| [`suspect`](sinter:#suspect-finding=v1) | the class of the findings of the suspect edges of a tree |

## 2. Labels, changes, and findings

### 2.1 What needs a new label

A declared item has a revised content: the content that its canonical
object represents (`ontology#revised-content`). The content hash of that
canonical object (`ontology#content-hash`) is the measure of revised
content. Two revised contents of the same declared item, in two trees
and in either encoding, are the same when, and only when, their
canonical objects have the same content hash.

Any change to the canonical object of a declared item changes its
content hash: changing its `kind`, its `text`, its status tags (in text
or in the member `status` of a declared item in `.sinter/`), or any of
its `edges`. In particular:

- Updating the pin of a citation entry changes the target content id of
  that edge and therefore changes the content hash of the citing item.
- Editing a declared item in place while its label stays the same
  changes its content id. Because exact pins stand wherever one exact
  object exists, any declared item that pins that edited item also
  changes its edge target and content hash, so both items get
  `needs-revision` until the edited item gets a new label.
- Editing a declared item held by a specification changes the exact
  target of that specification's `items` edge, so both the held item and
  the specification get `needs-revision` while their labels stay the
  same. A design holds no `items` edge, so editing a held item leaves
  the design's content hash unchanged.
- Changing the kind of a declared item changes the target content id of
  any exact pin to that item (for example, from `term:…` to `atom:…`),
  so a citing item with an exact pin also gets `needs-revision`. By
  contrast, an unpinned citation (`=*` or `name:…`) targets a `name`
  computed identity object that carries no kind, so changing the kind of
  an unpinned target changes neither the canonical object nor the
  content hash of the citing item.
- Moving a declared item between the text encoding and the `.sinter/`
  encoding without changing its canonical object keeps the same content
  hash and gives no `needs-revision` finding.

The labels of declared items are texts that match the production `label`
of Identifiers, such as `v2`, `2026-11`, or `rc1`. No order is defined
on the labels of declared items. So, for a declared item, a new label is
a label other than the label of its base item. The atom
`needs-revision-finding` gives which declared items of the tree need a
new label. A declared item with a new label gives no finding of the
class `needs-revision`, whatever else changed. A term with no label also
gives no finding of the class `needs-revision`.

For example, a base tree declares `@req size=v2`, which the item of the
kind design `billing` holds directly. In the tree, a sentence of the
text of the requirement changes, and the label of the requirement stays
`v2`. The tree has one finding of the class `needs-revision` with the
subject `billing#size`. When the label of the requirement becomes `v3`,
or any other label, the tree has no finding of the class
`needs-revision` for the requirement.

### 2.2 Base items

A declared item of the tree is compared with its base item (`base-item`),
which aligns with `ontology#same-item` across kinds and across
encodings. When `@design x=v1` becomes `@decision x=v1` with the same
text, the two items are compared, and the tree has a finding of the
class `needs-revision` for `x`.

Containment in both encodings follows `ontology#containment`. In
`.sinter/`, an item of the kind specification holds each declared item
whose current canonical object one of its exact `items` edges names, and
an item of the kind design holds each declared item in `.sinter/` whose
member `name` is `<design-name>#<segment>`.

Only current declared items of a tree enter its sets of names. A
declared-item object in `.sinter/` that is replaced or withdrawn
(`ontology#object-withdrawal`) is not a declared item of its tree, has
no base item, and is no base item. An item also has no base item when
its set of names has another declared item with the same name (including
one in text and one in `.sinter/`), in the tree or in the base tree, or
when the item is in no set of names. The valid path of the file of a
declared item does not count when the base item of that declared item is
found. A declared item in a read file that cannot be read, such as a
read file whose content is not valid UTF-8, is not a declared item of
its tree. When the object store of a tree is not valid
(`object-store#tree-object-store`), a conforming program gives no
`needs-revision` finding for a comparison that uses that tree.

### 2.3 Suspect edges

A tree has one finding of the class `suspect` for each suspect citation
edge of the tree whose target is not a missing part (`suspect-finding`,
refining `ontology#suspect-edge`). A finding of the class `suspect` needs
no base tree. Only citation edges (`cites`, `satisfies`, `verifies`,
`refines`, and `supersedes`) of current declared items (in the text
encoding, in the `.sinter/` encoding, or from a valid program's own
store), tests, sites, and vector lines can be suspect. Structural edges
(`items`, `about`, `revises`), record edges, and edges of replaced or
withdrawn declared-item objects in `.sinter/` are never suspect.

Exact pins and content-id citations of non-identity declared-item
objects resolve first in the tree (a current declared item, or for an
exact pin a single replaced, unwithdrawn declared-item object in
`.sinter/`) and then against unwithdrawn kept objects supplied from the
log branch (`ontology#edge`, `ontology#log-branch`,
`ontology#object-withdrawal`). For example, when `billing#size` has the
current revision `v3` in the tree and an unwithdrawn kept object holds
`billing#size` at `v2`, both `@cites billing#size=v2` and a content-id
citation of that kept object give `suspect`. A pinned edge whose target
names a term that has no label in the tree is also suspect when that
edge resolves to a kept or replaced object or to a `pin` object.

Unpinned citations (`=*` and `@cites name:…`) target `name` computed
identity objects and are never pinned and never suspect. A leftover
`name` object file in `.sinter/` never creates a declared item in the
tree.

A pinned citation names a `pin` computed identity object only for a pin
cycle, an undeclared name, or an ambiguous pin matching two or more
copies (`ontology#edge`). For a pin cycle, the `pin` object's label
matches the current revision of its target, so the edge is not suspect.
For an undeclared name, no declared item of that name exists in the
tree, so the edge is not suspect. For an ambiguous pin (two or more
unwithdrawn kept copies, two or more replaced unwithdrawn `.sinter/`
copies, or two or more current declared-item objects of one name and
label), `ontology#suspect-edge` applies directly: the edge is suspect
when its `pin` object's label differs from the current revision of its
target or when that name has no unique current declared-item object in
the tree.

In the text encoding, `@cites pin:…` resolves as the exact pin `n=l`
when an input holds that `pin` object (`n`, `l`), and an unknown `pin:`
content id whose object no input holds resolves to no object and gives
no `suspect` finding (`ontology#edge`). In `.sinter/`, a stored edge
whose `to` is `pin:…` keeps that `pin:` content id as its canonical
target and resolves in a tree as `n=l` when an input holds that `pin`
object.

When a citation edge's target is a missing part (`ontology#edge`,
`object-store#tree-object-store`) — such as an exact pin to a revision
that never merged, a pin or content-id citation to a kept object
withdrawn by a counting void, a missing log branch needed to resolve an
earlier revision, or a stored `"to":"pin:…"` edge in `.sinter/` whose
`pin` object no input of the run holds — a conforming program withholds
the `suspect` finding for that edge and still gives every `suspect`
finding that does not need that missing part
(`conformance#report-missing-parts`). When another input of the run,
such as a text file, supplies a `pin` object missing from `.sinter/`,
the run does not lack that part and gives every finding.

For example, in a vector file located under `vector-paths`
(`documents#vector-paths`), the edge that the vector line
`{"form":"#g-vector=v1","group":"g","input":1,"values":{}}` gives is
suspect when the schema `g-vector` held directly by the design has the
current revision `v2` and an unwithdrawn kept object holds `g-vector` at
`v1`. The finding for that edge takes its subject from the form position
and its spot from the form run `#g-vector=v1` (`documents#tree-edge`).

### 2.4 The base tree of the change of a commit

The findings of the class `needs-revision` are defined for any base tree
and any tree. For the change of a commit, the base tree is the tree of
the base of the change of that commit. When the change has no base, such
as when the commit and the commit of the default branch have two merge
bases, a conforming program gives no finding of that class for the
change and gives that the change has no base.

Both trees of a comparison are read under one binding of each parameter
and one set of kept objects. What a program gives from a repository read
that is not undisturbed, or from a file that changes while the program
reads it, is a matter of the quality of an implementation.

### 2.5 Findings

The findings of both classes are tree findings. No finding of either
class is ackable. For a finding of either class, the message, the mark,
the related messages, and any fix of that finding are those that the
program that gives that finding gives. Marks and offered fixes exist
only for spots with spans in text files, never in `.sinter/` and never
for objects from a store without files. A related message can have a
spot in the base tree, such as the spot of the declaration or object
file of the base item.

Each finding has the subject and the spot (or no spot) that the atom of
its class gives. Finding classes and subjects for declared items and
their edges come only from canonical objects in every encoding, while
spots follow the input in which the program found the object. Edges from
sites, tests, and vector lines keep position subjects and run spots.

## 3. Definitions

### 3.1 Base items

@term base-item=v1
@cites {
    ontology#{
        declared-item=v1, item-name=v1, same-item=v1, containment=v1,
        tree=v1,
    },
    documents#{name-set=v1},
    text#{text=v1},
}

For two trees T and B (each holding declared items in the text encoding,
in the `.sinter/` encoding, or in both, with containment as
`ontology#containment` defines it), the set of names of B that
corresponds to a set of names N of T is this:

- for the shared set of T, the shared set of B;
- for the set of an item of the kind design D of T, when no other item
  of the kind design of T has the name of D: the set of the item of the
  kind design of B whose name is the name of D, when B has exactly one
  such item.

Otherwise, N has no corresponding set of names in B. The base item in B
of a declared item d of T is the declared item e of B that is the same
item as d (`ontology#same-item`, whatever the kinds of item and the
encodings of d and e are) and that is in the set of names of B that
corresponds to the set of names of T in which d is, when e is the only
declared item of that set of B with the name of d and d is the only
declared item of its set of names of T with that name. Otherwise, d has
no base item in B. Two names are the same name when, and only when, they
are the same text.

### 3.2 Findings of the class `needs-revision`

@atom needs-revision-finding=v1
@cites {
    conformance#{own-store=v1},
    identifiers#{external-namespaces=v1, declaration=v1, tag-line-text=v1},
    ontology#{
        declared-item=v1, item-name=v1, item-revision=v1,
        revised-content=v1, object=v1, content-hash=v1, containment=v1,
        encoding=v1, log-branch=v1, parameter=v1, tree=v1,
    },
    object-store#{tree-object-store=v1, valid-object-file=v1},
    findings#{spot=v1},
    documents#{
        file-readers=v1, item-file=v1, origin=v1, run-spot=v1,
        tree-finding=v1,
    },
    text#{text=v1},
    #{base-item=v1},
}

This atom is for a tree T, a base tree B, a binding of `file-readers`, a
binding of `external-namespaces`, and a set of kept objects
(`ontology#log-branch`). The declared items, their kinds, names, current
revisions, canonical objects, content hashes, and files of T and of B,
and the base items in B of the declared items of T, are those that T and
B have under these bindings and kept objects, across the text encoding
and the `.sinter/` encoding (when the object store of each tree is
valid), or from a valid program's own store.

Under these bindings and kept objects, T has one tree finding of the
class `needs-revision` against B for each declared item d of T that
meets three conditions:

1. d has a current revision in T and a base item e in B;
2. e has a current revision in B that is the same text as the current
   revision of d in T;
3. d and e are of different kinds of item, or the content hash of the
   canonical object of d in T is not the content hash of the canonical
   object of e in B.

The subject of that finding is the name of d. The spot of that finding
follows the input from which d comes:

- when d is in the text encoding in T, the spot of the run of the text
  of the declaration of d in the text of the file of d in T;
- when d is in the `.sinter/` encoding in T, the spot that is the valid
  path of the valid object file of d in T alone, with no span;
- when a program takes d from a valid program's own store with no file
  in T, no spot.

### 3.3 Findings of the class `suspect`

@atom suspect-finding=v1
@refines ontology#suspect-edge=v1
@cites {
    conformance#{own-store=v1},
    identifiers#{
        external-namespaces=v1, citation-entry=v1, inline-citation=v1,
    },
    data-forms#{vector-line=v1},
    ontology#{
        edge=v1, pinned-edge=v1, declared-item=v1, object=v1,
        content-id=v1, computed-identity=v1, encoding=v1,
        log-branch=v1, parameter=v1, tree=v1,
    },
    object-store#{tree-object-store=v1, valid-object-file=v1},
    findings#{spot=v1},
    documents#{
        file-readers=v1, vector-paths=v1, tree-edge=v1, origin=v1,
        origin-position=v1, position-subject=v1, edge-finding-subject=v1,
        run-spot=v1, tree-finding=v1,
    },
    text#{space=v1, text=v1},
}

Under a binding of `file-readers`, a binding of `vector-paths`, a
binding of `external-namespaces`, and a set of kept objects
(`ontology#log-branch`), a tree has one tree finding of the class
`suspect` for each citation edge of the tree under these bindings and
kept objects that is suspect in the tree (`ontology#suspect-edge`) and
whose target is not a missing part (`ontology#edge`). Only citation
edges (`cites`, `satisfies`, `verifies`, `refines`, and `supersedes`)
whose source is a current declared item of the tree (in the text
encoding, in the `.sinter/` encoding when the object store of the tree
is valid, or from a valid program's own store), a test, a site, or a
group of conformance vectors (from a vector line) are edges of the tree
for this atom; structural edges, record edges, and edges of replaced or
withdrawn declared-item objects in `.sinter/` give no finding of the
class `suspect`.

The subject and the spot of the finding for a suspect edge follow the
source of that edge:

- For a canonical citation edge whose source is a declared item, the
  subject of the finding is the edge subject (`documents#edge-finding-subject`):
  the content id of the source canonical object, then a space, then the
  kind of edge, then a space, then the target content id of the edge.
  When that declared item is in the text encoding in the tree and
  exactly one citation entry or inline citation in that declared item
  gives that canonical edge, the spot of the finding is the spot of the
  run of that citation entry or inline citation in the text of the file
  of that declared item. When that declared item is in the text encoding
  in the tree and two or more citation entries or inline citations in
  that declared item give that canonical edge, the finding has no spot.
  When that declared item is in the `.sinter/` encoding in the tree, the
  spot of the finding is the spot that is the valid path of the valid
  object file of that declared item alone, with no span. When a program
  takes that declared item from a valid program's own store with no file
  in the tree, the finding has no spot.
- For an edge that a citation entry or an inline citation standing in a
  test or in a site gives, the subject of the finding is the position
  subject of the origin position of that citation entry or inline
  citation, and the spot of the finding is the spot of the run of that
  citation entry or inline citation in the text of the file of the edge.
- For an edge that a vector line gives, the subject of the finding is
  the position subject of the form position of that edge in the vector
  file of the edge, and the spot of the finding is the spot of the form
  run of that edge in the text of that vector file.

## 4. Requirements

### 4.1 The findings of the class `needs-revision`

@req give-needs-revision-findings=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        finding-class=v1, tree=v1, parameter=v1, log-branch=v1,
        edge=v1, declared-item=v1,
    },
    object-store#{tree-object-store=v1},
    documents#{file-readers=v1, tree-finding=v1},
    conformance#{
        conforming-program=v1, dependence=v1, report-missing-parts=v1,
        give-results-over-canonical-objects=v1,
        read-defined-encodings=v1,
    },
    text#{result=v1},
    #{needs-revision-finding=v1},
}

This requirement applies under a valid binding of `file-readers`, a
binding of `external-namespaces` for which a conforming program of the
design Identifiers gives the result "valid", a set of kept objects
(`ontology#log-branch`), and valid object stores
(`object-store#tree-object-store`) of T and of B (or valid program's own
stores). Under these inputs, when a conforming program gives the
findings of the class `needs-revision` of a tree T against a base tree
B, that program must give each tree finding of that class that T has
against B under these inputs once, and must give no other finding of
that class.

A finding of the class `needs-revision` for a declared item d of T needs
a missing part of a citation edge (`ontology#edge`) only when computing
the canonical object of d in T or of its base item in B needs that part.
It does not need a computed identity object missing from `.sinter/`
(`object-store#tree-object-store`) when the valid object file of d in T
and of its base item in B already hold their canonical byte sequences.

### 4.2 The findings of the class `suspect`

@req give-suspect-findings=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        finding-class=v1, tree=v1, parameter=v1, log-branch=v1,
        edge=v1,
    },
    object-store#{tree-object-store=v1},
    documents#{file-readers=v1, vector-paths=v1, tree-finding=v1},
    conformance#{
        conforming-program=v1, dependence=v1, reject-invalid-inputs=v1,
        report-missing-parts=v1,
        give-results-over-canonical-objects=v1,
        read-defined-encodings=v1,
    },
    text#{result=v1},
    #{suspect-finding=v1},
}

This requirement applies under a valid binding of `file-readers`, a
valid binding of `vector-paths`, a binding of `external-namespaces` for
which a conforming program of the design Identifiers gives the result
"valid", a set of kept objects (`ontology#log-branch`), and a valid
object store (`object-store#tree-object-store`) of the tree (or a valid
program's own store). Under these inputs, when a conforming program
gives the findings of the class `suspect` of a tree, that program must
give each tree finding of that class that the tree has under these
inputs once, and must give no other finding of that class.

Only a finding of the class `suspect` for an edge that a vector line
gives depends on the binding of `vector-paths`. When an edge of a
declared item in `.sinter/`, a test, a site, or a vector line has a
target that is a missing part (`ontology#edge`, including a stored
`"to":"pin:…"` edge in `.sinter/` whose `pin` object no input of the run
holds under `object-store#tree-object-store`), only the finding of the
class `suspect` for that edge needs that missing part; every other
finding of the class `suspect` of the tree does not need that missing
part. When an edge of a declared item d in the text encoding has a
target that is a missing part, each finding of the class `suspect` whose
source is d (or whose source's canonical object depends on d) needs that
missing part; every other finding of the class `suspect` of the tree
does not need that missing part.

### 4.3 The base tree of the change of a commit

@req compare-with-change-base=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{finding-class=v1, tree=v1, parameter=v1, log-branch=v1},
    object-store#{tree-object-store=v1},
    changes#{
        default-branch-name=v1, commit=v1, commit-file=v1,
        change-of-a-commit=v1, change-base=v1, repository-read=v1,
        undisturbed-read=v1,
    },
    documents#{file-readers=v1, tree-finding=v1},
    conformance#{
        conforming-program=v1, give-results-over-canonical-objects=v1,
        read-defined-encodings=v1,
    },
    text#{result=v1},
    #{needs-revision-finding=v1},
}

This requirement applies for a commit h under three bindings, a set of
kept objects (`ontology#log-branch`), and valid object stores
(`object-store#tree-object-store`) of the tree of h and of the tree of
the base of the change of h: a valid binding of `default-branch-name`
under which the change of h has a base, a valid binding of
`file-readers`, and a binding of `external-namespaces` for which a
conforming program of the design Identifiers gives the result "valid".
Under these inputs, this requirement applies when a conforming program
meets two conditions. First, that program gives the findings of the
class `needs-revision` of the change of h under these inputs. Second,
each repository read from which that program takes the base of the
change of h and the files of the tree of h and of the tree of that base
is undisturbed. Under these inputs and when both conditions hold, that
program must give each tree finding of that class that the tree of h has
against the tree of the base of the change of h under these inputs once,
and must give no other finding of that class.

### 4.4 The change of a commit with a base

@req omit-missing-base-report=v1
@cites {
    ontology#{finding-class=v1, parameter=v1},
    changes#{
        default-branch-name=v1, commit=v1, change-of-a-commit=v1,
        change-base=v1, repository-read=v1, undisturbed-read=v1,
    },
    conformance#{conforming-program=v1},
}

This requirement applies for a commit h under a valid binding of
`default-branch-name` under which the change of h has a base, when a
conforming program meets two conditions. First, that program gives the
findings of the class `needs-revision` of the change of h under that
binding, or gives whether the change of h has a base under that binding.
Second, each repository read from which that program takes whether the
change of h has a base is undisturbed. Under that binding and when both
conditions hold, that program must not give that the change of h has no
base.

### 4.5 The change of a commit with no base

@req report-missing-base=v1
@cites {
    ontology#{finding-class=v1, parameter=v1},
    changes#{
        default-branch-name=v1, commit=v1, change-of-a-commit=v1,
        change-base=v1, repository-read=v1, undisturbed-read=v1,
    },
    conformance#{conforming-program=v1},
}

This requirement applies for a commit h under a valid binding of
`default-branch-name` under which the change of h has no base, when a
conforming program meets two conditions. First, that program gives the
findings of the class `needs-revision` of the change of h under that
binding. Second, each repository read from which that program takes that
the change of h has no base is undisturbed. Under that binding and when
both conditions hold, that program must give that the change of h has no
base, and must give no finding of that class.

## 5. Conformance

A program conforms to this design when it is a
[conforming program](sinter:conformance#conforming-program=v1) of this design.

The vectors of this design are in the file
[`revisions.test-vectors.jsonl`](revisions.test-vectors.jsonl), in the
same folder as this design. The file is a test-vector set, as the
specification [`test-vectors`](sinter:data-forms#test-vectors=v1) of
Data forms gives it. A vector is an input and what a conforming program
gives for that input. Each vector follows from the requirements and adds
nothing to them. Subsection 5.1 gives the forms of the group `trees`, as
the term [`group-form-list`](sinter:data-forms#group-form-list=v1) gives
them. No vector follows from the requirements
`compare-with-change-base`, `omit-missing-base-report`, and
`report-missing-base`.

### 5.1 Trees

@schema trees-vector=v1
@cites {
    rfc/8259,
    conformance#{
        conforming-program=v1, reject-invalid-inputs=v1,
        report-missing-parts=v1,
    },
    text#{
        text=v1, character=v1, valid-utf-8=v1, result=v1,
        code-point-order=v1, span=v1, boundary=v1, decimal-numeral=v1,
        code-span=v1,
    },
    files#{path=v1, path-set=v1},
    data-forms#{
        hex-text=v1, vector-line=v1, group-form-list=v1,
        vector-meaning=v1,
    },
    identifiers#{
        external-namespaces=v1, validate-bindings=v1, slug=v1,
    },
    ontology#{
        tree=v1, finding-class=v1, parameter=v1, object=v1,
        object-kind=v1, log-branch=v1,
    },
    object-store#{tree-object-store=v1},
    findings#{spot=v1},
    documents#{file-readers=v1, vector-paths=v1, tree-finding=v1},
    #{
        needs-revision-finding=v1, suspect-finding=v1,
        give-needs-revision-findings=v1, give-suspect-findings=v1,
    },
}

The group `trees` holds the vectors whose inputs are a base tree, a
tree, a binding of `file-readers` whose readers are all `markdown`, a
binding of `external-namespaces`, an optional binding of `vector-paths`,
and an optional set of kept objects. Its requirements are
`give-needs-revision-findings` and `give-suspect-findings`. Each vector
of the group has the member `values`, and no
vector has the member `result`. These forms name no question for
`result`. The group uses no need, so these forms give no need names.

The JSON values, objects, arrays, strings, and numbers of this schema
are as RFC 8259 defines them. In the members `input` and `values`, a
text, such as a valid path, a name, a subject, a namespace name, or an
id pattern, is a JSON string whose characters are the characters of the
text, in order.

The member `input` of a vector of the group is a JSON object with these
four required members and two optional members:

- `base`: the base tree.
- `tree`: the tree.
- `file-readers`: the binding of `file-readers`, as a JSON array with
  one element for each pair of the binding, in their order. The reader
  of each pair is `markdown`. The element for each pair is the path set
  of that pair: a JSON array of the path set members of that path set,
  each a text, in their order.
- `external-namespaces`: the binding of `external-namespaces`, as a JSON
  array with one element for each pair of the binding, in no meaningful
  order. Each element is a JSON object with two members:
  `namespace-name`, the namespace name of the pair, and `id-pattern`,
  the id pattern of the pair.
- `vector-paths` (optional): the binding of `vector-paths`, as a JSON
  array of path set members, each a text, in their order. When absent,
  the binding of `vector-paths` is `["**"]`, which never includes any
  file of `.sinter/`.
- `kept` (optional): the set of kept objects (`ontology#log-branch`), as
  a JSON array of canonical objects (each a JSON object conforming to a
  row of `ontology#object-kind` marked allowed on the log branch), in no
  meaningful order. When absent, the set of kept objects is empty.

A tree is a JSON object with one member for each file of the tree. The
key is the valid path of the file. When the content of the file is valid
UTF-8, the value is the text of that content, as a JSON string. When the
content of the file is not valid UTF-8, the value is a JSON object with
one member, `bytes`: the [hex text](sinter:data-forms#hex-text=v1) of
the content, as a JSON string.

The member `values` is the empty JSON object, `{}`, when the binding of
`file-readers` of the input is not valid, when a conforming program of
the design Identifiers gives the result "invalid" for the binding of
`external-namespaces` of the input, or when the object store
(`object-store#tree-object-store`) of `tree` is not valid. Otherwise,
the member `values` is a JSON object with one member, `findings`, whose
value is a JSON array. In that case, `findings` holds:

- one element for each tree finding of the class `needs-revision` that
  `tree` has against `base` under the inputs, except when the object
  store of `base` is not valid (in which case `findings` holds no
  finding of the class `needs-revision`) or when computing the canonical
  object of that item or of its base item needs a missing part;
- one element for each tree finding of the class `suspect` that `tree`
  has under the inputs, except when `vector-paths` is not valid (in
  which case `findings` holds no finding of the class `suspect` for an
  edge that a vector line gives) or when that edge has a target that is
  a missing part.

In that case, the elements of `findings` are in the code point order of
the slugs of the classes of those findings and then in the code point
order of the subjects of those findings. Each element of `findings` is a
JSON object with `class` (the slug of the class of the finding),
`subject` (the subject of the finding), and, when and only when the
finding has a spot, `spot` (the spot of the finding). When a finding has
no spot, its element has no member `spot`. The value of `spot` is a JSON
object with the member `path` (the valid path of the spot) and, when the
spot has a span, the member `span` (the span of the spot). When the spot
has no span (such as a spot in `.sinter/`), `spot` has no member `span`.
The value of `span` is a JSON object with two members: `from`, the
boundary of the text of the file where the span starts, and `to`, the
boundary of the text of the file where the span ends, each a JSON number
written as a decimal numeral.

For the input of a vector, a conforming program gives what `values`
states. When `values` is `{}`, that conforming program gives no finding
of either class for `tree` (by `reject-invalid-inputs` of Conformance).
When `values` is not `{}` and that conforming program gives the findings
of the class `needs-revision` of `tree` against `base` under the inputs,
that conforming program gives one finding of that class for each element
of `findings` of that class, with the subject that the element states,
and gives no other finding of that class. When `values` is not `{}` and
that conforming program gives the findings of the class `suspect` of
`tree` under the inputs, that conforming program gives one finding of
that class for each element of `findings` of that class, with the
subject that the element states, and gives no other finding of that
class. When a conforming program gives the spot of such a finding, that
program gives the spot that the element of `findings` for that finding
states, and gives no spot when that element has no member `spot`.
