<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Revisions
@design revisions=v1
@cites text=v1
@cites identifiers=v1
@cites files=v1
@cites data-forms=v1
@cites ontology=v1
@cites changes=v1
@cites findings=v1
@cites documents=v1
@cites rfc/8259
Specifies the base items of declared items, the versions of vector sets in a tree, the finding classes `needs-revision` and `suspect`, the base tree of the change of a commit, and requirements for conforming programs that give the findings of these classes.

A label says which revised content of an item a citation rests on. When
the revised content of an item changes, its label must change too, so
that each pinned citation of the item becomes suspect and a person
checks it again. A conforming program compares a tree with a base tree,
such as the tree of the commit on which a change starts. It reports each
declared item, conformance vector, group of conformance vectors, and
vector set whose revised content changed while its label did not change
as it must. It also reports each suspect edge of a tree.

From the Ontology (`ontology`), the design takes trees and their files,
the tree of a commit, declared items and their kinds, names, labels,
current revisions, revised contents, conformance vectors, groups of
conformance vectors, vector sets, the same item in two trees, edges,
pinned edges, suspect edges, findings, finding classes, and parameters.
From Documents (`documents`), it takes the declared items of a tree and
their files, the text of a declaration and its origin position, extent
hashes as the measure of revised content, sets of names, vector files,
the edges of a tree, position subjects, the spots of runs, tree
findings, and bindings of the parameter `file-readers`. From Changes
(`changes`), it takes commits, the change of a commit, and the base of
the change of a commit under a binding of the parameter
`default-branch-name`. From Data forms (`data-forms`), it takes
test-vector revisions and the order "higher" on them, vector lines,
group lines, set lines, test-vector sets, the text of the forms of a
group, versions, and the rules of version sequences. From Findings
(`findings`), it takes subjects and spots of findings. From Identifiers
(`identifiers`), it takes labels, kind words, bindings of the parameter
`external-namespaces`, and the result "valid" of a binding. From Files
and paths (`files`), it takes valid paths. From Text and notation
(`text`), it takes texts, lines, runs, spans, UTF-8 encodings, decimal
numerals, and what a conforming program and a result are. From RFC
8259, it takes JSON texts: each line of the file that holds the
conformance vectors of the design is one.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| tree | a set of files, each a valid path with a content, such as the tree of a commit or the tree of a working tree |
| base tree | the tree with which a conforming program compares a tree, such as the tree of the base of the change of a commit |
| [label](sinter:ontology#revised-content=v1) | the text after `=` in the declaration of a declared item, such as `v2` in `@req size=v2`; the revision of the vector line of a conformance vector, of the group line of a group of conformance vectors, or of the set line of a vector set |
| [current revision](sinter:ontology#item-revision=v1) | the label that an item has in a tree; a term with no label has no current revision |
| [revised content](sinter:ontology#revised-content=v1) | the part of an item that its label covers |
| [extent hash](sinter:documents#extent-hash=v1) | the hash of the text of the revised content of a declared item after Documents takes out some parts, such as the revisions of citation entries; two revised contents of the same declared item are the same when their extent hashes are equal |
| [set of names](sinter:documents#name-set=v1) | a set of declared items of a tree in which each name names one item: the shared set, the set of the declared finding classes, and the set of each item of the kind design |
| [base item](sinter:#base-item=v1) | the declared item of the base tree with which a declared item of the tree is compared: the one item with the same name in the corresponding set of names, of any kind |
| [version of a vector set](sinter:#tree-version=v1) | a vector set of a tree, together with the text of the forms of each of its groups in that tree |
| [higher](sinter:data-forms#test-vector-revision=v1) | a test-vector revision is higher than another when the number after its `v` is greater |
| [suspect edge](sinter:ontology#suspect-edge=v1) | a pinned edge whose cited item has no current revision, or a current revision other than the label of the edge |
| [tree finding](sinter:documents#tree-finding=v1) | a finding of one tree, with a class, a subject, and a spot, that is not ackable |
| [`needs-revision`](sinter:#needs-revision-finding=v1) | the class of the findings of an item of a tree whose revised content changed against the base tree while its label did not change as it must |
| [`suspect`](sinter:#suspect-finding=v1) | the class of the findings of the suspect edges of a tree |

## 2. Labels, changes, and findings

### 2.1 What needs a new label

A declared item has a revised content: the part of the item that its
label covers. The extent hash is the measure of revised content.
An edit that changes the extent hash of a declared item changes its
revised content. An edit of a part that the hash text leaves out changes
no revised content, such as a new revision of a citation entry, a new
section number of a heading, or an `@ack` line.

Labels are free texts, such as `v2`, `2026-11`, or `rc1`, and no order
is defined on them. So, for a declared item, a new label is a label
other than the label at the base. A declared item of the tree gives a
finding of the class `needs-revision` when it has a label, it has a base
item, the base item has the same label, and the two items differ in
their kinds or in their extent hashes. A new label with no other change
gives no finding of that class, and neither does a term with no label.

For example, a base tree declares `@req size=v2` in the item of the kind
design `billing`. In the tree, the text of the requirement changes and
its label stays `v2`. The tree has one finding of the class
`needs-revision` with the subject `billing#size`. When the label becomes
`v3`, or any other label, the tree has none for it. When only the line
`@cites limit=v1` in the requirement becomes `@cites limit=v2`, the
extent hash stays the same, and the tree has none for it.

The revised content of an item of the kind specification holds the
revised contents of the declared items that it holds, without their
labels. So an edit of the text of a requirement in a specification
changes the revised content of both. The revised content of an item of
the kind design does not hold the declared items that it holds. So an
edit of the text of a design outside these items changes the revised
content of the design alone.

### 2.2 Base items

A declared item of the tree is compared with its base item: the
declared item of the base tree that has the same name, in the set of
names that corresponds to the set of names of the item. The kind does
not count in this match. So when `@design x=v1` becomes `@decision x=v1`
with the same text, the two items are compared, and the tree has a
finding of the class `needs-revision` for `x`, because their kinds
differ. Without it, a citation of `x` that rested on the item of the
kind design would rest on the decision record and not be suspect.

An item whose name another item of its set of names also has, in the
tree or in the base tree, has no base item. Declared items are matched
by their names, so a file that moves changes no declared item. A
declared item in a file that cannot be read is not a declared item of
its tree, so it has no base item and it is no base item.

### 2.3 Conformance vectors, groups, and vector sets

A conformance vector, a group of conformance vectors, and a vector set
each have a label: a test-vector revision, such as `v3`. Their labels
are ordered, and the rules of version sequences say when a label must
become higher. The version of a vector set in a tree is its
test-vector set together with the text of the forms of each of its
groups in that tree. A conformance vector, group of conformance vectors,
or vector set of the tree gives a finding of the class `needs-revision`
when these rules, for the version at the base and the version in the
tree, say that its label is higher than at the base, and it is not.

For example, the base tree holds the vector line
`{"group":"offsets","input":"x","n":12,"result":"valid","rev":"v1"}`
in the vector file of the specification `data-forms#toml`, under the
group line `{"group":"offsets","rev":"v2"}` and the set line
`{"rev":"v3"}`. In the tree, its `input` becomes `"y"`, and no label
changes. The tree has three findings of the class `needs-revision`,
with the subjects `data-forms#toml[12]`, `data-forms#toml[offsets][*]`,
and `data-forms#toml[*]`. An edit of the text of the forms of the group
`offsets` changes each conformance vector of that group in the same
way.

### 2.4 Suspect edges

A tree has one finding of the class `suspect` for each suspect edge of
the tree, such as the edge of `@cites billing#size=v2` when
`billing#size` has the current revision `v3`. A finding of the class
`suspect` needs no base tree. A pinned edge whose cited item is a term
with no label is always suspect.

### 2.5 The base tree of the change of a commit

The findings of the class `needs-revision` are defined for any base
tree and any tree. For the change of a commit, the base tree is the
tree of the base of the change of that commit. When the change has no
base, such as when the commit and the commit of the default branch have
two merge bases, a conforming program gives no finding of that class
for it and gives that the change has no base.

Both trees of a comparison are read under one binding of each
parameter. What a program gives when a file changes while it reads the
file is a matter of the quality of an implementation.

### 2.6 Findings

The findings of both classes are tree findings: no finding of either
class is ackable, and the program that gives a finding gives its
message, its mark, its related messages, and its fix. A related message
can have a spot in the base tree, such as the spot of the declaration of
the base item.

The subject of a finding of the class `needs-revision` names its item.
A declared item is named by its name, after `finding-class:` for a
declared finding class, so that the declared finding class `foo` and the
item of the kind design `foo` have two subjects. A conformance vector, a
group of conformance vectors, and a vector set are named by the name of
the item that has their vector set and a vector selection. The subject
of a finding of the class `suspect` is the position subject of its
citation entry or inline citation.

## 3. Definitions

### 3.1 Base items

@term base-item=v1
@cites {
    ontology#{declared-item=v1, item-name=v1, tree=v1},
    documents#{name-set=v1},
    text#{text=v1},
}

For two trees T and B, the set of names of B that corresponds to a set
of names N of T is this:

- for the shared set of T, the shared set of B;
- for the set of the declared finding classes of T, the set of the
  declared finding classes of B;
- for the set of an item of the kind design D of T, when no other item
  of the kind design of T has the name of D: the set of the item of the
  kind design of B whose name is the name of D, when B has exactly one
  such item.

Otherwise, N has no corresponding set of names in B. The base item in B
of a declared item d of T is the declared item e of B that has the name
of d and that is in the set of names of B that corresponds to the set
of names of T in which d is, when e is the only declared item of that
set of B with that name and d is the only declared item of its set of
names of T with that name. Otherwise, d has no base item in B. Two names
are the same name only when they are the same text.

### 3.2 The versions of vector sets

@term tree-version=v1
@cites {
    ontology#{vector-set=v1, declared-item=v1, containment=v1, tree=v1},
    data-forms#{
        test-vector-version-sequence=v1, test-vector-set=v1,
        group-form-list=v1,
    },
    text#{text=v1},
    documents#{item-file=v1},
}

Let V be the vector set of an item x of the kind design or of the kind
specification in a tree, and let D be the item of the kind design that
is x or to which x belongs in that tree. The version of V in that tree
is the version, as the term `test-vector-version-sequence` gives
versions, whose test-vector set is V and in which the text of the forms
of each group g of V is the text of the forms of g of x, as the term
`group-form-list` gives it, with the text of the file of D in that tree
as the text of the design.

### 3.3 Findings of the class `needs-revision`

@term needs-revision-finding=v1
@cites {
    identifiers#{binding=v1},
    files#{path=v1},
    ontology#{
        declared-item=v1, declared-finding-class=v1, item-name=v1,
        item-revision=v1, same-item=v1, conformance-vector=v1,
        conformance-vector-group=v1, vector-set=v1, parameter=v1,
        tree=v1,
    },
    data-forms#{
        test-vector-version-sequence=v1, test-vector-revision=v1,
        vector-line=v1,
    },
    documents#{
        file-reader-binding=v1, extent-hash=v1, item-file=v1, origin=v1,
        run-spot=v1, vector-file=v1, tree-finding=v1,
    },
    findings#{spot=v1},
    text#{
        text=v1, line=v1, span=v1, utf-8-encoding=v1, byte=v1,
        0x-numeral=v1, decimal-numeral=v1, code-span=v1,
    },
    #{base-item=v1, tree-version=v1},
}

Under a binding of `file-readers` and a binding of
`external-namespaces`, the declared items, their extent hashes, their
sets of names, their vector files, and their vector sets in two trees T
and B are those that each tree has under these two bindings. Under these
bindings, T has these tree findings of the class `needs-revision`
against the base tree B:

- For each declared item d of T that has a current revision in T and a
  base item e in B, when e has a current revision in B that is the same
  text as the current revision of d in T, and d and e are of different
  kinds of item or the extent hash of d in T is not the extent hash of e in B:
  one tree finding. Its subject is the name of d, after the text
  `finding-class:` when d is a declared finding class. Its spot is the
  spot of the run of the text of the declaration of d in the text of its
  file in T.
- For each conformance vector, group of conformance vectors, and vector
  set X of T that is the same item as an item Y of B: one tree finding
  when, by the rules of the term `test-vector-version-sequence` for the
  sequence of two versions whose first version is the version of the
  vector set of Y in B and whose second version is the version of the
  vector set of X in T, the revision of X in the second version is
  higher than the revision of Y in the first version, and the label of
  X in T is not higher than the label of Y in B. Let x be the item whose
  vector set in T holds X, or is X. The subject of the finding is the
  name of x, then: for a conformance vector, `[`, the decimal numeral of
  its number, and `]`; for a group of conformance vectors, `[`, its
  name, `]`, and `[*]`; for a vector set, `[*]`. Its spot has the valid
  path of the vector file of x in T and the span of the line of the text
  of the content of that file whose UTF-8 encoding, then the byte 0x0A,
  is the vector line of X, the group line of X, or the set line of X.

### 3.4 Findings of the class `suspect`

@term suspect-finding=v1
@cites {
    identifiers#{citation-entry=v1, inline-citation=v1},
    ontology#{suspect-edge=v1, tree=v1},
    documents#{
        tree-edge=v1, origin=v1, origin-position=v1,
        position-subject=v1, run-spot=v1, tree-finding=v1,
    },
}

A tree has one tree finding of the class `suspect` for each edge of the
tree that is suspect in the tree. Its subject is the position subject of
the origin position of the citation entry or of the inline citation of
the edge. Its spot is the spot of the run of that citation entry or
inline citation in the text of the file.

## 4. Requirements

### 4.1 The findings of the class `needs-revision`

@req give-needs-revision-findings=v1
@cites {
    identifiers#{binding=v1},
    ontology#{finding-class=v1, tree=v1},
    documents#{file-reader-binding=v1, tree-finding=v1},
    text#{conforming-program=v1, result=v1},
    #{needs-revision-finding=v1},
}

Under a valid binding of `file-readers` and a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", when a conforming program gives
the findings of the class `needs-revision` of a tree against a base tree
under these bindings, it must give each tree finding of that class that
the tree has against the base tree under these bindings once, and no
other finding of that class.

### 4.2 The findings of the class `suspect`

@req give-suspect-findings=v1
@cites {
    identifiers#{binding=v1},
    ontology#{finding-class=v1, tree=v1},
    documents#{file-reader-binding=v1, tree-finding=v1},
    text#{conforming-program=v1, result=v1},
    #{suspect-finding=v1},
}

Under a valid binding of `file-readers` and a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", when a conforming program gives
the findings of the class `suspect` of a tree under these bindings, it
must give each tree finding of that class that the tree has under these
bindings once, and no other finding of that class.

### 4.3 The base tree of the change of a commit

@req compare-with-change-base=v1
@cites {
    identifiers#{binding=v1},
    ontology#{finding-class=v1, tree=v1, parameter=v1},
    changes#{commit=v1, change-of-a-commit=v1, change-base=v1},
    documents#{file-reader-binding=v1, tree-finding=v1},
    text#{conforming-program=v1, result=v1},
    #{needs-revision-finding=v1},
}

Under a binding of `default-branch-name` under which the change of a
commit h has a base, a valid binding of `file-readers`, and a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", when a conforming program gives
the findings of the class `needs-revision` of the change of h under
these bindings, it must give each tree finding of that class that the
tree of h has against the tree of the base of the change of h under
these bindings once, and no other finding of that class.

### 4.4 The change of a commit with no base

@req report-missing-base=v1
@cites {
    ontology#{finding-class=v1, parameter=v1},
    changes#{commit=v1, change-of-a-commit=v1, change-base=v1},
    text#{conforming-program=v1},
}

Under a binding of `default-branch-name` under which the change of a
commit h has no base, when a conforming program gives the findings of
the class `needs-revision` of the change of h under that binding, it
must give that the change of h has no base, and no finding of that
class.

## 5. Conformance

A program, or a part of a program, conforms to this design when it is a
conforming program of this design: when it meets every requirement of
section 4.

The vectors of this design are in the file
[`revisions.test-vectors.jsonl`](revisions.test-vectors.jsonl), in the
same folder as this design. The file is a
[test-vector set](sinter:data-forms#test-vector-set=v1). A vector is an
input and what a conforming program gives for it. Each vector follows
from the requirements and adds nothing to them. The vectors cover the
requirements `give-needs-revision-findings` and `give-suspect-findings`.

The file is a sequence of the
[canonical byte sequences](sinter:data-forms#canonical-byte-sequence=v1)
of JSON objects, each followed by the byte 0x0A. So each line of the
text of the file is a JSON text, as RFC 8259 defines it. Only a line
feed ends a line of the file. The file has three kinds of line, in this
order:

1. The first line is the set line. Its JSON object has one member,
   `rev`: the revision of the whole set of vectors.
2. Then the group `trees` has a group line. Its JSON object has two
   members: `group`, the name of the group, as a JSON string, and `rev`,
   the revision of the group.
3. Then each vector has a vector line, in increasing order of the
   numbers of the vectors.

The JSON object of a vector line has these members:

- `n`: the number of the vector, a JSON number written as the decimal
  numeral of a whole number of 1 or more. No other vector of the file
  has this number. A number is given to one vector only: when a vector
  leaves the file, no later vector gets its number, and a new vector
  gets a number greater than each number before it.
- `rev`: the revision of the vector.
- `group`: the name of the group of the vector, `trees`, as a JSON
  string.
- `input`: the input.
- `values`: a JSON object that states what a conforming program gives
  for the input. Each vector has this member.
- `note`: an explanation of the vector, as a JSON string, which a
  conforming program does not give. A vector has this member only when
  it has an explanation.

No vector has the member `result` or the member `needs`. This design
gives no need names.

A revision is a JSON string of `v`, then the decimal numeral of a whole
number of 1 or more, such as `"v1"`. A revision rises, to a greater
number after its `v`, when the vectors that it covers change, join, or
leave. When the text of this section changes, other than its heading and
the vector lines that it shows, the revisions of every vector, the
group, and the set rise. A change of a note alone changes no revision. A
program does not need the revisions to run the vectors.

The group `trees` holds the vectors whose inputs are a base tree and a
tree whose files are all markdown files. Its requirements are
`give-needs-revision-findings` and `give-suspect-findings`. The member
`input` of its vectors is a JSON object with these four members:

- `base`: the base tree.
- `tree`: the tree.
- `file-readers`: the binding of `file-readers`, as a JSON array with
  one element for each pair of the binding, in their order. The reader
  of each pair is `markdown`, and the element is the path set of the
  pair: a JSON array of its path set members, each a text, in their
  order.
- `external-namespaces`: the binding of `external-namespaces`, as a
  JSON array with one element for each pair of the binding, in no
  meaningful order. Each element is a JSON object with two members:
  `namespace-name`, the namespace name of the pair, and `id-pattern`,
  the id pattern of the pair.

A tree is a JSON object with one member for each file of the tree. The
key is the valid path of the file. When the content of the file is
valid UTF-8, the value is the text of that content, as a JSON string.
When it is not, the value is a JSON object with one member, `bytes`: the
[hex text](sinter:data-forms#hex-text=v1) of the content, as a JSON
string. A text is a JSON string whose characters are the characters of
the text, in order.

The member `values` is the empty JSON object, `{}`, when the binding of
`file-readers` of the input is not valid, or a conforming program of the
design Identifiers gives the result "invalid" for its binding of
`external-namespaces`. Otherwise, it is a JSON object with one member,
`findings`: a JSON array with one element for each tree finding of the
class `needs-revision` that the tree has against the base tree, and for
each tree finding of the class `suspect` that the tree has, under the
two bindings of the input, in the code point order of the slugs of their
classes and then in the code point order of their subjects. Each element
is a JSON object with these members: `class`, the slug of its class;
`subject`, its subject; and `spot`, its spot: a JSON object with the
member `path`, its valid path, and the member `span`, its span, as a
JSON object with two members, `from`, the boundary of the text of the
file where the span starts, and `to`, the boundary where it ends, each a
JSON number written as a decimal numeral.

For the input of a vector, when `values` is `{}`, a conforming program
gives no finding of either class for the tree. Otherwise, when it gives
the findings of the class `needs-revision` of the tree against the base
tree under the two bindings of the input, it gives one for each element
of `findings` of that class, with the subject that the element states,
and no other; and when it gives the findings of the class `suspect` of
the tree under these bindings, it gives one for each element of
`findings` of that class, with the subject that the element states, and
no other. When it gives the spot of such a finding, it gives the spot
that the element states.
