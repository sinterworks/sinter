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
Specifies the subjects of approval that need a person's approval; the fields of the ledger entries of the kinds `approval` and `decline`, and their acceptance rule; the latest judgment of a subject of approval; the rule for merges; the states approved and declined of subjects of approval; the finding classes `declined`, `awaiting-approval`, and `unapproved-req`; and requirements for conforming programs that give these states, acceptance, and findings, and that append judgments.

A person approves or declines the revised content of a subject of
approval, such as the text of an item of the kind requirement. A
binding of the parameter `approval-kinds` says which kinds of subject of
approval need a person's approval. For such a kind, the latest judgment
of a subject of approval and of the content that it has in a tree
decides whether it is approved or declined. For each other kind, a
merge into the default branch approves it. A judgment names its subject
of approval by a kind word and a name, such as `req:billing#limit`, and
its content by an extent hash. Each judgment also records which earlier
judgment of the same subject and content its writer saw, so that an
approval never stands after a decline that its writer did not see.

From the Ontology (`ontology`), the design takes subjects of approval,
their five kinds, their declared items, and when two of them are the
same subject of approval; revised content; judgments, ledger entries,
the ledger, and points of a ledger; states, the states approved and
declined, and in force; trees, the default branch, edges with their
kinds, sources, and cited items, and when an edge says what its kind of
edge says; findings, finding classes, and parameters with their
bindings. The Ontology requires that a program appends a judgment only
on a confirmation that a person gives (requirement
`ontology#write-judgments-only-for-persons`), and that the writer, the
person, the branch, and the time that a ledger entry records change no
state (requirement `ontology#treat-ledger-entries-alike`).

From the Ledger (`ledger`), the design takes the fields of a kind of
ledger entry and the common fields, acceptance rules, and when a ledger
entry is accepted at a point. A program appends a ledger entry only at a
point at which it is accepted (requirement
`ledger#append-only-accepted-entries`), and a pull keeps a provisional
ledger entry only when it is accepted at its new point (term
`ledger#pull-commit`). A program gives no state at a point of a ledger
that is broken or newer (requirement
`ledger#give-states-only-from-valid-ledgers`).

From Documents (`documents`), the design takes the declared items of a
tree with their files and declarations, the bindings of the parameter
`file-readers`, extent hashes, the edges of a tree, origin positions,
position subjects, the order of positions, the spots of runs, and tree
findings. A program gives no extent hash under a binding that is not
valid (requirement `documents#give-nothing-under-invalid-bindings`).
From Changes (`changes`), it takes commits and their parents, the
commit of the default branch, and first-parent lines. From Findings
(`findings`), it takes the subjects of findings. From Identifiers
(`identifiers`), it takes slugs, full names, the parameter
`external-namespaces` with its bindings, and the results that a
conforming program of Identifiers gives. From Files and paths
(`files`), it takes valid paths. From Data forms (`data-forms`), it
takes hashes and test-vector sets: the file that holds the conformance
vectors of the design is one. From Text and notation (`text`), it takes
texts, code point order, the notation of productions, and what a
conforming program, an input, and a result are.

The production `subject-text` is written in ABNF, the notation of
RFC 5234, with the case-sensitive strings `%s"…"` of RFC 7405. From
RFC 8259, the design takes JSON texts, with their objects, members,
arrays, strings, and the literal names `true` and `false`: each line of
the file that holds the conformance vectors of the design is a JSON
text.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [subject of approval](sinter:ontology#subject-of-approval=v1) | a unit that a person approves, or that the merge approves, as a whole |
| [kind of subject of approval](sinter:ontology#subject-of-approval=v1) | which of five units a subject of approval is: an item of the kind design without the declared items that it holds, an item of the kind specification with the items of the kind requirement and the terms that it holds, an item of the kind requirement that an item of the kind design holds directly, a term that an item of the kind design holds directly, or a decision record |
| [declared item of a subject of approval](sinter:ontology#subject-of-approval=v1) | the item of the kind design, for a subject of approval of the first kind, and otherwise the item of the kind specification, the item of the kind requirement, the term, or the decision record that the subject of approval is |
| [same subject of approval](sinter:ontology#subject-of-approval=v1) | two subjects of approval of two trees are the same when their declared items have the same kind of item and the same name |
| [revised content](sinter:ontology#revised-content=v1) | the part of an item that its label covers, such as the text of an item of the kind requirement |
| [extent hash](sinter:documents#extent-hash=v1) | the hash of a text that the revised content of a declared item gives, without its own label and some other parts; two revised contents of the same declared item are the same when their extent hashes are equal |
| [hash](sinter:data-forms#hash=v1) | 64 hex digits: the SHA-256 digest of a byte sequence, as a text |
| [binding of `approval-kinds`](sinter:#approval-binding=v1), [need approval](sinter:#approval-binding=v1) | a set of kinds of subject of approval; a subject of approval needs approval under a binding when its kind is in that binding |
| [subject text](sinter:#subject-text=v1) | the kind word of the kind of a subject of approval, `:`, and the name of its declared item, such as `req:billing#limit` |
| [judgment](sinter:ontology#judgment=v1) | a ledger entry that records a decision of a person; here, a ledger entry of the kind `approval` or `decline` |
| [field of a kind](sinter:ledger#entry-field=v1) | a member of the object of a ledger entry that a design names for its kind, other than the common fields, such as `subject` |
| [malformed](sinter:#judgment-field=v1) | of a ledger entry of the kind `approval` or `decline`: one of its fields is missing or does not have its form |
| [acceptance rule](sinter:ledger#accepted-entry=v1), [accepted](sinter:ledger#accepted-entry=v1) | the condition under which a ledger entry of one kind can stand at a point of a ledger; a ledger entry is accepted at a point when the acceptance rule of its kind holds for it there |
| [judgment before a ledger entry](sinter:#judgment-acceptance-rule=v1) | of a ledger entry of the kind `approval` or `decline` at a point, the latest earlier `approval` or `decline` ledger entry with the same subject text and hash that is accepted at its own point |
| [latest judgment](sinter:#latest-judgment=v1) | of a subject of approval of a tree at a point of a ledger: the latest `approval` or `decline` ledger entry before the point that is accepted at its point and that names the subject text and the extent hash that the subject of approval has in the tree |
| [first-parent line](sinter:changes#first-parent-line=v1) | the sequence of commits that starts with a commit and goes on, from each commit, to its first parent, until a commit with no parent |
| [commit of the default branch](sinter:changes#default-branch-commit=v1) | the commit to which the default branch of a git repository points, if it points to one |
| [has merged](sinter:#merged-content=v1) | the revised content of a subject of approval in a tree has merged into the default branch when a tree of a commit of the first-parent line of the commit of the default branch gives the same subject of approval the same extent hash |
| [approved, declined, neither](sinter:#subject-state=v1) | the three states of a subject of approval in a tree, at a point of a ledger, under the bindings of the parameters |
| [in force](sinter:ontology#in-force-item=v1) | a declared item is in force in a tree, at a point of a ledger, when it is not retired there: when it still applies |
| [subject order](sinter:#subject-order=v1) | the order of the subjects of approval of a tree by the valid paths of the files of their declared items, and then by the positions of their declarations |
| [tree finding](sinter:documents#tree-finding=v1) | a finding of a tree with a given class, subject, and spot, that is not ackable |
| [subject of a finding](sinter:findings#finding-subject=v1) | the text that names what a finding is about |
| [position subject](sinter:documents#position-subject=v1) | the subject of a finding at a position, such as `src/fee.ml@L3C4` |

## 2. Judgments and approval states

### 2.1 Subjects that need approval

The parameter `approval-kinds` gives the kinds of subject of approval
that need approval by a person (term `approval-binding`). For example,
under the binding of the two kinds item of the kind specification and
item of the kind requirement that an item of the kind design holds
directly, the subject of approval `req:billing#limit` needs approval,
and the subject of approval `design:billing` does not. Under the empty
binding, no subject of approval needs approval.

A subject of approval has a subject text (term `subject-text`): the kind
word of its kind, `:`, and the name of its declared item. The kind words
are `design`, `spec`, `req`, `term`, and `decision`. For example, the
item of the kind requirement `billing#limit` that the item of the kind
design `billing` holds directly has the subject text
`req:billing#limit`, and the item of the kind design `billing` has the
subject text `design:billing`. An item of the kind requirement that an
item of the kind specification holds has no subject of approval of its
own: the specification is its subject of approval. Two subjects of
approval of two trees are the same subject of approval when, and only
when, they have the same subject text, because the kind word gives the
kind of item and the name is the name of the declared item. So a renamed
item is another subject of approval.

### 2.2 The fields of judgments

The ledger entries of the kinds `approval` and `decline` are judgments.
Their fields are `subject`, `hash`, and `saw`, and, for the kind
`decline`, `reason` (term `judgment-field`). For example, this is the
object of an approval, with the common fields of the Ledger:

```
{"by":"Ada Lovelace <ada@example.com>","hash":"39096d6a3499d398332a59e6882377d2f0b81e206429b16f163df9cb16c00656","id":"e-c137172925a9","kind":"approval","saw":"none","seq":12,"subject":"req:billing#limit-amount","v":1}
```

The field `subject` names the subject of approval by its subject text.
The field `hash` names the revised content by its extent hash: the
extent hash of the declared item of the subject of approval in the tree
from which the person gave the decision (requirement
`record-judged-content`). Which tree that is, how the program shows the
content to the person, and how the person confirms are for the program
to choose. The extent hash leaves out the label of the declared item, so
a new label alone does not change what a judgment judges. An edit back
to a judged content makes the judgment of that content count again.

The field `saw` records the kind of the judgment before the new
judgment that its writer saw, or `none` when the writer saw no judgment
of the same subject text and hash. The field `reason` holds the reason
that a person gave for a decline. No state depends on it.

A malformed judgment (term `judgment-field`) is accepted at no point, so
it counts for nothing, and the ledger stays valid. For example, an
approval whose `subject` is `billing#limit`, with no kind word, is
malformed.

### 2.3 Acceptance

The Ledger asks each kind of ledger entry that a program appends for an
acceptance rule (term `ledger#accepted-entry`). The term
`judgment-acceptance-rule` gives the rule of the kinds `approval` and
`decline`. It reads only the ledger entries before the point, never a
tree, a binding, or a commit. A program appends a judgment only at a
point at which it is accepted, so the `saw` of a judgment that a program
appends is the kind of the judgment before it at the end of the ledger
of its clone, or `none`.

These cases show the rule. In each, X is one subject text and one hash.

1. Clone A appends an approval of X with `saw` `none`. Before A pushes,
   clone B pushes a decline of X with `saw` `none`. A pulls: the decline
   of B comes first, and the approval of A, which did not see it, is not
   accepted at its new point. So the pull drops it and reports it
   (requirement `ledger#report-leaving-entries`), and the person decides
   again.
2. A person declines X, and later approves X on purpose. The approval
   has `saw` `decline`, and it is accepted.
3. Two clones each approve X with `saw` `none`, one after the other. The
   second approval is not accepted at its point. An approval with `saw`
   `approval` is never accepted either. So no accepted approval of X has
   an approval as the judgment before it.
4. A person declines X twice, with two reasons. The second decline has
   `saw` `decline`, and it is accepted.
5. A person approves X, and later declines it. The decline has `saw`
   `approval`, and it is accepted. A decline with `saw` `none` after
   that approval is not.

Only a judgment that is accepted at its point counts for a state (term
`latest-judgment`). So a judgment that is not accepted at its point,
such as a repeated approval that a program that does not conform
appended, counts for nothing. When a repair removes a
judgment, each later judgment of the same subject text and hash is
accepted, or not, by the ledger entries that remain before it.

### 2.4 The latest judgment and the states

A subject of approval of a tree has, at a point of a ledger, a latest
judgment, or none (term `latest-judgment`). It is the latest judgment
before the point, among those that are accepted at their points, of the
subject text of the subject of approval and of the extent hash that its
declared item has in that tree. The term `subject-state` gives the
three states approved, declined, and neither. They are the states
approved and declined of subjects of approval that the term
`ontology#approval-state` names.

For a subject of approval that needs approval, the latest judgment
decides. For example, a ledger holds an approval of `req:billing#limit`
with the extent hash H1, then an approval with the extent hash H2. In a
tree in which the requirement has the extent hash H1, it is approved;
with H2, it is approved; with a third extent hash, it is neither
approved nor declined.

For a subject of approval that does not need approval, the merge
decides (term `merged-content`). A judgment of such a subject of
approval changes no state while the binding stays the same. Under
another binding, in which its kind needs approval, the same judgment
counts.

Only `seq` orders judgments, because it gives the order of the ledger.
The writer, the person, the branch, and the time of a judgment change no
state (requirement `ontology#treat-ledger-entries-alike`), so an
approval that any person gave counts. Judgments that a pull brought from
another clone count as the judgments of the clone itself do, and a
provisional judgment counts in the clone that holds it.

### 2.5 Merges

The rule for merges (term `merged-content`) reads the first-parent line
of the commit of the default branch. A merge commit, a squash merge, and
a commit made straight on the default branch each put their tree on that
line, so content that came into the default branch in one of these ways
has merged. A commit that the default branch reaches only through the
second parent of a merge commit is not on the line. So when the default
branch fast-forwards to a commit whose first-parent line leaves out
earlier commits of the default branch, content that only those earlier
commits held has not merged. When a person moves the default branch back,
content that only the commits that left the line held has not merged.

When the default branch has no commit, no content has merged. In a
shallow clone, the first-parent line ends at a commit that the file
`shallow` names, which has no parents (term `changes#commit`). So the
rule does not see content that merged only before that commit.

### 2.6 Bindings and missing inputs

The extent hashes that a state uses, in the tree and in the tree of each
commit of the first-parent line, are those that one binding of
`file-readers` and one binding of `external-namespaces` give, and the
state is under one binding of `approval-kinds` (term `subject-state`).
Under bindings for which Documents gives no extent hash, a program gives
no state of a subject of approval and no finding of the classes of
section 2.7 (requirement `give-no-states-under-invalid-bindings`). A
program gives no state at a point of a ledger that is broken or newer, or of a git
repository that does not hold its ledger objects (requirement
`ledger#give-states-only-from-valid-ledgers`); so then it gives no
state of a subject of approval, also for a kind that does not need
approval.

What a program gives while another process changes a file, a ref, or
the ledger is a matter of the quality of an implementation.

### 2.7 Findings

Each of these classes has a term that gives its findings, each a
[tree finding](sinter:documents#tree-finding=v1), at a point of a
ledger, under the bindings of the parameters. No finding of these
classes is ackable.

| class | term |
|---|---|
| `declined` | [`declined-finding`](sinter:#declined-finding=v1) |
| `awaiting-approval` | [`awaiting-approval-finding`](sinter:#awaiting-approval-finding=v1) |
| `unapproved-req` | [`unapproved-req-finding`](sinter:#unapproved-req-finding=v1) |

The subject of a finding of the class `declined` or `awaiting-approval`
is a subject text, such as `req:billing#limit`. A subject text holds no
space and no tab, so it is a subject of a finding (term
`findings#finding-subject`). A declined subject of approval gives a
finding of the class `declined` and none of the class
`awaiting-approval`. Two declared items of one tree with the same kind
of item and the same name have the same subject text, so they give at
most one finding of each class. The spot of that finding is that of the
first of them in the subject order (term `subject-order`) for which the
term of the class holds.

The subject of a finding of the class `unapproved-req` is the position
subject of the citation entry or the inline citation of its edge, such
as `src/fee.ml@L3C4`, as for the class `dangling` of Documents.

## 3. Parameters

### 3.1 `approval-kinds`

The parameter `approval-kinds` gives the kinds of subject of approval
that need approval by a person, by its
[bindings](sinter:#approval-binding=v1).

## 4. Definitions

### 4.1 Bindings of `approval-kinds`

@term approval-binding=v1
@cites ontology#{subject-of-approval=v1, parameter=v1, person=v1}

A binding of the parameter `approval-kinds` is a set of kinds of subject
of approval. The empty set is a binding. Under a binding A of
`approval-kinds`, a subject of approval needs approval by a person when,
and only when, its kind is in A.

### 4.2 Subject texts

@term subject-text=v1
@cites {
    rfc/5234,
    rfc/7405,
    identifiers#{slug=v1, full-name=v1},
    ontology#{
        subject-of-approval=v1, declared-item=v1, item-name=v1, tree=v1,
    },
    text#{text=v1, production=v1, rule-name=v1, code-span=v1},
}

A subject text is a text that matches the production `subject-text`:

```abnf
subject-text  = ( %s"design" / %s"decision" ) ":" slug
              / ( %s"spec" / %s"req" / %s"term" ) ":" ( slug / full-name )
```

The kind word of a kind of subject of approval is `design` for an item
of the kind design without the declared items that it holds, `spec` for
an item of the kind specification with the items that it holds, `req`
for an item of the kind requirement that an item of the kind design
holds directly, `term` for a term that an item of the kind design holds
directly, and `decision` for a decision record. The subject text of a
subject of approval of a tree is the kind word of its kind, then `:`,
then the name of its declared item in that tree.

### 4.3 The fields of judgments

@term judgment-field=v1
@cites {
    ledger#{entry-field=v1},
    data-forms#{hash=v1},
    ontology#{
        judgment=v1, ledger-entry=v1, subject-of-approval=v1, person=v1,
    },
    text#{text=v1, hex-digit=v1, code-span=v1},
    documents#{extent-hash=v1},
    #{subject-text=v1},
}

The fields of the kind `approval` and of the kind `decline` are these,
with these values:

- `subject`, a string that is a subject text: the subject text of the
  subject of approval that the person judged;
- `hash`, a string of 64 hex digits, in the form of a hash: the extent
  hash of the declared item of that subject of approval that the person
  judged;
- `saw`, one of the strings `none`, `approval`, and `decline`: the kind
  of the judgment of the same subject text and hash that its writer saw
  as the latest, or `none` when its writer saw none.

The kind `decline` also has the field `reason`, a string: the reason
that the person gave. A ledger entry of the kind `approval` or `decline`
is malformed when, and only when, its object does not have the members
`subject`, `hash`, and `saw`, each with a value of the form that this
term gives for that member, or it is of the kind `decline` and its
object has the member `reason` with a value that is not a string.

### 4.4 The acceptance rule of judgments

@term judgment-acceptance-rule=v1
@cites {
    ledger#{accepted-entry=v1},
    ontology#{ledger=v1, ledger-entry=v1},
    text#{code-span=v1},
    #{judgment-field=v1},
}

For a ledger entry E of the kind `approval` or `decline` and a point P
of a ledger, the judgment before E at P is the latest ledger entry
before P that is of the kind `approval` or `decline`, that is accepted
at its point, and whose values of `subject` and `hash` are the values of
`subject` and `hash` of E; E has no judgment before it at P when no
ledger entry is such. The acceptance rule of the kinds `approval` and
`decline` holds for E at P when, and only when, each of these is true:

1. E is not malformed.
2. The value of `saw` of E is the kind of the judgment before E at P, or
   `none` when E has no judgment before it at P.
3. When E is of the kind `approval`, the value of `saw` of E is not
   `approval`.

The rule reads only the ledger entries before P. So whether each ledger
entry of these two kinds is accepted at its point follows from the
ledger entries before it, in the order of the ledger.

### 4.5 Latest judgments

@term latest-judgment=v1
@cites {
    ledger#{accepted-entry=v1},
    ontology#{
        subject-of-approval=v1, ledger=v1, ledger-entry=v1, tree=v1,
    },
    identifiers#{binding=v1},
    documents#{extent-hash=v1, file-reader-binding=v1},
    text#{code-span=v1},
    #{subject-text=v1, judgment-field=v1},
}

For a subject of approval S of a tree T, a binding F of `file-readers`,
a binding N of `external-namespaces`, and a point P of a ledger, the
latest judgment of S at P under F and N is the latest ledger entry
before P that is of the kind `approval` or `decline`, that is accepted
at its point, whose value of `subject` is the subject text of S in T,
and whose value of `hash` is the extent hash of the declared item of S
in T under F and N. S has no latest judgment at P under F and N when no
ledger entry is such.

### 4.6 The rule for merges

@term merged-content=v1
@cites {
    changes#{commit=v1, default-branch-commit=v1, first-parent-line=v1},
    ontology#{
        subject-of-approval=v1, revised-content=v1, default-branch=v1,
        tree=v1,
    },
    identifiers#{binding=v1},
    documents#{extent-hash=v1, file-reader-binding=v1},
}

For a subject of approval S of a tree T, a binding F of `file-readers`,
and a binding N of `external-namespaces`, the revised content of S in T
has merged into the default branch under F and N when, and only when,
the default branch has a commit, and a commit of the first-parent line
of the commit of the default branch has a tree in which the declared
item of a subject of approval that is the same subject of approval as S
has, under F and N, the extent hash that the declared item of S has in
T under F and N. When the default branch has no commit, the revised
content of no subject of approval has merged into it.

### 4.7 The states of subjects of approval

@term subject-state=v1
@cites {
    ontology#{
        subject-of-approval=v1, approval-state=v1, tree=v1, ledger=v1,
        state=v1,
    },
    identifiers#{binding=v1},
    documents#{file-reader-binding=v1},
    text#{code-span=v1},
    #{approval-binding=v1, latest-judgment=v1, merged-content=v1},
}

For a binding A of `approval-kinds`, a binding F of `file-readers`, a
binding N of `external-namespaces`, a tree T, and a point P of a ledger,
each subject of approval S of T is in exactly one of the states
approved, declined, and neither, in T at P under A, F, and N:

- When S needs approval under A, S is approved when, and only when, its
  latest judgment at P under F and N is of the kind `approval`; it is
  declined when, and only when, that latest judgment is of the kind
  `decline`; and it is neither when, and only when, it has no latest
  judgment at P under F and N.
- When S does not need approval under A, S is approved when, and only
  when, its revised content in T has merged into the default branch
  under F and N; it is neither otherwise; and it is never declined.

The states approved and declined that this term gives are the states
approved and declined of S in T at P that the term
`ontology#approval-state` names. A subject of approval that is neither
is neither approved nor declined.

### 4.8 The subject order

@term subject-order=v1
@cites {
    files#{path=v1},
    text#{code-point-order=v1, position=v1},
    identifiers#{tag-line-text=v1},
    ontology#{subject-of-approval=v1, declared-item=v1, tree=v1},
    documents#{item-file=v1, origin-position=v1, position-order=v1},
}

One subject of approval of a tree comes before another in the subject
order when, and only when, the valid path of the file of its declared
item comes before the valid path of the file of the declared item of
the other in code point order, or the two valid paths are the same and
the origin position of the text of the declaration of its declared item
comes before the origin position of the text of the declaration of the
declared item of the other in the order of positions.

### 4.9 Findings of the class `declined`

@term declined-finding=v1
@cites {
    ontology#{subject-of-approval=v1, declared-item=v1, tree=v1, ledger=v1},
    identifiers#{binding=v1, tag-line-text=v1},
    documents#{
        file-reader-binding=v1, item-file=v1, origin=v1, run-spot=v1,
        tree-finding=v1,
    },
    findings#{finding-subject=v1},
    #{subject-text=v1, subject-state=v1, subject-order=v1},
}

For a binding A of `approval-kinds`, a binding F of `file-readers`, a
binding N of `external-namespaces`, and a point P of a ledger, a tree T
has, at P under A, F, and N, one tree finding of the class `declined`
for each text t that is the subject text of a subject of approval of T
that is declined in T at P under A, F, and N. Its subject is t. Its
spot is the spot of the run of the text of the declaration of the
declared item of the first of these subjects of approval with the
subject text t, in the subject order, in the text of its file.

### 4.10 Findings of the class `awaiting-approval`

@term awaiting-approval-finding=v1
@cites {
    ontology#{
        subject-of-approval=v1, declared-item=v1, in-force-item=v1,
        tree=v1, ledger=v1,
    },
    identifiers#{binding=v1, tag-line-text=v1},
    documents#{
        file-reader-binding=v1, item-file=v1, origin=v1, run-spot=v1,
        tree-finding=v1,
    },
    findings#{finding-subject=v1},
    #{
        approval-binding=v1, subject-text=v1, subject-state=v1,
        subject-order=v1,
    },
}

For a binding A of `approval-kinds`, a binding F of `file-readers`, a
binding N of `external-namespaces`, and a point P of a ledger, a tree T
has, at P under A, F, and N, one tree finding of the class
`awaiting-approval` for each text t that is the subject text of a
subject of approval S of T such that S needs approval under A, the
declared item of S is in force in T at P, and S is neither in T at P
under A, F, and N. Its subject is t. Its spot is the spot of the run of
the text of the declaration of the declared item of the first of these
subjects of approval with the subject text t, in the subject order, in
the text of its file.

### 4.11 Findings of the class `unapproved-req`

@term unapproved-req-finding=v1
@cites {
    identifiers#{binding=v1, citation-entry=v1, inline-citation=v1},
    ontology#{
        edge=v1, satisfies-edge=v1, verifies-edge=v1,
        subject-of-approval=v1, declared-item=v1, tree=v1, ledger=v1,
    },
    documents#{
        file-reader-binding=v1, tree-edge=v1, origin=v1,
        origin-position=v1, position-subject=v1, run-spot=v1,
        tree-finding=v1,
    },
    #{approval-binding=v1, subject-state=v1},
}

For a binding A of `approval-kinds`, a binding F of `file-readers`, a
binding N of `external-namespaces`, and a point P of a ledger, a tree T
has, at P under A, F, and N, one tree finding of the class
`unapproved-req` for each edge of T of the kind `satisfies` or
`verifies` that says what its kind of edge says, and whose cited item is
an item of the kind requirement whose subject of approval needs approval
under A and is not approved in T at P under A, F, and N. Its subject is
the position subject of the origin position of the citation entry or of
the inline citation of the edge. Its spot is the spot of the run of that
citation entry or inline citation in the text of the file.

## 5. Requirements

### 5.1 The states of subjects of approval

@req give-subject-states=v1
@cites {
    ontology#{subject-of-approval=v1, tree=v1, ledger=v1},
    identifiers#{binding=v1, accept-inputs=v1},
    documents#{file-reader-binding=v1},
    text#{conforming-program=v1, result=v1},
    #{subject-state=v1},
}

Under a binding A of `approval-kinds`, a valid binding F of
`file-readers`, and a binding N of `external-namespaces` for which a
conforming program of the design Identifiers gives the result "valid",
when a conforming program gives whether a subject of approval of a tree
is approved or declined at a point of a ledger under these bindings, it
must give that it is approved when, and only when, it is approved in
that tree at that point under A, F, and N, and that it is declined
when, and only when, it is declined there.

### 5.2 The acceptance of judgments

@req give-judgment-acceptance=v1
@cites {
    ledger#{accepted-entry=v1},
    ontology#{ledger=v1, ledger-entry=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{judgment-acceptance-rule=v1},
}

When a conforming program gives whether a ledger entry of the kind
`approval` or `decline` is accepted at a point of a ledger, it must give
that it is accepted when, and only when, the acceptance rule of the
kinds `approval` and `decline` holds for that ledger entry at that
point.

### 5.3 The content that a judgment records

@req record-judged-content=v1
@cites {
    ontology#{
        judgment=v1, person=v1, subject-of-approval=v1,
        revised-content=v1, tree=v1, ledger=v1,
    },
    identifiers#{binding=v1},
    documents#{extent-hash=v1, file-reader-binding=v1},
    text#{conforming-program=v1, code-span=v1},
    #{subject-text=v1, judgment-field=v1},
}

When a conforming program appends to a ledger a ledger entry of the kind
`approval`, or of the kind `decline`, to record that a person approved,
or declined, the revised content that a subject of approval S has in a
tree T, under a binding F of `file-readers` and a binding N of
`external-namespaces`, the value of `subject` of that ledger entry must
be the subject text of S in T, and its value of `hash` must be the
extent hash of the declared item of S in T under F and N.

### 5.4 No state under bindings that are not valid

@req give-no-states-under-invalid-bindings=v1
@cites {
    ontology#{subject-of-approval=v1, tree=v1},
    identifiers#{binding=v1, accept-inputs=v1},
    documents#{file-reader-binding=v1},
    text#{conforming-program=v1, result=v1},
    #{
        subject-state=v1, declined-finding=v1,
        awaiting-approval-finding=v1, unapproved-req-finding=v1,
    },
}

Under a binding of `file-readers` that is not valid, or under a binding
of `external-namespaces` for which a conforming program of the design
Identifiers gives the result "invalid", a conforming program must give,
for any tree, no state approved or declined of a subject of approval,
and no finding of the classes `declined`, `awaiting-approval`, and
`unapproved-req`.

### 5.5 The findings of a tree

@req give-approval-findings=v1
@cites {
    ontology#{finding-class=v1, tree=v1, ledger=v1},
    identifiers#{binding=v1, accept-inputs=v1},
    documents#{file-reader-binding=v1, tree-finding=v1},
    text#{conforming-program=v1, result=v1},
    #{
        declined-finding=v1, awaiting-approval-finding=v1,
        unapproved-req-finding=v1,
    },
}

Under a binding A of `approval-kinds`, a valid binding F of
`file-readers`, and a binding N of `external-namespaces` for which a
conforming program of the design Identifiers gives the result "valid",
when a conforming program gives the findings of a tree at a point of a
ledger of one of the classes `declined`, `awaiting-approval`, and
`unapproved-req` under these bindings, it must give each tree finding of
that class that the tree has at that point under A, F, and N once, and
no other finding of that class.

## 6. Conformance

A program, or a part of a program, conforms to this design when it is a
conforming program of this design: when it meets every requirement of
section 5.

The vectors of this design are in the file
[`approval.test-vectors.jsonl`](approval.test-vectors.jsonl), in the
same folder as this design. A vector is an input and what a conforming
program gives for it. Each vector follows from the requirements and adds
nothing to them. The vectors are in three groups, `acceptance`,
`findings`, and `states`, and each group has a subsection below. The
subsection names the requirements that the vectors of the group follow
from, and it describes their inputs, results, and values. No vector
follows from the requirements `record-judged-content` and
`give-no-states-under-invalid-bindings`.

Each requirement from which vectors follow applies only when a program
gives the thing that it names, such as whether a ledger entry is
accepted at a point. So a vector holds a program only to what the
program gives for the input. The input of each vector stands for a valid
ledger of a git repository that holds its ledger objects, and for a
binding of `file-readers` that is valid and a binding of
`external-namespaces` for which a conforming program of Identifiers
gives the result "valid", and no other process changes these inputs
while the program reads them.

The file is a [test-vector set](sinter:data-forms#test-vector-set=v1).
Each line of the file is the
[canonical byte sequence](sinter:data-forms#canonical-byte-sequence=v1)
of one JSON object, then the byte 0x0A, so each line is a JSON text, as
RFC 8259 defines it. The file has three kinds of line, in this order:

1. The first line is the set line. Its JSON object has one member,
   `rev`: the revision of the whole set of vectors.
2. Then each group has a group line, in this order: `acceptance`,
   `findings`, `states`. Its JSON object has two members: `group`, the
   name of the group, as a JSON string, and `rev`, the revision of the
   group.
3. Then each vector has a vector line, in increasing order of the
   numbers of the vectors.

The JSON object of a vector line has these members:

- `n`: the number of the vector, a JSON number written as the decimal
  numeral of a whole number of 1 or more. No other vector of the file
  has this number. A number is given to one vector only: when a vector
  leaves the file, no later vector gets its number, and a new vector
  gets a number greater than each number before it.
- `rev`: the revision of the vector.
- `group`: the name of the group of the vector, as a JSON string.
- `input`: the input.
- `result`: the result that a conforming program gives when it gives a
  result for the input. Only the vectors of the group `states` have this
  member.
- `values`: a JSON object that holds what a conforming program gives
  for the input, other than the result. Only the vectors of the groups
  `acceptance` and `findings` have this member.
- `note`: an explanation of the vector, as a JSON string, which a
  conforming program does not give. A vector has this member only when
  it has an explanation.

No vector has the member `needs`: the vectors of this design have no
need names.

A revision is a JSON string of `v`, then the decimal numeral of a whole
number of 1 or more, such as `"v1"`. The revision of the set line is the
revision of the whole set, the revision of a group line is the revision
of the group, and the revision of a vector line is the revision of the
vector. A revision rises, to a greater number after its `v`, when the
vectors that it covers change, join, or leave. When the text of this
section, other than its headings and the vector lines that it shows,
changes, the revisions of every vector, every group, and the set rise.
When only the note of a vector changes, no revision rises. A program
does not need the revisions to run the vectors.

Inside the members `input`, `result`, and `values`, a text, such as a
subject text, a hash, or a position subject, is a JSON string whose
characters are the characters of the text, in order. A sequence is a
JSON array of its elements, in order. A binding of `approval-kinds` is a
JSON array of JSON strings: for each kind of subject of approval in the
binding, its kind word, such as `"req"` for an item of the kind
requirement that an item of the kind design holds directly.

### 6.1 Acceptance

The group `acceptance` holds the vectors of the requirement
`give-judgment-acceptance`. Each vector gives a ledger whose judgments
of the kinds `approval` and `decline` are the given ones, in order, and,
for each of them, whether it is accepted at its point.

- `input`: a JSON object with one member, `ledger`: the ledger entries
  of the kinds `approval` and `decline` of the ledger, as a sequence in
  the order of the ledger. Each ledger entry is a JSON object that holds
  the member `kind` and each of the members `subject`, `hash`, `saw`,
  and `reason` that the object of the ledger entry has, with the same
  values; the other members of the object of the ledger entry have no
  effect on the vector. The ledger has no other ledger entry of these
  two kinds.
- `result`: no vector of the group has this member.
- `values`: a JSON object with one member, `accepted`: a JSON array with
  one element for each element of `ledger`, in the same order: `true`
  when that ledger entry is accepted at its point, and `false` when it
  is not.

When a conforming program gives whether one of these ledger entries is
accepted at its point, it gives "accepted" when the element of
`accepted` for it is `true`, and "not accepted" when it is `false`.

```
{"group":"acceptance","input":{"ledger":[{"hash":"7692c3ad3540bb803c020b3aee66cd8887123234ea0c6e7143c0add73ff431ed","kind":"decline","saw":"none","subject":"req:billing#limit"},{"hash":"7692c3ad3540bb803c020b3aee66cd8887123234ea0c6e7143c0add73ff431ed","kind":"approval","saw":"none","subject":"req:billing#limit"}]},"n":3,"note":"an approval after a decline that its writer did not see is not accepted","rev":"v1","values":{"accepted":[true,false]}}
```

### 6.2 Findings

The group `findings` holds the vectors of the requirement
`give-approval-findings`. Each vector gives the subjects of approval of
a tree with their states, whether their declared items are in force,
and the edges of the kinds `satisfies` and `verifies` of the tree, and
it gives the findings of the three classes of the tree at a point of a
ledger, by their subjects.

- `input`: a JSON object with three members. `binding` is a binding of
  `approval-kinds`. `subjects` is the subjects of approval of the tree,
  as a sequence, each a JSON object with three members: `subject`, its
  subject text; `state`, its state in the tree at the point under the
  bindings, one of the JSON strings `"approved"`, `"declined"`, and
  `"neither"`; and `in-force`, `true` when its declared item is in force
  in the tree at the point, and `false` when it is not. `edges` is the
  edges of the tree, as a sequence, each a JSON object with these members:
  `kind`, its kind of edge, a text; `fits`, `true` when the edge says
  what its kind of edge says, and `false` when it does not; `at`, the
  position subject of the origin position of its citation entry or
  inline citation; and, when its cited item is an item of the kind
  requirement that has a subject of approval, `cited`, the index of that
  subject of approval in `subjects`, a JSON number written as the
  decimal numeral of a whole number of 1 or more, counted from 1.
- `result`: no vector of the group has this member.
- `values`: a JSON object with one member, `findings`: a JSON object with
  three members, `awaiting-approval`, `declined`, and `unapproved-req`,
  each a JSON array of the subjects of the tree findings of that class
  that the tree has at the point, each once, in code point order.

When a conforming program gives the findings of one of the three
classes of the tree at the point, it gives one finding with each subject
that the member of `findings` for that class holds, and no other finding
of that class.

```
{"group":"findings","input":{"binding":["req"],"edges":[],"subjects":[{"in-force":true,"state":"declined","subject":"req:billing#limit"},{"in-force":true,"state":"declined","subject":"req:billing#limit"},{"in-force":true,"state":"neither","subject":"req:billing#limit"}]},"n":52,"note":"two declared items with the same kind and name give one finding of a class","rev":"v1","values":{"findings":{"awaiting-approval":["req:billing#limit"],"declined":["req:billing#limit"],"unapproved-req":[]}}}
```

### 6.3 States

The group `states` holds the vectors of the requirement
`give-subject-states`. Each vector gives one subject of approval of a
tree, by its subject text and the extent hash of its declared item, a
binding of `approval-kinds`, the judgments of a ledger, and the trees of
the commits of the first-parent line of the commit of the default
branch, and it gives the state of the subject of approval in the tree at
the point after the last ledger entry of the ledger.

- `input`: a JSON object with four or five members. `binding` is a
  binding of `approval-kinds`. `subject` is the subject text of the
  subject of approval, and `hash` is the extent hash of its declared
  item in the tree. `ledger` is the ledger entries of the kinds
  `approval` and `decline` of the ledger, in the form of the group
  `acceptance`. When the default branch has a commit, `line` is the
  commits of the first-parent line of that commit, as a sequence in the
  order of that line, in which each commit is a JSON array with one
  JSON object for each subject of approval of its tree, which has two
  members: `subject`, its subject text, and `hash`, the extent hash of
  its declared item in that tree. When the default branch has no
  commit, the input has no member `line`.
- `result`: `approved` when the subject of approval is approved in the
  tree at the point, `declined` when it is declined, and `neither` when
  it is neither.
- `values`: no vector of the group has this member.

When a conforming program gives whether the subject of approval is
approved or declined in the tree at the point, it gives that it is
approved when, and only when, `result` is `approved`, and that it is
declined when, and only when, `result` is `declined`.

```
{"group":"states","input":{"binding":["spec"],"hash":"7692c3ad3540bb803c020b3aee66cd8887123234ea0c6e7143c0add73ff431ed","ledger":[],"line":[[{"hash":"3fc4ccfe745870e2c0d99f71f30ff0656c8dedd41cc1d7d3d376b0dbe685e2f3","subject":"req:billing#limit"}],[{"hash":"7692c3ad3540bb803c020b3aee66cd8887123234ea0c6e7143c0add73ff431ed","subject":"req:billing#limit"}],[]],"subject":"req:billing#limit"},"n":44,"note":"the content is in the tree of an earlier commit of the first-parent line","result":"approved","rev":"v1"}
```
