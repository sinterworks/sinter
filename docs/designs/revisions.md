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
Specifies the base items of declared items, the versions of vector sets in a tree, the finding classes `needs-revision` and `suspect`, the base tree of the change of a commit, and requirements for conforming programs that give the findings of these classes and whether the change of a commit has a base.

A label says which revised content of an item a citation rests on. When
the revised content of an item changes, its label must change too, so
that each pinned citation of the item becomes suspect and a person
checks it again. A conforming program compares a tree with a base tree,
such as the tree of the base of the change of a commit. It reports each
declared item whose revised content or kind changed while its label
stayed the same, and each conformance vector, group of conformance
vectors, and vector set whose label did not become higher when it had
to. It also reports each suspect edge of a tree.

From the Ontology (`ontology`), the design takes trees and their files,
the tree of a commit, declared items and their kinds, containment,
declared finding classes, names, labels, current revisions, revised
contents, conformance vectors, groups of conformance vectors, vector
sets, the same item in two trees, edges, pinned edges, suspect edges,
findings, finding classes, and parameters. From Documents (`documents`),
it takes the declared items of a tree and their files, the origins of
the runs of the text of a file, the origin positions of citation entries
and inline citations, extent hashes as the measure of revised content,
sets of names, the scopes of items, file lines, vector files, the edges
of a tree, position subjects, the spots of runs, tree findings, and
bindings of the parameter `file-readers` with their readers. From
Changes (`changes`), it takes commits, the change of a commit, the base
of the change of a commit under a binding of the parameter
`default-branch-name`, and undisturbed repository reads. From Data forms
(`data-forms`), it takes test-vector revisions and the order "higher" on
them, vector lines, group lines, set lines, test-vector sets, the text
of the forms of a group, versions, the rules of version sequences,
canonical byte sequences, and hex texts. From Findings (`findings`), it
takes the subjects, spots, messages, marks, related messages, and fixes
of findings, and ackable findings. From Identifiers (`identifiers`), it
takes declarations, their targets, the production `label`, the texts of
tag lines, citation entries, inline citations, slugs, bindings of the
parameter `external-namespaces` with their namespace names and id
patterns, and the result "valid" of such a binding. From Files and paths
(`files`), it takes valid paths and path sets. From Text and notation
(`text`), it takes texts, line feeds, lines, spans, bytes, 0x numerals,
code spans, UTF-8 encodings, decimal numerals, and what a conforming
program and a result are. From RFC 8259, it takes JSON texts: each line
of the file that holds the conformance vectors of the design is one.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [tree](sinter:ontology#tree=v1) | a set of files, each a valid path with a content, such as the tree of a commit or the tree of a working tree |
| base tree | the tree with which a conforming program compares a tree, such as the tree of the base of the change of a commit |
| [label](sinter:ontology#revised-content=v1) | for a declared item, the text that `label` of Identifiers matches in its declaration, such as `v2` in `@req size=v2`; for a conformance vector, a group of conformance vectors, or a vector set, the revision of its vector line, of the group line of its name, or of the set line |
| [current revision](sinter:ontology#item-revision=v1) | the label that an item has in a tree; a term with no label has no current revision |
| [revised content](sinter:ontology#revised-content=v1) | the part of an item that its label covers, or would cover for a term with no label |
| [extent hash](sinter:documents#extent-hash=v1) | the hash of the hash text that Documents gives for a declared item from its revised content; two revised contents of the same declared item are the same when, and only when, their extent hashes are equal |
| [set of names](sinter:documents#name-set=v1) | one of the sets of declared items of a tree in which names are looked up: the shared set, the set of the declared finding classes, and the set of each item of the kind design |
| [base item](sinter:#base-item=v1) | the declared item of the base tree with which a declared item of the tree is compared: the one item with the same name in the corresponding set of names, of any kind, when the item of the tree is also the one item with its name in its set of names |
| [version of a vector set](sinter:#tree-version=v1) | a vector set of a tree, together with the text of the forms of each of its groups in that tree, or the empty text when its item has no Conformance section or part |
| [higher](sinter:data-forms#test-vector-revision=v1) | a test-vector revision is higher than another when the number after its `v` is greater |
| [suspect edge](sinter:ontology#suspect-edge=v1) | a pinned edge that has a cited item in the tree and whose cited item has no current revision, or has a current revision other than the revision of its citation entry or inline citation |
| [tree finding](sinter:documents#tree-finding=v1) | a finding of one tree, with a class, a subject, and a spot, that is not ackable |
| [`needs-revision`](sinter:#needs-revision-finding=v1) | the class of the findings of a declared item of a tree whose revised content or kind changed against the base tree while its label stayed the same, and of a conformance vector, group of conformance vectors, or vector set whose label did not become higher when it had to |
| [`suspect`](sinter:#suspect-finding=v1) | the class of the findings of the suspect edges of a tree |

## 2. Labels, changes, and findings

### 2.1 What needs a new label

A declared item has a revised content: the part of the item that its
label covers. The extent hash is the measure of revised content: an edit
changes the revised content of a declared item when, and only when, it
changes its extent hash.

The labels of declared items are texts that match the production `label`
of Identifiers, such as `v2`, `2026-11`, or `rc1`, and no order is
defined on them. So, for a declared item, a new label is a label other
than the label of the item with which it is compared at the base. The
term `needs-revision-finding` gives which declared items of the tree
need a new label. A declared item with a new label gives no finding of
that class, whatever else changed, and neither does a term with no
label.

For example, a base tree declares `@req size=v2`, which the item of the
kind design `billing` holds directly. In the tree, a sentence of the
text of the requirement changes and its label stays `v2`. The tree has
one finding of the class `needs-revision` with the subject
`billing#size`. When the label becomes `v3`, or any other label, the
tree has none for it.

### 2.2 Base items

A declared item of the tree is compared with its base item, as the term
`base-item` gives it. The kind of the base item can differ from the kind
of the item. So when `@design x=v1` becomes `@decision x=v1` with the
same text, the two items are compared, and the tree has a finding of the
class `needs-revision` for `x`, because their kinds differ. A citation
of `x` then rests on the decision record, and its pin becomes suspect
only when the label changes.

An item has no base item when, for example, another item of its set of
names has its name, in the tree or in the base tree, or when the item is
in no set of names. The valid path of the file of a declared item does
not count when its base item is found. A declared item in a file that
cannot be read is not a declared item of its tree, so it has no base
item and it is no base item.

### 2.3 Conformance vectors, groups, and vector sets

The labels of a conformance vector, a group of conformance vectors, and
a vector set are test-vector revisions, such as `v3`, and the order
"higher" is defined on them. The rules of version sequences say when
such a label must become higher. The version of a vector set in a tree
is its test-vector set together with the text of the forms of each of
its groups, as the term `tree-version` gives it. A vector set of the
tree is compared with the vector set of the base item of its item. The
rules of version sequences, for the version at the base and the version
in the tree, then say which conformance vectors, groups of conformance
vectors, and vector sets of the tree need a higher label, as the term
`needs-revision-finding` gives.

For example, the base tree holds the vector line
`{"group":"offsets","input":"x","n":12,"result":"valid","rev":"v1"}`
in the vector file of the specification `data-forms#toml`, under the
group line `{"group":"offsets","rev":"v2"}` and the set line
`{"rev":"v3"}`. In the tree, its `input` becomes `"y"`, and no label
changes. The tree has three findings of the class `needs-revision`,
with the subjects `data-forms#toml[12]`, `data-forms#toml[offsets][*]`,
and `data-forms#toml[*]`.

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
parameter. What a program gives from a repository read that is not
undisturbed, or from a file that changes while the program reads it, is
a matter of the quality of an implementation.

### 2.6 Findings

The findings of both classes are tree findings: no finding of either
class is ackable, and the message, the mark, the related messages, and
any fix of a finding are those that the program that gives it gives. A
related message can have a spot in the base tree, such as the spot of
the declaration of the base item.

Each finding has the subject and the spot that the term of its class
gives. The subjects tell apart two items with one name in two sets of
names, such as the declared finding class `foo` and the item of the
kind design `foo`.

## 3. Definitions

### 3.1 Base items

@term base-item=v1
@cites {
    ontology#{
        declared-item=v1, declared-finding-class=v1, item-name=v1,
        tree=v1,
    },
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
are the same name when, and only when, they are the same text.

### 3.2 The versions of vector sets

@term tree-version=v1
@cites {
    identifiers#{declaration=v1, target=v1},
    ontology#{vector-set=v1, declared-item=v1, containment=v1, tree=v1},
    data-forms#{
        test-vector-version-sequence=v1, test-vector-set=v1,
        group-form-list=v1,
    },
    documents#{item-scope=v1, file-line=v1, vector-file=v1},
    text#{text=v1, line-feed=v1},
}

Let V be the vector set of an item x of the kind design or of the kind
specification in a tree. The scope text of x is the text that joins the
texts of the file lines of the scope of x, in their order, each followed
by one line feed. The version of V in that tree is the version, as the
term `test-vector-version-sequence` gives versions, whose test-vector
set is V and in which the text of the forms of each group g of V is:

- the text of the forms of g of x, as the term `group-form-list` gives
  it, with the scope text of x as the text of the design, with the
  items of the kind specification that belong to x as the
  specifications of x, and with the name in the target of the
  declaration of each item of the kind specification as the name of
  that specification, when the term `group-form-list` gives x a
  Conformance section or a Conformance part in this way;
- otherwise, the empty text.

### 3.3 Findings of the class `needs-revision`

@term needs-revision-finding=v1
@cites {
    identifiers#{binding=v1, declaration=v1, tag-line-text=v1},
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
`external-namespaces`, a tree T has these tree findings of the class
`needs-revision` against a base tree B, where the declared items, their
kinds, names, current revisions, extent hashes, and files, the base
items, the vector sets and their versions, and the vector files of T and
of B are those that each tree has under these two bindings:

- For each declared item d of T that has a current revision in T and a
  base item e in B, when e has a current revision in B that is the same
  text as the current revision of d in T, and d and e are of different
  kinds of item or the extent hash of d in T is not the extent hash of e
  in B: one tree finding. Its subject is the text `finding-class:`, then
  the name of d, when d is a declared finding class; otherwise, the name
  of d. Its spot is the
  spot of the run of the text of the declaration of d in the text of its
  file in T.
- For each item x of the kind design or of the kind specification of T
  that has a vector set in T and a base item y in B that has a vector
  set in B, and for each item X of T that is the vector set of x or one
  of its conformance vectors or groups of conformance vectors, and that
  is the same item as an item Y of B that is the vector set of y or one
  of its conformance vectors or groups of conformance vectors: one tree
  finding when the rules of the term `test-vector-version-sequence`, for
  the sequence of two versions whose first version is the version of the
  vector set of y in B and whose second version is the version of the
  vector set of x in T, require the revision of X in the second version
  to be higher than the revision of Y in the first version, and it is
  not higher. The subject of the finding is the name of x, then: for a
  conformance vector, `[`, the decimal numeral of its number, and `]`;
  for a group of conformance vectors, `[`, its name, `]`, and `[*]`; for
  a vector set, `[*]`. Its spot has the valid path of the vector file of
  x in T and the span of the line of the text of the content of that
  file whose UTF-8 encoding, then the byte 0x0A, is this line: for a
  conformance vector, its vector line; for a group of conformance
  vectors, the group line of the vector set of x whose group is its
  name; for a vector set, its set line.

### 3.4 Findings of the class `suspect`

@term suspect-finding=v1
@cites {
    identifiers#{binding=v1, citation-entry=v1, inline-citation=v1},
    ontology#{suspect-edge=v1, parameter=v1, tree=v1},
    documents#{
        file-reader-binding=v1, tree-edge=v1, origin=v1,
        origin-position=v1, position-subject=v1, run-spot=v1,
        tree-finding=v1,
    },
}

Under a binding of `file-readers` and a binding of
`external-namespaces`, a tree has one tree finding of the class
`suspect` for each edge that the tree has under these bindings and that
is suspect in the tree. Its subject is the position subject of
the origin position of the citation entry or of the inline citation of
the edge. Its spot is the spot of the run of that citation entry or
inline citation in the text of the file of the edge.

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

### 4.3 No finding under bindings that are not valid

@req omit-findings-under-invalid-bindings=v1
@cites {
    identifiers#{binding=v1},
    ontology#{finding-class=v1, tree=v1},
    documents#{file-reader-binding=v1},
    text#{conforming-program=v1, result=v1},
}

Under a binding of `file-readers` that is not valid, or under a binding
of `external-namespaces` for which a conforming program of the design
Identifiers gives the result "invalid", a conforming program must give
no finding of the class `needs-revision` of any tree against any base
tree, and no finding of the class `suspect` of any tree.

### 4.4 The base tree of the change of a commit

@req compare-with-change-base=v1
@cites {
    identifiers#{binding=v1},
    ontology#{finding-class=v1, tree=v1, parameter=v1},
    changes#{
        commit=v1, change-of-a-commit=v1, change-base=v1,
        repository-read=v1, undisturbed-read=v1,
    },
    documents#{file-reader-binding=v1, tree-finding=v1},
    text#{conforming-program=v1, result=v1},
    #{needs-revision-finding=v1},
}

Under a binding of `default-branch-name` under which the change of a
commit h has a base, a valid binding of `file-readers`, and a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", when a conforming program gives
the findings of the class `needs-revision` of the change of h under
these bindings, and each repository read from which it takes the base
of the change of h and the files of the tree of h and of the tree of
that base is undisturbed, it must give each tree finding of that class
that the tree of h has against the tree of the base of the change of h
under these bindings once, and no other finding of that class.

### 4.5 The change of a commit with a base

@req omit-missing-base-report=v1
@cites {
    ontology#{finding-class=v1, parameter=v1},
    changes#{
        commit=v1, change-of-a-commit=v1, change-base=v1,
        repository-read=v1, undisturbed-read=v1,
    },
    text#{conforming-program=v1},
}

Under a binding of `default-branch-name` under which the change of a
commit h has a base, when a conforming program gives the findings of the
class `needs-revision` of the change of h under that binding, or gives
whether the change of h has a base under that binding, and each
repository read from which it takes whether the change of h has a base
is undisturbed, it must not give that the change of h has no base.

### 4.6 The change of a commit with no base

@req report-missing-base=v1
@cites {
    ontology#{finding-class=v1, parameter=v1},
    changes#{
        commit=v1, change-of-a-commit=v1, change-base=v1,
        repository-read=v1, undisturbed-read=v1,
    },
    text#{conforming-program=v1},
}

Under a binding of `default-branch-name` under which the change of a
commit h has no base, when a conforming program gives the findings of
the class `needs-revision` of the change of h under that binding, and
each repository read from which it takes that the change of h has no
base is undisturbed, it must give that the change of h has no base, and
no finding of that class.

## 5. Conformance

A program, or a part of a program, conforms to this design when it is a
conforming program of this design: when it meets every requirement of
section 4.

The vectors of this design are in the file
[`revisions.test-vectors.jsonl`](revisions.test-vectors.jsonl), in the
same folder as this design. The file is a
[test-vector set](sinter:data-forms#test-vector-set=v1). A vector is an
input and what a conforming program gives for it. Each vector follows
from the requirements and adds nothing to them.

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

No vector has the member `result` or the member `needs`. The forms of
the group `trees` name no question for `result`, and the Conformance
section gives no need name.

A revision is a JSON string of `v`, then the decimal numeral of a whole
number of 1 or more, such as `"v1"`. The revisions of the vectors, of
the group, and of the set, and the numbers of new vectors, follow the
rules of version sequences of Data forms. A program does not need the
revisions to run the vectors.

In the members `input` and `values`, a text, such as a valid path, a
name, a subject, a namespace name, or an id pattern, is a JSON string
whose characters are the characters of the text, in order.

The group `trees` holds the vectors whose inputs are a base tree, a
tree, a binding of `file-readers` whose readers are all `markdown`, and
a binding of `external-namespaces`. Its requirements are
`give-needs-revision-findings`, `give-suspect-findings`, and
`omit-findings-under-invalid-bindings`. The member `input` of its
vectors is a JSON object with these four members:

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
string.

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
