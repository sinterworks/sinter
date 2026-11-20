<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Approval
@design approval=v1
@cites text=v1
@cites identifiers=v1
@cites files=v1
@cites data-forms=v1
@cites ontology=v1
@cites changes=v1
@cites findings=v1
@cites documents=v1
@cites ledger=v1
@cites rfc/5234
@cites rfc/7405
@cites rfc/8259
Specifies the subjects of approval that need approval by a person; the fields of the ledger entries of the kinds `approval` and `decline`, and their acceptance rule; the latest judgment of a subject of approval; the rule for merges; the states approved and declined of subjects of approval; the finding classes `declined`, `awaiting-approval`, and `unapproved-req`; and requirements for conforming programs that give these states, acceptance, and findings, and that append `approval` and `decline` ledger entries.

A person approves or declines the revised content of a subject of
approval, such as the text of an item of the kind requirement. A binding
of the parameter `approval-kinds` says which kinds of subject of
approval need approval by a person. For such a kind, the latest judgment
of a subject of approval and of the revised content that the subject of
approval has in a tree decides the state of that subject of approval.
For each other kind, a merge into the default branch approves it. An
`approval` or `decline` ledger entry names its subject of approval by
the kind word of its kind of subject of approval and the name of its
declared item, such as `req:billing#limit`, and its revised content by
an extent hash. The fields of these two kinds also include `saw` (schema
`judgment-field`). The acceptance rule and the requirement
`record-seen-judgments` limit the value of `saw` (section 2.2).

From the Ontology (`ontology`), the design takes subjects of approval,
their seven kinds, their declared items, and when two subjects of
approval are the same subject of approval; schemas and atoms; revised
content; persons, ledger entries, the ledger, points of a ledger, and
repairs; states, the states approved and declined, and in force; trees,
the default branch, edges with their kinds and cited items, and when an
edge says what its kind of edge says; findings, finding classes, and
parameters with their bindings; and the requirement
`ontology#treat-ledger-entries-alike`.

From the Ledger (`ledger`), the design takes the fields of a kind of
ledger entry and the common fields, acceptance rules, and when a ledger
entry is accepted at a point; the ledger of a git repository, which is
the stored ledger of that git repository; and when that ledger is broken
or newer, and the ledger objects of a git repository; clones, the shared
clone, pulls, pushes, and the ledger entries that leave in a pull; and
the requirements `ledger#append-only-accepted-entries`,
`ledger#give-states-only-from-valid-ledgers`, and
`ledger#report-leaving-entries`.

From Documents (`documents`), the design takes the declared items of a
tree with their files and declarations, the bindings of the parameter
`file-readers`, sets of stopped files, extent hashes, the edges of a
tree, origins and origin positions, position subjects, the order of
positions, the spots of runs, and tree findings. From Changes
(`changes`), the design takes commits and their parents, the files of
the tree of a commit, the parameter `default-branch-name` with its
bindings, the commit of the default branch, first-parent lines, and
shallow commits. From Findings (`findings`), the design takes the
subjects of findings. From Identifiers (`identifiers`), the design takes
slugs, full names, kind words, citation entries, inline citations,
status tags, the texts of tag
lines, the form of `@ack` lines with its production `subject`, the
parameter `external-namespaces` with its bindings, and the results that
a conforming program of Identifiers gives. From Files and paths
(`files`), the design takes valid paths. From Data forms (`data-forms`),
the design takes JSON values with their objects, members, and strings;
the index of an element of a finite sequence; the hash form; the forms
of a group and the meaning of a vector; and test-vector sets. The file
that holds the conformance vectors of the design is a test-vector set.
From Text and notation (`text`), the design takes texts, code point
order, the notation of productions, and what a conforming program, an
input, and a result are.

The production `subject-text` is written in ABNF, the notation of RFC
5234, with the case-sensitive strings `%s"…"` of RFC 7405. From RFC
8259, the design takes JSON values, with their objects, members, arrays,
strings, numbers, and the literal names `true` and `false`.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [subject of approval](sinter:ontology#subject-of-approval=v1) | a unit that a person approves, or that the merge approves, as a whole |
| [kind of subject of approval](sinter:ontology#subject-of-approval=v1) | which of seven units a subject of approval is: an item of the kind design without the declared items that it holds, an item of the kind specification with the schemas, the items of the kind requirement, the atoms, and the terms that it holds, a schema that an item of the kind design holds directly, an item of the kind requirement that an item of the kind design holds directly, an atom that an item of the kind design holds directly, a term that an item of the kind design holds directly, or a decision record |
| [declared item of a subject of approval](sinter:ontology#subject-of-approval=v1) | the item of the kind design, for a subject of approval of the first kind, and otherwise the item of the kind specification, the schema, the item of the kind requirement, the atom, the term, or the decision record that the subject of approval is |
| [subject of approval of a declared item](sinter:ontology#subject-of-approval=v1) | for an item of the kind design, an item of the kind specification, a schema, an item of the kind requirement, an atom, or a term that an item of the kind design holds directly, or a decision record, the subject of approval whose declared item it is; for a schema, an item of the kind requirement, an atom, or a term that an item of the kind specification holds, the subject of approval of that item of the kind specification; each other declared item has none |
| [same subject of approval](sinter:ontology#subject-of-approval=v1) | two subjects of approval of two trees are the same when their declared items have the same kind of item and the same name |
| [revised content](sinter:ontology#revised-content=v1) | the part of an item that its label covers, such as the text of an item of the kind requirement |
| [extent hash](sinter:documents#extent-hash=v1) | the hash that measures the revised content of a declared item of a tree: two revised contents of the same declared item are the same when, and only when, their extent hashes are equal |
| [hash form](sinter:data-forms#hash-form=v1) | the form of a text of exactly 64 hex digits, which a hash has |
| [binding of `approval-kinds`](sinter:#approval-kinds=v1) | a set of kinds of subject of approval |
| [need approval](sinter:#approval-need=v1) | a subject of approval needs approval by a person under a valid binding of `approval-kinds` when its kind is in that binding |
| [kind word of a kind of subject of approval](sinter:#subject-text=v1) | `design` for an item of the kind design without the declared items that it holds, `spec` for an item of the kind specification with the items that it holds, `schema` for a schema that an item of the kind design holds directly, `req` for an item of the kind requirement that an item of the kind design holds directly, `atom` for an atom that an item of the kind design holds directly, `term` for a term that an item of the kind design holds directly, and `decision` for a decision record |
| [subject text](sinter:#subject-text=v1) | a text that matches the production `subject-text`, such as `req:billing#limit`; the subject text of a subject of approval of a tree is the kind word of its kind of subject of approval, `:`, and the name of its declared item in that tree |
| [judgment](sinter:ontology#judgment=v1) | a ledger entry that records a decision of a person: a ledger entry of the kind `approval`, `decline`, `done`, or `abandoned` |
| an approval, a decline | with an article: a ledger entry of the kind `approval`; a ledger entry of the kind `decline`; without an article, "approval" is the act of a person who approves |
| [field of a kind](sinter:ledger#entry-field=v1) | a member of the object of a ledger entry that a design names for the kind of that ledger entry, other than the common fields, such as `subject` |
| [fields of an `approval` or `decline` ledger entry](sinter:#judgment-field=v1) | `subject`, a string that is a subject text; `hash`, a string that fits the hash form; `saw`, one of the strings `none`, `approval`, and `decline`; and, for a decline only, the optional `reason`, a string |
| [acceptance rule](sinter:ledger#accepted-entry=v1), [accepted](sinter:ledger#accepted-entry=v1) | the condition under which a ledger entry of one kind can stand at a point of a ledger; a ledger entry is accepted at a point when the acceptance rule of its kind holds for it there |
| [index in a ledger](sinter:#ledger-index=v1), [point of an index](sinter:#ledger-index=v1) | the number, counted from 1, of an element of the sequence of a ledger; the point of the index k is the point of the first k − 1 ledger entries; the indexes before the point of the first n ledger entries are the indexes 1 to n |
| [count at an index](sinter:#judgment-acceptance-rule=v1) | the ledger entry at an index counts at that index when it is of the kind `approval` or `decline` and is accepted at the point of that index |
| [judgment before a ledger entry at a point](sinter:#judgment-acceptance-rule=v1) | of a ledger entry E of the kind `approval` or `decline` at a point P: the ledger entry at the greatest index before P at which the ledger entry counts and has the values of `subject` and `hash` of E, or none; none when E lacks `subject` or `hash` |
| [acceptance rule of `approval` and `decline`](sinter:#judgment-acceptance-rule=v1) | the acceptance rule holds for a ledger entry E of the kind `approval` or `decline` at a point P when the `saw` of E is the kind of the judgment before E at P, or `none` when there is no judgment before E at P, and, when E is an approval, the `saw` of E is not `approval` |
| [set of stopped files](sinter:documents#unreadable-file=v1) | a set of files of a tree that a program takes as an input of its own: the markdown files whose reading the program stops for limits of its own, the code files for whose reading the program gives the result "parse failure" for limits of its own, and the files of the tree whose content the program stops reading as a test-vector set for limits of its own; any set of files of a tree can be a set of stopped files |
| [latest judgment](sinter:#latest-judgment=v1) | of a subject of approval of a tree at a point of a ledger, under a binding of `file-readers`, a binding of `external-namespaces`, and a set of stopped files of the tree: of the ledger entries of the kind `approval` or `decline` that count at their indexes before the point and that name the subject text and the extent hash that the subject of approval has in the tree under those bindings and that set, the one at the greatest index, or none |
| [first-parent line](sinter:changes#first-parent-line=v1) | the sequence of commits that starts with a commit and goes on, from each commit, to its first parent, until a commit with no parent |
| [shallow commit](sinter:changes#shallow-commit=v1) | a commit of a git repository that the file `shallow` of its git folder names |
| [commit of the default branch](sinter:changes#default-branch-commit=v1) | the commit that the default branch has, under a binding of `default-branch-name` |
| [has merged](sinter:#merged-content=v1) | under bindings of `default-branch-name`, `file-readers`, and `external-namespaces`, and one set of stopped files of each tree that is a tree T or, when the default branch of a git repository has a commit, is the tree of a commit of the first-parent line of that commit, the revised content of a subject of approval in T has merged into the default branch of that git repository when the default branch of that git repository has a commit, and the tree of a commit of that first-parent line gives the same subject of approval the same extent hash under those bindings and those sets |
| [approved, declined, neither](sinter:#subject-state=v1) | the three states of a subject of approval in a tree T, at a point of the ledger of a git repository, under the bindings of the parameters and one set of stopped files of each tree that is T or, when the default branch of that git repository has a commit, is the tree of a commit of the first-parent line of that commit |
| [in force](sinter:ontology#in-force-item=v1) | a declared item is in force in a tree, at a point of a ledger, when it is not retired there: when it still applies |
| [in force under the bindings](sinter:#bound-in-force-item=v1) | in force as the atom `ontology#in-force-item` gives it, where the state approved of the source of each `supersedes` edge follows from the states that the atom `subject-state` gives, and where each declared item, status tag, and edge is read under the bindings of `file-readers` and `external-namespaces` and the set of stopped files of the tree |
| [subject order](sinter:#subject-order=v1) | the order of the subjects of approval of a tree by the valid paths of the files of their declared items, and then by the positions of the declarations of those declared items |
| [tree finding](sinter:documents#tree-finding=v1) | a finding of a tree with a given class, a given subject, and a given spot or no spot, that is not ackable |
| [subject of a finding](sinter:findings#finding-subject=v1) | the text that names what a finding is about |
| [position subject](sinter:documents#position-subject=v1) | the subject of a finding at a position, such as `src/fee.ml@L3C4` |

## 2. Judgments and approval states

### 2.1 Subjects that need approval

The parameter `approval-kinds` gives the kinds of subject of approval
that need approval by a person (schema `approval-kinds` and term
`approval-need`). For example, under the binding of the two kinds of
subject of approval whose kind words are `spec` and `req`, the subject
of approval `req:billing#limit` needs approval, and the subject of
approval `design:billing` does not. Under the empty binding, no subject
of approval needs approval.

A subject of approval has a subject text (term `subject-text`). For
example, the item of the kind requirement `billing#limit` that the item
of the kind design `billing` holds directly has the subject text
`req:billing#limit`, and the item of the kind design `billing` has the
subject text `design:billing`. An item of the kind requirement that an
item of the kind specification holds is no subject of approval. The
subject of approval of that item of the kind requirement is the subject
of approval of that item of the kind specification. Two subjects of
approval of two trees are the same subject of approval when, and only
when, those two subjects of approval have the same subject text, because
the kind word of the kind of subject of approval gives the kind of item,
and the name is the name of the declared item. So a renamed item is
another subject of approval.

### 2.2 The fields of `approval` and `decline` ledger entries

The ledger entries of the kinds `approval` and `decline` are judgments.
The schema `judgment-field` gives their fields and the form of each. For
example, this is the object of an approval, with the common fields of
the Ledger:

```
{"by":"Ada Lovelace <ada@example.com>","hash":"50d858e0985ecc7f60418aaf0cc5ab587f42c2570a884095a9e8ccacd0f6545c","id":"e-6cff3eb61833","kind":"approval","saw":"none","seq":12,"subject":"req:billing#limit","v":1}
```

The field `subject` names the subject of approval by its subject text.
The field `hash` names the revised content by the extent hash of that
revised content. That extent hash is the extent hash of the declared
item of the subject of approval in the tree in which the subject of
approval has the revised content that the person approved or declined
(requirement `record-judged-content`). After an edit back to a revised
content that a person approved or declined, the latest judgment of the
subject of approval can be the same ledger entry again, and that ledger
entry decides the state again.

Conditions 1 and 2 of the acceptance rule (atom
`judgment-acceptance-rule`) and the requirement `record-seen-judgments`
limit the value of `saw` at the point at which a program appends the
ledger entry. Conditions 1 and 2 of the acceptance rule limit that value
because a program appends only accepted ledger entries (requirement
`ledger#append-only-accepted-entries`). The field `reason` of a decline
can hold a reason that the person gave. No state and no acceptance
depends on the member `reason`, whatever its value.

### 2.3 Acceptance

Each kind of ledger entry that a program appends has an acceptance rule
(term `ledger#accepted-entry`). The atom `judgment-acceptance-rule`
gives the rule of the kinds `approval` and `decline`. That rule reads
only the ledger entry itself and the ledger entries before the point,
never a tree, a binding, or a commit. The rule's condition on `saw`
reads the judgment before the ledger entry at the point. Of that
judgment, the rule uses only the kind of that judgment. The judgment
before a ledger entry is one ledger entry. That judgment counts at its
index. An `approval` or `decline` ledger entry that does not count at
its index is never the judgment before another ledger entry. The
requirement `record-seen-judgments` names that one ledger entry, and not
only the kind of that ledger entry. To give the person an `approval` or
`decline` ledger entry that does not count at its index does not meet
that requirement. A program appends a ledger entry only at a point at
which that ledger entry is accepted (requirement
`ledger#append-only-accepted-entries`). Each index of a ledger has its
own point (term `ledger-index`). The ledger entry at an index counts at
that index when that ledger entry is accepted at the point of that index
(atom `judgment-acceptance-rule`). Whether the ledger entry at an index
counts there follows from the ledger entry itself and the ledger entries
before it, in the order of the ledger.

These cases show the rule. In each case, X is one subject text and one
hash.

1. Clone A appends an approval of X. At the point of that approval in A,
   there was no judgment before that approval, so the approval has `saw`
   `none`. Before A pushes, clone B pushes a decline of X with `saw`
   `none`. After the pull, the decline of B comes first, and the
   approval is not accepted at its new point. So that approval leaves
   the ledger in the pull, the pull reports that approval (requirement
   `ledger#report-leaving-entries`), and the person decides again.
2. A person declines X, and later approves X on purpose. The approval
   has `saw` `decline`, and it is accepted.
3. Two clones each approve X with `saw` `none` before either pushes.
   After the pull, the second approval is not accepted at its new point.
   An approval with `saw` `approval` is never accepted either. So no
   accepted approval of X has an approval as the judgment before that
   accepted approval at the point of that accepted approval.
4. A person declines X twice, with two reasons. The second decline has
   `saw` `decline`, and it is accepted.
5. A person approves X, and later declines it. The decline has `saw`
   `approval`, and it is accepted. A decline with `saw` `none` after
   that approval is not accepted.
6. A ledger holds a decline D1 of X. Clone A appends an approval of X
   with `saw` `decline`. Before A pushes, clone B appends a second
   decline D2 of X with `saw` `decline` and pushes D2. A pulls. After
   the pull, D2 comes before the approval. The approval is accepted at
   its new point because the `saw` of the approval is the kind of D2. So
   an approval can stand after a decline that the program did not give
   the person, when the program gave that person another decline of X.

Only an `approval` or `decline` ledger entry that counts at the index
where it stands can decide a state (term `latest-judgment`). So such a
ledger entry that is not accepted at the point of its index, such as a
repeated approval that a program that does not conform appended, decides
no state. When a repair removes an `approval` or `decline` ledger entry,
each later `approval` or `decline` ledger entry of the same subject text
and hash is accepted, or not accepted, by the ledger entries that remain
before that later ledger entry.

### 2.4 The latest judgment and the states

A subject of approval of a tree has, at a point of a ledger, a latest
judgment, or none (term `latest-judgment`). The atom `subject-state`
gives the three states approved, declined, and neither. The states
approved and declined that the atom `subject-state` gives are the states
of subjects of approval that the term `ontology#approval-state` names.

For a subject of approval that needs approval, the latest judgment
decides. For example, a ledger holds an approval of `req:billing#limit`
with the extent hash H1, then an approval with the extent hash H2. In a
tree in which the requirement has the extent hash H1, that requirement
is approved. In a tree in which the requirement has the extent hash H2,
that requirement is approved. In a tree in which the requirement has a
third extent hash, that requirement is neither approved nor declined.

For a subject of approval that does not need approval, the merge decides
(term `merged-content`). An `approval` or `decline` ledger entry of such
a subject of approval changes no state while the binding stays the same.
Under another binding, in which the kind of that subject of approval
needs approval, the same ledger entry can decide the state.

Only `seq` orders `approval` and `decline` ledger entries, because it
gives the order of the ledger. The writer, the person, the branch, and
the time of a ledger entry change no state (requirement
`ontology#treat-ledger-entries-alike`). So an approval can decide a
state whatever person that approval records. The `approval` and
`decline` ledger entries that a pull brought from another clone decide
states as the `approval` and `decline` ledger entries of the clone
itself do. An `approval` or `decline` ledger entry that a clone holds
and for which the shared clone of that clone does not account can decide
a state in that clone.

### 2.5 Merges

The rule for merges (term `merged-content`) reads the first-parent line
of the commit of the default branch. A merge commit, a squash merge, and
a commit made straight on the default branch each put their tree on that
line. So revised content that came into the default branch in one of
these ways has merged. A commit that the default branch reaches only
through the second parent of a merge commit is not on the line. So when
the default branch fast-forwards to a commit whose first-parent line
leaves out earlier commits of the default branch, revised content that
only those earlier commits held has not merged. When a person moves the
default branch back, revised content that only the commits that left the
line held has not merged.

When the default branch has no commit, no revised content has merged.

### 2.6 Bindings and missing inputs

The extent hashes that a state uses, in the tree and in the trees of the
commits of the first-parent line, are those that one binding of
`file-readers`, one binding of `external-namespaces`, and one set of
stopped files of each tree among them give. When two commits of the
first-parent line have the same tree, or when the checked tree is the
tree of a commit of that first-parent line, that tree has one set of
stopped files in every place where the state reads that tree. The state
is under one binding of `approval-kinds` (atom `subject-state`). The
commit of the default branch is the commit that one binding of
`default-branch-name` gives (atom `subject-state`). The states and the
findings are of a tree at a point of the ledger of one git repository.
The rule for merges reads the default branch of that git repository. The
requirement `give-no-states-under-invalid-bindings` covers bindings of
`file-readers` and of `external-namespaces` that are not valid. The
requirement `ledger#give-states-only-from-valid-ledgers` covers a ledger
that is broken or newer and a git repository that does not hold its
ledger objects, also for a kind that does not need approval. The
requirement `give-no-findings-from-invalid-ledgers` covers the findings
for such a ledger and such a git repository. When a git repository lacks
the git objects that a tree of the first-parent line needs, or when a
commit of the first-parent line is a shallow commit, by the requirement
`give-subject-states`, a program gives the state that the atom
`subject-state` gives, or gives no state. When a git repository lacks
the git objects that a tree of the first-parent line needs, or when a
commit of the first-parent line is a shallow commit, by the requirement
`give-approval-findings`, a program gives the findings of a class that
the atom of that class gives, or does not give the findings of that
class.

What a program gives while another process changes a file, a ref, or
the ledger is a matter of the quality of an implementation.

### 2.7 Findings

Each of these classes has an atom that gives the findings of that class
at a point of a ledger, under the bindings of the parameters and one set
of stopped files of each tree that the atom reads. Each of those
findings is a
[tree finding](sinter:documents#tree-finding=v1). No finding of these
classes is ackable.

| class | atom |
|---|---|
| `declined` | [`declined-finding`](sinter:#declined-finding=v1) |
| `awaiting-approval` | [`awaiting-approval-finding`](sinter:#awaiting-approval-finding=v1) |
| `unapproved-req` | [`unapproved-req-finding`](sinter:#unapproved-req-finding=v1) |

The subject of a finding of the class `declined` or `awaiting-approval`
is a subject text, such as `req:billing#limit`. A subject text matches
the production `subject` of the schema `identifiers#ack-line` and holds
no line feed. So a subject text is a subject of a finding (term
`findings#finding-subject`). Each of the three classes reports only a
subject of approval whose declared item is in force under the bindings,
or an edge whose cited item is in force under the bindings (term
`bound-in-force-item`). So a retired item gives no finding of these
classes. A subject of approval that is declined gives no finding of the
class `awaiting-approval`. When the declared items of two subjects of
approval of one tree have the same kind of item and the same name, those
two subjects of approval have the same subject text. So those two
subjects of approval give at most one finding of each class. The spot of
that finding is the spot of the first subject of approval of the tree
with that subject text in the subject order (term `subject-order`),
whatever the state of that first subject of approval is and whether the
declared item of that first subject of approval is in force. So the spot
does not depend on the ledger or on the states. Two such subjects of
approval can give a finding of the class `declined` and a finding of the
class `awaiting-approval`: both subjects of approval are in force, one
of those subjects of approval is declined, and the other subject of
approval needs approval and is neither.

The subject of a finding of the class `unapproved-req` is the position
subject of the citation entry of the edge of that finding, such as
`src/fee.ml@L3C4` (term `documents#position-subject`). An inline
citation and a vector line give only edges of the kind `cites`. So an
inline citation and a vector line give no finding of the class
`unapproved-req`.

## 3. Parameters

### 3.1 `approval-kinds`

@schema approval-kinds=v1
@cites {
    ontology#{subject-of-approval=v1, parameter=v1},
    text#{code-span=v1},
}

A binding of the parameter `approval-kinds` is a set of kinds of subject
of approval. The empty set is a binding. Every binding of
`approval-kinds` meets the schema `approval-kinds`.

## 4. Definitions

### 4.1 Subjects that need approval

@term approval-need=v1
@cites {
    ontology#{subject-of-approval=v1, person=v1, parameter=v1},
    text#{code-span=v1},
    #{approval-kinds=v1},
}

Under a valid binding A of `approval-kinds`, a subject of approval needs
approval by a person when, and only when, its kind is in A.

### 4.2 Subject texts

@term subject-text=v1
@cites {
    rfc/5234,
    rfc/7405,
    identifiers#{slug=v1, full-name=v1, kind-word=v1},
    ontology#{
        subject-of-approval=v1, declared-item=v1, item-name=v1, tree=v1,
        schema=v1, atom=v1, term=v1, decision-record=v1, containment=v1,
    },
    text#{text=v1, production=v1, rule-name=v1, code-span=v1},
}

A subject text is a text that matches the production `subject-text`:

```abnf
subject-text  = ( %s"design" / %s"decision" ) ":" slug
              / ( %s"spec" / %s"schema" / %s"req" / %s"atom" / %s"term" )
                ":" ( slug / full-name )
```

The seven texts `design`, `spec`, `schema`, `req`, `atom`, `term`, and
`decision` are kind words of Identifiers. In a subject text, each of
those seven texts names a kind of subject of approval. The kind word of
a kind of subject of approval is `design` for an item of the kind design
without the declared items that it holds, `spec` for an item of the kind
specification with the items that it holds, `schema` for a schema that
an item of the kind design holds directly, `req` for an item of the kind
requirement that an item of the kind design holds directly, `atom` for
an atom that an item of the kind design holds directly, `term` for a
term that an item of the kind design holds directly, and `decision` for
a decision record. The subject text of a subject of approval of a tree
is the kind word of its kind of subject of approval, then `:`, then the
name of its declared item in that tree.

### 4.3 The fields of `approval` and `decline` ledger entries

@schema judgment-field=v1
@cites {
    ledger#{entry-field=v1},
    data-forms#{json-value=v1, hash-form=v1},
    ontology#{ledger-entry=v1},
    text#{text=v1, code-span=v1},
    #{subject-text=v1},
}

The fields of the kind `approval` and of the kind `decline` are these,
with these values:

- `subject`, a string that is a subject text;
- `hash`, a string that fits the hash form;
- `saw`, one of the strings `none`, `approval`, and `decline`.

A ledger entry of the kind `decline` can also have the field `reason`, a
string.

### 4.4 Indexes in a ledger

@term ledger-index=v1
@cites {
    ontology#{ledger=v1, ledger-entry=v1},
    data-forms#{index=v1},
    text#{whole-number=v1},
}

An index in a ledger is the index of an element of the sequence of the
ledger. The point of the index k is the point of the first k − 1 ledger
entries. The indexes before the point of the first n ledger entries are
the indexes 1 to n.

### 4.5 The acceptance rule of `approval` and `decline` ledger entries

@atom judgment-acceptance-rule=v1
@refines ledger#accepted-entry=v1
@cites {
    ontology#{ledger=v1, ledger-entry=v1},
    data-forms#{json-value=v1},
    text#{code-span=v1},
    #{judgment-field=v1, ledger-index=v1},
}

The ledger entry at the index k of a ledger counts at that index when,
and only when, it is of the kind `approval` or `decline` and is accepted
at the point of the index k.

For a ledger entry E of the kind `approval` or `decline` and a point P
of a ledger, the judgment before E at P is the ledger entry at the
greatest index k before P for which two conditions are true. First, the
ledger entry at the index k counts at that index. Second, the values of
`subject` and `hash` of the ledger entry at the index k are the values
of `subject` and `hash` of E. E has no judgment before E at P when E
lacks the member `subject` or the member `hash`, or when there is no
index k before P for which both conditions are true.

The acceptance rule of the kinds `approval` and `decline` holds for a
ledger entry E of one of these kinds at a point P of a ledger when, and
only when, each of these is true:

1. When E has a judgment before E at P, the value of `saw` of E is the
   kind of that judgment. When E has no judgment before E at P, the
   value of `saw` of E is `none`.
2. When E is of the kind `approval`, the value of `saw` of E is not
   `approval`.

### 4.6 Latest judgments

@term latest-judgment=v1
@cites {
    data-forms#{json-value=v1, index=v1},
    ontology#{
        subject-of-approval=v1, ledger=v1, ledger-entry=v1, tree=v1,
    },
    identifiers#{external-namespaces=v1},
    documents#{extent-hash=v1, file-readers=v1, unreadable-file=v1},
    text#{code-span=v1},
    #{
        subject-text=v1, judgment-field=v1, ledger-index=v1,
        judgment-acceptance-rule=v1,
    },
}

This term is for a tree T, a binding F of `file-readers`, a binding N of
`external-namespaces`, a set of stopped files of T, a subject of
approval S that T has under F, N, and that set of stopped files, and a
point P of a ledger. The latest judgment of S at P under F, N, and that
set of stopped files is the ledger entry at the greatest index k before
P for which all three of these conditions are true:

1. The ledger entry at the index k counts at that index.
2. The value of `subject` of the ledger entry at the index k is the
   subject text of S in T.
3. The value of `hash` of the ledger entry at the index k is the extent
   hash of the declared item of S in T under F, N, and that set of
   stopped files.

S has no latest judgment at P under F, N, and that set of stopped files
when there is no index k before P for which all three conditions are
true.

### 4.7 The rule for merges

@term merged-content=v1
@cites {
    changes#{
        commit=v1, commit-file=v1, default-branch-commit=v1,
        first-parent-line=v1,
    },
    ontology#{
        subject-of-approval=v1, revised-content=v1, default-branch=v1,
        tree=v1, parameter=v1,
    },
    identifiers#{external-namespaces=v1},
    documents#{extent-hash=v1, file-readers=v1, unreadable-file=v1},
    text#{code-span=v1},
}

This term is for a git repository R, a tree T, a binding D of
`default-branch-name`, a binding F of `file-readers`, a binding N of
`external-namespaces`, and, for each tree U that is T or, when the
default branch of R has a commit H under D, is the tree of a commit of
the first-parent line of H, one set of stopped files of U. Each such
tree U has that one set as the set of stopped files of U, also when two
commits of that first-parent line have the same tree or when T is the
tree of a commit of that first-parent line. For a subject of approval S
that T has under F, N, and the set of stopped files of T, the revised
content of S in T has merged into the default branch of R under D, F, N,
and these sets of stopped files when, and only when, two conditions are
true. First, the default branch of R has a commit H under D. Second,
some commit C of the first-parent line of H has a tree that has, under
F, N, and the set of stopped files of the tree of C, a subject of
approval S2 that is the same subject of approval as S, and in the tree
of C the declared item of S2 has, under F, N, and the set of stopped
files of the tree of C, the extent hash that the declared item of S has
in T under F, N, and the set of stopped files of T. When the default
branch of R has no commit under D, the revised content of no subject of
approval has merged into the default branch of R under D, F, N, and
these sets of stopped files.

### 4.8 The states of subjects of approval

@atom subject-state=v1
@refines ontology#approval-state=v1
@cites {
    ontology#{
        subject-of-approval=v1, tree=v1, ledger=v1, state=v1,
        default-branch=v1, parameter=v1,
    },
    identifiers#{external-namespaces=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-commit=v1,
        first-parent-line=v1,
    },
    ledger#{stored-ledger=v1},
    documents#{file-readers=v1, unreadable-file=v1},
    text#{code-span=v1},
    #{
        approval-kinds=v1, approval-need=v1, latest-judgment=v1,
        merged-content=v1,
    },
}

This atom is for a git repository R, a valid binding A of
`approval-kinds`, a binding D of `default-branch-name`, a binding F of
`file-readers`, a binding N of `external-namespaces`, a tree T, a point
P of the ledger of R, and, for each tree U that is T or, when the
default branch of R has a commit H under D, is the tree of a commit of
the first-parent line of H, one set of stopped files of U. Each such
tree U has that one set as the set of stopped files of U, also when two
commits of that first-parent line have the same tree or when T is the
tree of a commit of that first-parent line. Each subject of approval S
that T has under F, N, and the set of stopped files of T is in exactly
one of the states approved, declined, and neither, in T at P under A, D,
F, N, and these sets of stopped files:

- When S needs approval under A, S is approved when, and only when, the
  latest judgment of S at P under F, N, and the set of stopped files of
  T is of the kind `approval`. When S needs approval under A, S is
  declined when, and only when, the latest judgment of S at P under F,
  N, and the set of stopped files of T is of the kind `decline`. When S
  needs approval under A, S is neither when, and only when, S has no
  latest judgment at P under F, N, and the set of stopped files of T.
- When S does not need approval under A, S is approved when, and only
  when, the revised content of S in T has merged into the default branch
  of R under D, F, N, and these sets of stopped files. When S does not
  need approval under A, S is neither when the revised content of S in T
  has not merged into the default branch of R under D, F, N, and these
  sets of stopped files. When S does not need approval under A, S is
  never declined.

The states approved and declined that this atom gives are the states
approved and declined of S in T at P that the term
`ontology#approval-state` names. A subject of approval that is neither
is neither approved nor declined.

### 4.9 In force under the bindings

@term bound-in-force-item=v1
@cites {
    ontology#{
        declared-item=v1, in-force-item=v1, retired-item=v1,
        effective-supersedes-edge=v1, supersedes-edge=v1,
        approval-state=v1, edge=v1, tree=v1, ledger=v1, parameter=v1,
    },
    identifiers#{external-namespaces=v1, status-tag=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-commit=v1,
        first-parent-line=v1,
    },
    ledger#{stored-ledger=v1},
    documents#{file-readers=v1, unreadable-file=v1},
    text#{code-span=v1},
    #{approval-kinds=v1, subject-state=v1},
}

This term is for a git repository R, a valid binding A of
`approval-kinds`, a binding D of `default-branch-name`, a binding F of
`file-readers`, a binding N of `external-namespaces`, a tree T, a point
P of the ledger of R, and, for each tree U that is T or, when the
default branch of R has a commit H under D, is the tree of a commit of
the first-parent line of H, one set of stopped files of U. Each such
tree U has that one set as the set of stopped files of U, also when two
commits of that first-parent line have the same tree or when T is the
tree of a commit of that first-parent line. A declared item that T has
under F, N, and the set of stopped files of T is in force in T at P
under A, D, F, N, and these sets of stopped files when, and only when,
that declared item is in force in T at P (atom
`ontology#in-force-item`), read as this term gives. The atoms
`ontology#effective-supersedes-edge` and `ontology#retired-item` read
the state approved of the source of each `supersedes` edge. That state
follows, by the term `ontology#approval-state`, from the states that the
atom `subject-state` gives for R, T, and P under A, D, F, N, and these
sets of stopped files. When any of the atoms `ontology#in-force-item`,
`ontology#effective-supersedes-edge`, and `ontology#retired-item` reads
a declared item, a status tag, or an edge, that atom reads that declared
item, status tag, or edge under F, N, and the set of stopped files of T.

### 4.10 The subject order

@term subject-order=v1
@cites {
    files#{path=v1},
    text#{code-point-order=v1, position=v1},
    identifiers#{tag-line-text=v1},
    ontology#{subject-of-approval=v1, declared-item=v1, tree=v1},
    documents#{item-file=v1, origin-position=v1, position-order=v1},
}

One subject of approval S1 of a tree comes before another subject of
approval S2 of that tree in the subject order when, and only when,
either of these two conditions is true:

1. The valid path of the file of the declared item of S1 comes before the valid path of the file of the declared item of S2 in code point order.
2. The valid path of the file of the declared item of S1 and the valid path of the file of the declared item of S2 are the same, and the origin position of the text of the tag line of the declaration of the declared item of S1 comes before the origin position of the text of the tag line of the declaration of the declared item of S2 in the order of positions.

### 4.11 Findings of the class `declined`

@atom declined-finding=v1
@cites {
    ontology#{
        subject-of-approval=v1, declared-item=v1, tree=v1, ledger=v1,
        parameter=v1,
    },
    identifiers#{external-namespaces=v1, tag-line-text=v1},
    documents#{
        file-readers=v1, item-file=v1, origin=v1, run-spot=v1,
        tree-finding=v1, unreadable-file=v1,
    },
    changes#{
        commit=v1, commit-file=v1, default-branch-commit=v1,
        first-parent-line=v1,
    },
    ledger#{stored-ledger=v1},
    findings#{finding-subject=v1},
    text#{code-span=v1},
    #{
        approval-kinds=v1, subject-text=v1, subject-state=v1,
        bound-in-force-item=v1, subject-order=v1,
    },
}

This atom is for a git repository R, a valid binding A of
`approval-kinds`, a binding D of `default-branch-name`, a binding F of
`file-readers`, a binding N of `external-namespaces`, a tree T, a point
P of the ledger of R, and, for each tree U that is T or, when the
default branch of R has a commit H under D, is the tree of a commit of
the first-parent line of H, one set of stopped files of U. Each such
tree U has that one set as the set of stopped files of U, also when two
commits of that first-parent line have the same tree or when T is the
tree of a commit of that first-parent line. T has, at P under A, D, F,
N, and these sets of stopped files, one tree finding of the class
`declined` for each text t that is the subject text of a subject of
approval S that T has under F, N, and the set of stopped files of T such
that both of these are true:

1. S is declined in T at P under A, D, F, N, and these sets of stopped
   files.
2. The declared item of S is in force in T at P under A, D, F, N, and
   these sets of stopped files.

Its subject is t. Its spot is the spot of the run of the text of the tag
line of the declaration of the declared item of the first subject of
approval, in the subject order, whose subject text is t among the
subjects of approval that T has under F, N, and the set of stopped files
of T; that run is in the text of the file of that declared item.

### 4.12 Findings of the class `awaiting-approval`

@atom awaiting-approval-finding=v1
@cites {
    ontology#{
        subject-of-approval=v1, declared-item=v1, tree=v1, ledger=v1,
        parameter=v1,
    },
    identifiers#{external-namespaces=v1, tag-line-text=v1},
    documents#{
        file-readers=v1, item-file=v1, origin=v1, run-spot=v1,
        tree-finding=v1, unreadable-file=v1,
    },
    changes#{
        commit=v1, commit-file=v1, default-branch-commit=v1,
        first-parent-line=v1,
    },
    ledger#{stored-ledger=v1},
    findings#{finding-subject=v1},
    text#{code-span=v1},
    #{
        approval-kinds=v1, approval-need=v1, subject-text=v1,
        subject-state=v1, bound-in-force-item=v1, subject-order=v1,
    },
}

This atom is for a git repository R, a valid binding A of
`approval-kinds`, a binding D of `default-branch-name`, a binding F of
`file-readers`, a binding N of `external-namespaces`, a tree T, a point
P of the ledger of R, and, for each tree U that is T or, when the
default branch of R has a commit H under D, is the tree of a commit of
the first-parent line of H, one set of stopped files of U. Each such
tree U has that one set as the set of stopped files of U, also when two
commits of that first-parent line have the same tree or when T is the
tree of a commit of that first-parent line. T has, at P under A, D, F,
N, and these sets of stopped files, one tree finding of the class
`awaiting-approval` for each text t that is the subject text of a
subject of approval S that T has under F, N, and the set of stopped
files of T such that each of these is true:

1. S needs approval under A.
2. The declared item of S is in force in T at P under A, D, F, N, and
   these sets of stopped files.
3. S is neither in T at P under A, D, F, N, and these sets of stopped
   files.

Its subject is t. Its spot is the spot of the run of the text of the tag
line of the declaration of the declared item of the first subject of
approval, in the subject order, whose subject text is t among the
subjects of approval that T has under F, N, and the set of stopped files
of T; that run is in the text of the file of that declared item.

### 4.13 Findings of the class `unapproved-req`

@atom unapproved-req-finding=v1
@cites {
    identifiers#{external-namespaces=v1, citation-entry=v1},
    ontology#{
        edge=v1, satisfies-edge=v1, verifies-edge=v1,
        subject-of-approval=v1, declared-item=v1, schema=v1, tree=v1,
        ledger=v1, parameter=v1,
    },
    documents#{
        file-readers=v1, tree-edge=v1, origin=v1,
        origin-position=v1, position-subject=v1, run-spot=v1,
        tree-finding=v1, unreadable-file=v1,
    },
    changes#{
        commit=v1, commit-file=v1, default-branch-commit=v1,
        first-parent-line=v1,
    },
    ledger#{stored-ledger=v1},
    text#{code-span=v1},
    #{
        approval-kinds=v1, approval-need=v1, subject-state=v1,
        bound-in-force-item=v1,
    },
}

This atom is for a git repository R, a valid binding A of
`approval-kinds`, a binding D of `default-branch-name`, a binding F of
`file-readers`, a binding N of `external-namespaces`, a tree T, a point
P of the ledger of R, and, for each tree U that is T or, when the
default branch of R has a commit H under D, is the tree of a commit of
the first-parent line of H, one set of stopped files of U. Each such
tree U has that one set as the set of stopped files of U, also when two
commits of that first-parent line have the same tree or when T is the
tree of a commit of that first-parent line. T has, at P under A, D, F,
N, and these sets of stopped files, one tree finding of the class
`unapproved-req` for each edge that T has under F, N, and the set of
stopped files of T such that all four of these conditions are true:

1. The edge is of the kind `satisfies` or `verifies`, and says what its
   kind of edge says.
2. The cited item of the edge is an item of the kind requirement that
   has a subject of approval, or a schema that has a subject of
   approval.
3. That cited item is in force in T at P under A, D, F, N, and these
   sets of stopped files.
4. The subject of approval of that cited item needs approval under A and
   is not approved in T at P under A, D, F, N, and these sets of stopped
   files.

The subject of that tree finding is the position subject of the origin
position of the citation entry of the edge. The spot of that tree
finding is the spot of the run of that citation entry in the text of the
file of the edge.

## 5. Requirements

### 5.1 The states of subjects of approval

@req give-subject-states=v1
@cites {
    ontology#{
        subject-of-approval=v1, tree=v1, ledger=v1, state=v1,
        parameter=v1,
    },
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-commit=v1,
        first-parent-line=v1, shallow-commit=v1,
    },
    ledger#{stored-ledger=v1},
    documents#{file-readers=v1, unreadable-file=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{approval-kinds=v1, subject-state=v1},
}

This requirement applies under a valid binding A of `approval-kinds`, a
binding D of `default-branch-name`, a valid binding F of `file-readers`,
and a binding N of `external-namespaces` for which a conforming program
of the design Identifiers gives the result "valid". It applies for a git
repository R, a tree T, and a point P of the ledger of R. When a
conforming program gives whether a subject of approval S is approved or
declined in T at P under A, D, F, and N, that conforming program must
use one set of stopped files of U, as the set of stopped files of U, for
each tree U that is T or, when the default branch of R has a commit H
under D, is the tree of a commit of the first-parent line of H. To give
that result, that conforming program must use that same set in every
place where that conforming program reads U, also when two commits of
that first-parent line have the same tree or when T is the tree of a
commit of that first-parent line. For each subject of approval S that T
has under F, N, and the set of stopped files of T, when that conforming
program gives whether S is approved or declined in T at P under A, D, F,
N, and these sets of stopped files, that conforming program must give
exactly one result, and only "approved", "declined", or "neither":

- That conforming program must give "approved" when S is approved in T
  at P under A, D, F, N, and these sets of stopped files.
- That conforming program must give "declined" when S is declined in T
  at P under A, D, F, N, and these sets of stopped files.
- That conforming program must give "neither" when S is neither in T at
  P under A, D, F, N, and these sets of stopped files.

When the default branch of R has a commit H under D, and either R lacks
the git objects that the tree of a commit of the first-parent line of H
needs or a commit of that first-parent line is a shallow commit, for
such a subject of approval S, a conforming program must either give
exactly the one result that this requirement states for S and no other
result, or give no state for S.

### 5.2 The acceptance of `approval` and `decline` ledger entries

@req give-judgment-acceptance=v1
@cites {
    ledger#{accepted-entry=v1},
    ontology#{ledger=v1, ledger-entry=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{judgment-acceptance-rule=v1},
}

When a conforming program gives whether a ledger entry of the kind
`approval` or `decline` is accepted at a point of a ledger, that
conforming program must give exactly one result, and only "accepted" or
"not accepted":

- That conforming program must give "accepted" when the acceptance rule of the kinds `approval` and `decline` holds for that ledger entry at that point.
- That conforming program must give "not accepted" when the acceptance rule of the kinds `approval` and `decline` does not hold for that ledger entry at that point.

### 5.3 What an `approval` or `decline` ledger entry records

@req record-judged-content=v1
@cites {
    ontology#{
        ledger-entry=v1, person=v1, subject-of-approval=v1,
        revised-content=v1, tree=v1, ledger=v1,
    },
    identifiers#{external-namespaces=v1},
    documents#{extent-hash=v1, file-readers=v1, unreadable-file=v1},
    text#{conforming-program=v1, code-span=v1},
    #{subject-text=v1, judgment-field=v1},
}

This requirement applies for a tree T, a binding F of `file-readers`, a
binding N of `external-namespaces`, a set of stopped files of T, and a
subject of approval S that T has under F, N, and that set of stopped
files. When a conforming program appends to a ledger a ledger entry of
the kind `approval` or `decline` to record a decision of a person on the
revised content that S has in T under F, N, and that set of stopped
files, all of these rules apply to that ledger entry:

- That ledger entry must be of the kind `approval` when the person
  approved that revised content.
- That ledger entry must be of the kind `decline` when the person
  declined that revised content.
- The value of `subject` of that ledger entry must be the subject text
  of S in T.
- The value of `hash` of that ledger entry must be the extent hash of
  the declared item of S in T under F, N, and that set of stopped files.

### 5.4 What `saw` records

@req record-seen-judgments=v1
@cites {
    ontology#{ledger=v1, ledger-entry=v1, person=v1},
    text#{conforming-program=v1, code-span=v1},
    #{judgment-field=v1, judgment-acceptance-rule=v1},
}

A conforming program must append a ledger entry of the kind `approval`
or `decline` whose value of `saw` is `approval` or `decline` only when,
before the person whose decision that ledger entry records confirmed the
decision, the program gave that person the judgment before that ledger
entry at the point at which the program appends it.

### 5.5 No state under bindings that are not valid

@req give-no-states-under-invalid-bindings=v1
@cites {
    ontology#{
        subject-of-approval=v1, tree=v1, finding-class=v1, parameter=v1,
    },
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{
        subject-state=v1, declined-finding=v1,
        awaiting-approval-finding=v1, unapproved-req-finding=v1,
    },
}

Under a binding of `file-readers` that is not valid, or under a binding
of `external-namespaces` for which a conforming program of the design
Identifiers gives the result "invalid", a conforming program must give,
for any tree, no state approved, declined, or neither of a subject of
approval, and no finding of the classes `declined`,
`awaiting-approval`, and `unapproved-req`.

### 5.6 No finding from a ledger that is not valid

@req give-no-findings-from-invalid-ledgers=v1
@cites {
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    ontology#{tree=v1, ledger=v1, finding-class=v1},
    text#{conforming-program=v1, code-span=v1},
    #{
        declined-finding=v1, awaiting-approval-finding=v1,
        unapproved-req-finding=v1,
    },
}

A conforming program must give no finding of the classes `declined`,
`awaiting-approval`, and `unapproved-req` of a tree at a point of the
ledger of a git repository that no other process changes while the
program reads it, when that ledger is broken or newer, or when the git
repository does not hold its ledger objects.

### 5.7 The findings of a tree

@req give-approval-findings=v1
@cites {
    ontology#{finding-class=v1, tree=v1, ledger=v1, parameter=v1},
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-commit=v1,
        first-parent-line=v1, shallow-commit=v1,
    },
    ledger#{stored-ledger=v1},
    documents#{file-readers=v1, tree-finding=v1, unreadable-file=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{
        approval-kinds=v1, declined-finding=v1,
        awaiting-approval-finding=v1, unapproved-req-finding=v1,
    },
}

This requirement applies under a valid binding A of `approval-kinds`, a
binding D of `default-branch-name`, a valid binding F of `file-readers`,
and a binding N of `external-namespaces` for which a conforming program
of the design Identifiers gives the result "valid". It applies for a git
repository R, a tree T, and a point P of the ledger of R. When a
conforming program gives the findings of one of the classes `declined`,
`awaiting-approval`, and `unapproved-req` of T at P under A, D, F, and
N, that conforming program must use one set of stopped files of U, as
the set of stopped files of U, for each tree U that is T or, when the
default branch of R has a commit H under D, is the tree of a commit of
the first-parent line of H. To give those findings, that conforming
program must use that same set in every place where that conforming
program reads U, also when two commits of that first-parent line have
the same tree or when T is the tree of a commit of that first-parent
line. Under these sets of stopped files, when that conforming program
gives the findings of one of those three classes of T at P under A, D,
F, and N, that conforming program must give each tree finding of that
class that T has at P under A, D, F, N, and these sets of stopped files
once, and must give no other finding of that class. When the default
branch of R has a commit H under D, and either R lacks the git objects
that the tree of a commit of the first-parent line of H needs or a
commit of that first-parent line is a shallow commit, for each of those
three classes, a conforming program must either give each tree finding
of that class that T has at P under A, D, F, N, and these sets of
stopped files once and no other finding of that class, or not give the
findings of that class.

## 6. Conformance

A program, or a part of a program, conforms to this design when it is a
conforming program of this design: when it meets every requirement of
section 5.

The vectors of this design are in the file
[`approval.test-vectors.jsonl`](approval.test-vectors.jsonl), in the
same folder as this design. The file is a test-vector set, as the
specification [`test-vectors`](sinter:data-forms#test-vectors=v1) of
Data forms gives it. A vector is an input and what a conforming program
gives for it. Each vector follows from the requirements and adds nothing
to them. The vectors are in three groups: `acceptance`, `findings`, and
`states`. Each group has a subsection below that gives the forms of that
group, as the term
[`group-form-list`](sinter:data-forms#group-form-list=v1) gives the
forms of a group. No vector follows from the requirements
`record-judged-content`, `record-seen-judgments`,
`give-no-states-under-invalid-bindings`, and
`give-no-findings-from-invalid-ledgers`.

Each requirement from which vectors follow applies only when a program
gives the thing that the requirement names, such as whether a ledger
entry is accepted at a point. So a vector holds a program only to what
the program gives for the input.

### 6.1 Acceptance

@schema acceptance-vector=v1
@cites {
    rfc/8259,
    text#{
        conforming-program=v1, text=v1, character=v1, result=v1,
        code-span=v1,
    },
    data-forms#{
        group-form-list=v1, vector-meaning=v1, json-value=v1,
        hash-form=v1,
    },
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{ledger=v1, ledger-entry=v1, parameter=v1},
    changes#{default-branch-commit=v1},
    documents#{file-readers=v1},
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    #{
        subject-text=v1, judgment-field=v1, judgment-acceptance-rule=v1,
        give-judgment-acceptance=v1,
    },
}

The group `acceptance` holds the vectors of the requirement
`give-judgment-acceptance`. Each vector gives a ledger whose ledger
entries of the kinds `approval` and `decline` are the given ones, in
order. For each of those ledger entries of the kinds `approval` and
`decline`, the vector gives whether that ledger entry is accepted at its
point. The group uses no need, so these forms give no need names.

The input of each vector stands for a valid ledger of a git repository
that holds its ledger objects; for a binding of `file-readers` that is
valid; for a binding of `external-namespaces` for which a conforming
program of Identifiers gives the result "valid"; and for one binding of
`default-branch-name` (the input does not depend on that binding). No
other process changes these inputs while the program reads them.

The JSON values, objects, arrays, strings, numbers, and the literal
names `true` and `false` of this schema are as RFC 8259 defines them.
Inside the members `input` and `values`, a text, such as a subject text
or a hash, is a JSON string whose characters are the characters of the
text, in order. Inside the members `input` and `values`, a sequence is a
JSON array of its elements, in order.

- `input`: a JSON object with one member, `ledger`. `ledger` is the
  ledger entries of the kinds `approval` and `decline` of the ledger, as
  a sequence in the order of the ledger. Each ledger entry is a JSON
  object that holds the member `kind` and each of the members `subject`,
  `hash`, `saw`, and `reason` that the object of the ledger entry has,
  with the same values. The other members of the object of the ledger
  entry have no effect on the vector. The ledger has no other ledger
  entry of these two kinds.
- `result`: no vector of the group has this member; these forms name no
  question for `result`.
- `values`: a JSON object with one member, `accepted`. `accepted` is a
  JSON array with one element for each element of `ledger`, in the same
  order. The element of `accepted` for an element of `ledger` is `true`
  when that ledger entry is accepted at its point, and `false` when that
  ledger entry is not accepted at its point.

When a conforming program gives whether one of these ledger entries is
accepted at the point of that ledger entry, the program gives "accepted"
when the element of `accepted` for that ledger entry is `true`, and the
program gives "not accepted" when that element of `accepted` is `false`.

```
{"form":"#acceptance-vector=v1","group":"acceptance","input":{"ledger":[{"hash":"7692c3ad3540bb803c020b3aee66cd8887123234ea0c6e7143c0add73ff431ed","kind":"decline","saw":"none","subject":"req:billing#limit"},{"hash":"7692c3ad3540bb803c020b3aee66cd8887123234ea0c6e7143c0add73ff431ed","kind":"approval","saw":"none","subject":"req:billing#limit"}]},"note":"an approval with `saw` `none` after a decline is not accepted","values":{"accepted":[true,false]}}
```

### 6.2 Findings

@schema findings-vector=v1
@cites {
    rfc/8259,
    text#{
        conforming-program=v1, text=v1, character=v1, whole-number=v1,
        decimal-numeral=v1, code-point-order=v1, result=v1,
        code-span=v1,
    },
    data-forms#{
        index=v1, group-form-list=v1, vector-meaning=v1, json-value=v1,
    },
    identifiers#{
        external-namespaces=v1, validate-bindings=v1, citation-entry=v1,
        inline-citation=v1,
    },
    ontology#{
        subject-of-approval=v1, declared-item=v1, schema=v1, tree=v1,
        edge=v1, ledger=v1, finding-class=v1, parameter=v1,
    },
    changes#{
        commit=v1, commit-file=v1, default-branch-commit=v1,
        first-parent-line=v1,
    },
    documents#{
        file-readers=v1, tree-edge=v1, origin-position=v1,
        position-subject=v1, tree-finding=v1, unreadable-file=v1,
    },
    findings#{finding-subject=v1},
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    #{
        approval-kinds=v1, subject-text=v1, subject-state=v1,
        bound-in-force-item=v1, declined-finding=v1,
        awaiting-approval-finding=v1, unapproved-req-finding=v1,
        give-approval-findings=v1,
    },
}

The group `findings` holds the vectors of the requirement
`give-approval-findings`. Each vector gives the subjects of approval of
a tree, their states, and whether the declared items of those subjects
of approval are in force. The vector gives the edges of the tree. For
each edge, when the cited item of that edge is an item of the kind
requirement or a schema, the vector gives whether that cited item is in
force. The vector gives the findings of the three classes of the tree at
a point of a ledger, by the subjects of those findings. The group uses
no need, so these forms give no need names.

The input of each vector stands for a valid ledger of a git repository
that holds its ledger objects; for a binding of `file-readers` that is
valid; for a binding of `external-namespaces` for which a conforming
program of Identifiers gives the result "valid"; and for one binding of
`default-branch-name` (the input does not depend on that binding). Each
vector is for the empty set of stopped files of each tree that is the
tree or, when the default branch has a commit, is the tree of a commit
of the first-parent line of that commit. No other process changes these
inputs while the program reads them.

The JSON values, objects, arrays, strings, numbers, and the literal
names `true` and `false` of this schema are as RFC 8259 defines them.
Inside the members `input` and `values`, a text, such as a subject text
or a position subject, is a JSON string whose characters are the
characters of the text, in order. A sequence is a JSON array of its
elements, in order. A valid binding of `approval-kinds` is a JSON array
of JSON strings. The elements of that array are, for each kind of
subject of approval in the binding, the kind word of that kind of
subject of approval, each once, in code point order. For example,
`"req"` is the kind word for an item of the kind requirement that an
item of the kind design holds directly.

- `input`: a JSON object with three members. `binding` is a valid
  binding of `approval-kinds`. `subjects` is the subjects of approval of
  the tree, as a sequence. Each subject of approval in `subjects` is a
  JSON object with three members: `subject`, `state`, and `in-force`.
  `subject` is the subject text of that subject of approval. `state` is
  the state of that subject of approval in the tree at the point under
  the bindings and those empty sets of stopped files, one of the JSON
  strings `"approved"`, `"declined"`, and `"neither"`. `in-force` is
  `true` when the declared item of that subject of approval is in force
  in the tree at the point under the bindings and those empty sets of
  stopped files (term `bound-in-force-item`), and `false` when that
  declared item is not in force in the tree at the point under the
  bindings and those empty sets of stopped files. `edges` is the edges
  of the tree, as a sequence. Each edge in `edges` is a JSON object with
  the members `kind`, `fits`, and `at`, and, when the cited item of that
  edge is an item of the kind requirement that has a subject of
  approval, or a schema that has a subject of approval, two more
  members, `cited` and `in-force`. `kind` is the kind of edge of that
  edge, a text. `fits` is `true` when that edge says what its kind of
  edge says, and `false` when that edge does not say what its kind of
  edge says. `at` is the position subject of the origin position of the
  citation entry of that edge, of the origin position of the inline
  citation of that edge, or of the form position of the vector line of
  that edge. An inline citation and a vector line give only edges of the
  kind `cites`. When the cited item of an edge in `edges` is an item of
  the kind requirement that has a subject of approval, or a schema that
  has a subject of approval, `cited` is the index of that subject of
  approval in `subjects`, a JSON number written as the decimal numeral
  of a whole number of 1 or more, counted from 1. When the cited item of
  an edge in `edges` is an item of the kind requirement that has a
  subject of approval, or a schema that has a subject of approval,
  `in-force` is `true` when that cited item is in force in the tree at
  the point under the bindings and those empty sets of stopped files
  (term `bound-in-force-item`), and `false` when that cited item is not
  in force in the tree at the point under the bindings and those empty
  sets of stopped files.
- `result`: no vector of the group has this member; these forms name no
  question for `result`.
- `values`: a JSON object with one member, `findings`. `findings` is a
  JSON object with three members: `awaiting-approval`, `declined`, and
  `unapproved-req`. Each of those three members is a JSON array of the
  subjects of the tree findings of that class that the tree has at the
  point under the bindings and those empty sets of stopped files, with
  each subject once, in code point order.

When a conforming program gives the findings of one of the three classes
of the tree at the point under the empty set of stopped files of each
tree that is the tree or, when the default branch has a commit, is the
tree of a commit of the first-parent line of that commit, the program
gives one finding with each subject that the member of `findings` for
that class holds, and the program gives no other finding of that class.

```
{"form":"#findings-vector=v1","group":"findings","input":{"binding":["req"],"edges":[],"subjects":[{"in-force":true,"state":"declined","subject":"req:billing#limit"},{"in-force":true,"state":"declined","subject":"req:billing#limit"},{"in-force":true,"state":"neither","subject":"req:billing#limit"}]},"note":"two declared items with the same kind and name give one finding of a class","values":{"findings":{"awaiting-approval":["req:billing#limit"],"declined":["req:billing#limit"],"unapproved-req":[]}}}
```

### 6.3 States

@schema states-vector=v1
@cites {
    rfc/8259,
    text#{
        conforming-program=v1, text=v1, character=v1,
        code-point-order=v1, result=v1, code-span=v1,
    },
    data-forms#{group-form-list=v1, vector-meaning=v1, json-value=v1},
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        subject-of-approval=v1, tree=v1, ledger=v1, ledger-entry=v1,
        default-branch=v1, parameter=v1,
    },
    changes#{
        commit=v1, commit-file=v1, default-branch-commit=v1,
        first-parent-line=v1,
    },
    documents#{file-readers=v1, extent-hash=v1, unreadable-file=v1},
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    #{
        approval-kinds=v1, subject-text=v1, subject-state=v1,
        give-subject-states=v1, acceptance-vector=v1,
        findings-vector=v1,
    },
}

The group `states` holds the vectors of the requirement
`give-subject-states`. Each vector gives one subject of approval of a
tree, by the subject text of that subject of approval and the extent
hash of the declared item of that subject of approval; a valid binding
of `approval-kinds`; the `approval` and `decline` ledger entries of a
ledger; and the trees of the commits of the first-parent line of the
commit of the default branch. The vector gives the state of that subject
of approval in the tree at the point after the last ledger entry of the
ledger. The group uses no need, so these forms give no need names.

The input of each vector stands for a valid ledger of a git repository
that holds the ledger objects of that git repository; for a binding of
`file-readers` that is valid; for a binding of `external-namespaces` for
which a conforming program of Identifiers gives the result "valid"; and
for one binding of `default-branch-name`. Under that binding of
`default-branch-name`, when the input has the member `line`, the default
branch of that git repository has the commit whose first-parent line the
member `line` of the input gives. Under that binding of
`default-branch-name`, when the input has no member `line`, the default
branch of that git repository has no commit. Each vector is for the
empty set of stopped files of each tree that is the tree or, when the
default branch has a commit, is the tree of a commit of the first-parent
line of that commit. No other process changes these inputs while the
program reads them.

The JSON values, objects, arrays, strings, and numbers of this schema
are as RFC 8259 defines them. Inside the members `input` and `result`, a
text, such as a subject text or a hash, is a JSON string whose
characters are the characters of the text, in order. Inside the members
`input` and `result`, a sequence is a JSON array of its elements, in
order. Inside the members `input` and `result`, a valid binding of
`approval-kinds` has the form that the schema `findings-vector` gives
for a valid binding of `approval-kinds`.

- `input`: a JSON object with four or five members. `binding` is a valid
  binding of `approval-kinds`. `subject` is the subject text of the
  subject of approval. `hash` is the extent hash of the declared item of
  the subject of approval in the tree. `ledger` is the ledger entries of
  the kinds `approval` and `decline` of the ledger, in the form that the
  schema `acceptance-vector` gives. When the default branch has a
  commit, `line` is the commits of the first-parent line of that commit,
  as a sequence in the order of that line. When the default branch has a
  commit, each commit in `line` is a JSON array with one JSON object for
  each subject of approval of the tree of that commit. When the default
  branch has a commit, each of those JSON objects has two members:
  `subject` and `hash`. When the default branch has a commit, in the
  JSON object for a subject of approval of the tree of a commit in
  `line`, `subject` is the subject text of that subject of approval.
  When the default branch has a commit, in the JSON object for a subject
  of approval of the tree of a commit in `line`, `hash` is the extent
  hash of the declared item of that subject of approval in the tree of
  that commit. When the default branch has no commit, the input has no
  member `line`.
- `result`: when a conforming program gives whether the subject of
  approval is approved or declined in the tree at the point under those
  empty sets of stopped files, `result` is that result. That result is
  "approved" when the subject of approval is approved in the tree at the
  point under those empty sets of stopped files. That result is
  "declined" when the subject of approval is declined in the tree at the
  point under those empty sets of stopped files. That result is
  "neither" when the subject of approval is neither in the tree at the
  point under those empty sets of stopped files.
- `values`: no vector of the group has this member. These forms give no
  fixed form for `values`.

When a conforming program gives whether the subject of approval is
approved or declined in the tree at the point under the empty set of
stopped files of each tree that is the tree or, when the default branch
has a commit, is the tree of a commit of the first-parent line of that
commit, the program gives "approved" when `result` is `approved`, the
program gives "declined" when `result` is `declined`, the program gives
"neither" when `result` is `neither`, and the program gives no other
result.

```
{"form":"#states-vector=v1","group":"states","input":{"binding":["spec"],"hash":"7692c3ad3540bb803c020b3aee66cd8887123234ea0c6e7143c0add73ff431ed","ledger":[],"line":[[{"hash":"3fc4ccfe745870e2c0d99f71f30ff0656c8dedd41cc1d7d3d376b0dbe685e2f3","subject":"req:billing#limit"}],[{"hash":"7692c3ad3540bb803c020b3aee66cd8887123234ea0c6e7143c0add73ff431ed","subject":"req:billing#limit"}],[]],"subject":"req:billing#limit"},"note":"the revised content is in the tree of an earlier commit of the first-parent line","result":"approved"}
```
