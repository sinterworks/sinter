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
Specifies the base items of declared items, the finding classes `needs-revision` and `suspect`, the base tree of the change of a commit, and requirements for conforming programs that give the findings of these classes and whether the change of a commit has a base.

A label says which revised content of an item a citation rests on. When
the revised content of an item changes, its label must change too, so
that each pinned citation of the item becomes suspect and a person
checks it again. A conforming program compares a tree with a base tree,
such as the tree of the base of the change of a commit. It reports each
declared item whose revised content or kind changed while its label
stayed the same. It also reports each suspect edge of a tree.

From the Ontology (`ontology`), the design takes trees and their files,
the tree of a commit, declared items and their kinds, containment,
names, labels, current revisions, revised contents, edges, pinned edges,
suspect edges, findings, finding classes, and parameters. From Documents
(`documents`), it takes the declared items of a tree and their files,
the origins of the runs of the text of a file, the origin positions of
citation entries and inline citations, extent hashes as the measure of
revised content, sets of names, vector files, the edges of a tree, the
form runs and form positions of the edges that vector lines give,
position subjects, the spots of runs, tree findings, bindings of the
parameter `file-readers` with their readers, and sets of stopped files.
From Changes (`changes`), it takes commits, the files of the tree of a
commit, the change of a commit, the base of the change of a commit under
a binding of the parameter `default-branch-name`, and undisturbed
repository reads. From Data forms (`data-forms`), it takes test-vector
sets, vector lines, the forms of a group, the meaning of a vector, and
hex texts.
From Findings (`findings`), it takes the subjects, spots, messages,
marks, related messages, and fixes of findings, and ackable findings.
From Identifiers (`identifiers`), it takes declarations, the production
`label`, the texts of tag lines, citation entries, inline citations,
slugs, bindings of the parameter `external-namespaces` with their
namespace names and id patterns, and the result "valid" of such a
binding. From Files and paths (`files`), it takes valid paths and path
sets. From Text and notation (`text`), it takes characters, texts,
boundaries, spans, valid UTF-8, code point order, code spans, decimal
numerals, and what a conforming program and a result are. From RFC 8259,
it takes JSON values, with their objects, members, arrays, strings, and
numbers.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [tree](sinter:ontology#tree=v1) | a set of files, each a valid path with a content, such as the tree of a commit or the tree of a working tree |
| base tree | the tree with which a conforming program compares a tree, such as the tree of the base of the change of a commit |
| [label](sinter:ontology#revised-content=v1) | for a declared item, the text that `label` of Identifiers matches in its declaration, such as `v2` in `@req size=v2` |
| [label of an edge](sinter:ontology#pinned-edge=v1) | for a pinned edge, the revision of its citation entry or inline citation, such as `v2` in `@cites billing#size=v2`, or the schema label of the form of its vector line, such as `v1` in `"form":"#g-vector=v1"` |
| [current revision](sinter:ontology#item-revision=v1) | the label that an item has in a tree; a term with no label has no current revision |
| [revised content](sinter:ontology#revised-content=v1) | the part of an item that its label covers, or would cover for a term with no label |
| [extent hash](sinter:documents#extent-hash=v1) | the hash of the hash text that Documents gives for a declared item from its revised content; two revised contents of the same declared item, in two trees under one binding of each parameter, are the same when, and only when, the extent hashes of that item in the two trees are equal |
| [set of names](sinter:documents#name-set=v1) | one of the sets of declared items of a tree in which names are looked up: the shared set and the set of each item of the kind design |
| [base item](sinter:#base-item=v1) | the declared item of the base tree with which a declared item of the tree is compared: the one item with the same name in the corresponding set of names, of any kind, when the item of the tree is also the one item with its name in its set of names |
| [form run](sinter:documents#tree-edge=v1), [form position](sinter:documents#tree-edge=v1) | for an edge that a vector line gives, the run of the text of its vector file between the opening and closing quotes of the JSON string of the value of `form`, and the position where that run starts |
| [suspect edge](sinter:ontology#suspect-edge=v1) | a pinned edge that has a cited item in the tree and whose cited item has no current revision, or has a current revision other than the label of the edge |
| [set of stopped files](sinter:documents#unreadable-file=v1) | a set of read files of a tree that a program takes as an input of its own: the markdown files whose reading it stops for limits of its own, and the code files to whose reading it gives the result "parse failure" for limits of its own; a file in it cannot be read |
| [tree finding](sinter:documents#tree-finding=v1) | a finding of one tree, with a class, a subject, and a spot, that is not ackable |
| [`needs-revision`](sinter:#needs-revision-finding=v1) | the class of the findings of a declared item of a tree whose revised content or kind changed against the base tree while its label stayed the same |
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
atom `needs-revision-finding` gives which declared items of the tree
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
cannot be read, such as a file in the set of stopped files of the tree,
is not a declared item of its tree, so it has no base item and it is no
base item.

### 2.3 Suspect edges

A tree has one finding of the class `suspect` for each suspect edge of
the tree, such as the edge of `@cites billing#size=v2` when
`billing#size` has the current revision `v3`. A finding of the class
`suspect` needs no base tree. A pinned edge whose cited item is a term
with no label is always suspect. For example, in the vector file of a
design, the edge that the vector line
`{"form":"#g-vector=v1","group":"g","input":1,"values":{}}` gives is
suspect by the atom `ontology#suspect-edge` when the schema `g-vector`
that the design holds directly has the current revision `v2`, and the
finding for that edge takes its subject from the form position and its
spot from the form run `#g-vector=v1` that the term
`documents#tree-edge` gives.

### 2.4 The base tree of the change of a commit

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

### 2.5 Findings

The findings of both classes are tree findings: no finding of either
class is ackable, and the message, the mark, the related messages, and
any fix of a finding are those that the program that gives it gives. A
related message can have a spot in the base tree, such as the spot of
the declaration of the base item.

Each finding has the subject and the spot that the atom of its class
gives.

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

### 3.2 Findings of the class `needs-revision`

@atom needs-revision-finding=v1
@cites {
    identifiers#{external-namespaces=v1, declaration=v1, tag-line-text=v1},
    ontology#{
        declared-item=v1, item-name=v1, item-revision=v1, parameter=v1,
        tree=v1,
    },
    documents#{
        file-readers=v1, extent-hash=v1, item-file=v1, origin=v1,
        run-spot=v1, tree-finding=v1, unreadable-file=v1,
    },
    text#{text=v1},
    #{base-item=v1},
}

Under a binding of `file-readers`, a binding of `external-namespaces`,
and a set of stopped files of each tree, for a tree T and a base tree B,
the declared items, their kinds, names, current revisions, extent
hashes, and files of T and of B, and the base items in B of the declared
items of T, are those that T and B have under these two bindings and
their sets of stopped files. Under these bindings and sets, T has one
tree finding of the class `needs-revision` against B for each declared
item d of T that has a current revision in T and a base item e in B,
when e has a current revision in B that is the same text as the current
revision of d in T, and d and e are of different kinds of item or the
extent hash of d in T is not the extent hash of e in B. Its subject is
the name of d. Its spot is the spot of the run of the text of the
declaration of d in the text of its file in T.

### 3.3 Findings of the class `suspect`

@atom suspect-finding=v1
@refines ontology#suspect-edge=v1
@cites {
    identifiers#{
        external-namespaces=v1, citation-entry=v1, inline-citation=v1,
    },
    data-forms#{vector-line=v1},
    ontology#{edge=v1, parameter=v1, tree=v1},
    documents#{
        file-readers=v1, tree-edge=v1, origin=v1,
        origin-position=v1, position-subject=v1, run-spot=v1,
        tree-finding=v1, unreadable-file=v1,
    },
}

Under a binding of `file-readers`, a binding of `external-namespaces`,
and a set of stopped files of a tree, the tree has one tree finding of
the class `suspect` for each edge that the tree has under these bindings
and this set and that is suspect in the tree. For an edge that a
citation entry or an inline citation gives, its subject is the position
subject of the origin position of the citation entry or of the inline
citation of the edge, and its spot is the spot of the run of that
citation entry or inline citation in the text of the file of the edge.
For an edge that a vector line gives, its subject is the position
subject of its form position in the file of the edge, and its spot is
the spot of its form run in the text of the file of the edge.

## 4. Requirements

### 4.1 The findings of the class `needs-revision`

@req give-needs-revision-findings=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{finding-class=v1, tree=v1, parameter=v1},
    documents#{
        file-readers=v1, tree-finding=v1, unreadable-file=v1,
    },
    text#{conforming-program=v1, result=v1},
    #{needs-revision-finding=v1},
}

Under a valid binding of `file-readers` and a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", when a conforming program gives
the findings of the class `needs-revision` of a tree against a base tree
under these bindings and a set of stopped files of each tree, it must
give each tree finding of that class that the tree has against the base
tree under these bindings and these sets once, and no other finding of
that class.

### 4.2 The findings of the class `suspect`

@req give-suspect-findings=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{finding-class=v1, tree=v1, parameter=v1},
    documents#{
        file-readers=v1, tree-finding=v1, unreadable-file=v1,
    },
    text#{conforming-program=v1, result=v1},
    #{suspect-finding=v1},
}

Under a valid binding of `file-readers` and a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", when a conforming program gives
the findings of the class `suspect` of a tree under these bindings and
a set of stopped files, it must give each tree finding of that class
that the tree has under these bindings and this set once, and no other
finding of that class.

### 4.3 No finding under bindings that are not valid

@req omit-findings-under-invalid-bindings=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{finding-class=v1, tree=v1, parameter=v1},
    documents#{file-readers=v1},
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
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{finding-class=v1, tree=v1, parameter=v1},
    changes#{
        commit=v1, commit-file=v1, change-of-a-commit=v1,
        change-base=v1, repository-read=v1, undisturbed-read=v1,
    },
    documents#{
        file-readers=v1, tree-finding=v1, unreadable-file=v1,
    },
    text#{conforming-program=v1, result=v1},
    #{needs-revision-finding=v1},
}

Under a binding of `default-branch-name` under which the change of a
commit h has a base, a valid binding of `file-readers`, and a binding of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", when a conforming program gives
the findings of the class `needs-revision` of the change of h under
these bindings and a set of stopped files of each of the two trees, and
each repository read from which it takes the base of the change of h
and the files of the tree of h and of the tree of that base is
undisturbed, it must give each tree finding of that class that the tree
of h has against the tree of the base of the change of h under these
bindings and these sets once, and no other finding of that class.

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
same folder as this design. The file is a test-vector set, as the
specification [`test-vectors`](sinter:data-forms#test-vectors=v1) of
Data forms gives it. A vector is an input and what a conforming program
gives for it. Each vector follows from the requirements and adds nothing
to them. No group of this design uses a need, so the forms of each group
give no need names. Subsection 5.1 gives the forms of the group `trees`,
as the term [`group-form-list`](sinter:data-forms#group-form-list=v1)
gives them. No vector follows from the requirements
`compare-with-change-base`, `omit-missing-base-report`, and
`report-missing-base`.

Each vector is for the empty set of
[stopped files](sinter:documents#unreadable-file=v1) of each tree. So a
vector checks a program only when the set of stopped files of the
program for each tree of the vector is empty.

### 5.1 Trees

@schema trees-vector=v1
@cites {
    rfc/8259,
    text#{
        conforming-program=v1, text=v1, character=v1, valid-utf-8=v1,
        result=v1, code-point-order=v1, span=v1, boundary=v1,
        decimal-numeral=v1, code-span=v1,
    },
    files#{path=v1, path-set=v1},
    data-forms#{
        hex-text=v1, vector-line=v1, group-form-list=v1,
        vector-meaning=v1,
    },
    identifiers#{
        external-namespaces=v1, validate-bindings=v1, slug=v1,
    },
    ontology#{tree=v1, finding-class=v1, parameter=v1},
    findings#{spot=v1},
    documents#{file-readers=v1, tree-finding=v1, unreadable-file=v1},
    #{
        give-needs-revision-findings=v1, give-suspect-findings=v1,
        omit-findings-under-invalid-bindings=v1,
    },
}

The group `trees` holds the vectors whose inputs are a base tree, a
tree, a binding of `file-readers` whose readers are all `markdown`, and
a binding of `external-namespaces`. Its requirements are
`give-needs-revision-findings`, `give-suspect-findings`, and
`omit-findings-under-invalid-bindings`. Each vector is for the empty set
of stopped files of each tree. Each vector of the group has the member
`values`, and no vector has the member `result`; these forms name no
question for `result`. The group uses no need, so these forms give no
need names.

The JSON values, objects, arrays, strings, and numbers of this schema
are as RFC 8259 defines them. In the members `input` and `values`, a
text, such as a valid path, a name, a subject, a namespace name, or an
id pattern, is a JSON string whose characters are the characters of the
text, in order.

The member `input` of a vector of the group is a JSON object with these
four members:

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
two bindings of the input and the empty set of stopped files of each
tree, in the code point order of the slugs of their
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
tree under the two bindings of the input and the empty set of stopped
files of each tree, it gives one for each element of `findings` of that
class, with the subject that the element states, and no other; and when
it gives the findings of the class `suspect` of the tree under these
bindings and the empty set of stopped files, it gives one for each element of
`findings` of that class, with the subject that the element states, and
no other. When it gives the spot of such a finding, it gives the spot
that the element states.
