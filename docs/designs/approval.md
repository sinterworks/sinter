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
of a subject of approval and of the revised content that it has in a
tree decides its state. For each other kind, a merge into the default
branch approves it. An `approval` or `decline` ledger entry names its
subject of approval by the kind word of its kind of subject of approval
and the name of its declared item, such as `req:billing#limit`, and its
revised content by an extent hash. Each `approval` or `decline` ledger
entry also has the field `saw` (term `judgment-field`). What a program
records in `saw` follows from the acceptance rule of these two kinds
(term `judgment-acceptance-rule`) and from the requirement
`record-seen-judgments`.

From the Ontology (`ontology`), the design takes subjects of approval,
their five kinds, their declared items, and when two of them are the
same subject of approval; revised content; persons, ledger entries, the
ledger, points of a ledger, and repairs; states, the states approved and
declined, and in force; trees, the default branch, edges with their
kinds and cited items, and when an edge says what its kind of edge says;
findings, finding classes, and parameters with their bindings; and the
requirements `ontology#write-judgments-only-for-persons` and
`ontology#treat-ledger-entries-alike`.

From the Ledger (`ledger`), the design takes the fields of a kind of
ledger entry and the common fields, acceptance rules, and when a ledger
entry is accepted at a point; the ledger of a git repository, which is
its stored ledger; and when that ledger is broken or newer, and the
ledger objects of a git repository; pull commits (term
`ledger#pull-commit`); and the requirements
`ledger#append-only-accepted-entries` and
`ledger#give-states-only-from-valid-ledgers`.

From Documents (`documents`), the design takes the declared items of a
tree with their files and declarations, the bindings of the parameter
`file-readers`, extent hashes, the edges of a tree, origins and origin
positions, position subjects, the order of positions, the spots of runs,
and tree findings; and the requirement
`documents#give-nothing-under-invalid-bindings`. From Changes
(`changes`), it takes commits and their parents, the parameter
`default-branch-name` with its bindings, the commit of the default
branch, first-parent lines, and the requirement
`changes#take-objects-only-from-repositories`. From Findings
(`findings`), it takes the subjects of findings. From Identifiers
(`identifiers`), it takes slugs, full names, kind words, citation
entries, inline citations, status tags, the texts of tag lines, the form
of `@ack` lines with its production `subject`, the parameter
`external-namespaces` with its bindings, and the results that a
conforming program of Identifiers gives. From Files and paths (`files`),
it takes valid paths. From Data forms (`data-forms`), it takes JSON
values with their objects, members, and strings; canonical byte
sequences; the index of an element of a finite sequence; the hash form;
and test-vector sets: the file that holds the conformance vectors of the
design is one. From Text and notation (`text`), it takes texts, code
point order, the notation of productions, and what a conforming program,
an input, and a result are.

The production `subject-text` is written in ABNF, the notation of RFC
5234, with the case-sensitive strings `%s"…"` of RFC 7405. From RFC
8259, the design takes JSON texts, with their objects, members, arrays,
strings, numbers, and the literal names `true` and `false`: each line of
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
| [extent hash](sinter:documents#extent-hash=v1) | the hash that measures the revised content of a declared item of a tree: two revised contents of the same declared item are the same when, and only when, their extent hashes are equal |
| [hash form](sinter:data-forms#hash-form=v1) | the form of a text of exactly 64 hex digits, which a hash has |
| [binding of `approval-kinds`](sinter:#approval-binding=v1) | a set of kinds of subject of approval |
| [need approval](sinter:#approval-binding=v1) | a subject of approval needs approval by a person under a binding of `approval-kinds` when its kind is in that binding |
| [kind word of a kind of subject of approval](sinter:#subject-text=v1) | `design` for an item of the kind design without the declared items that it holds, `spec` for an item of the kind specification with the items that it holds, `req` for an item of the kind requirement that an item of the kind design holds directly, `term` for a term that an item of the kind design holds directly, and `decision` for a decision record |
| [subject text](sinter:#subject-text=v1) | a text that matches the production `subject-text`, such as `req:billing#limit`; the subject text of a subject of approval of a tree is the kind word of its kind of subject of approval, `:`, and the name of its declared item in that tree |
| [judgment](sinter:ontology#judgment=v1) | a ledger entry that records a decision of a person: a ledger entry of the kind `approval`, `decline`, `done`, or `abandoned` |
| an approval, a decline | with an article: a ledger entry of the kind `approval`; a ledger entry of the kind `decline`; without an article, "approval" is the act of a person who approves |
| [field of a kind](sinter:ledger#entry-field=v1) | a member of the object of a ledger entry that a design names for its kind, other than the common fields, such as `subject` |
| [fields of an `approval` or `decline` ledger entry](sinter:#judgment-field=v1) | `subject`, a string that is a subject text; `hash`, a string that fits the hash form; `saw`, one of the strings `none`, `approval`, and `decline`; and, for a decline only, the optional `reason`, a string |
| [malformed](sinter:#judgment-acceptance-rule=v1) | of a ledger entry of the kind `approval` or `decline`: its object lacks one of the members `subject`, `hash`, and `saw`, or its `subject` is not a string that is a subject text, its `hash` is not a string that fits the hash form, or its `saw` is not one of the strings `none`, `approval`, and `decline` |
| [acceptance rule](sinter:ledger#accepted-entry=v1), [accepted](sinter:ledger#accepted-entry=v1) | the condition under which a ledger entry of one kind can stand at a point of a ledger; a ledger entry is accepted at a point when the acceptance rule of its kind holds for it there |
| [index in a ledger](sinter:#ledger-index=v1), [point of an index](sinter:#ledger-index=v1) | the number, counted from 1, of an element of the sequence of a ledger; the point of the index k is the point of the first k − 1 ledger entries |
| [count at an index](sinter:#judgment-acceptance-rule=v1) | the ledger entry at an index counts at that index when it is of the kind `approval` or `decline` and is accepted at the point of that index |
| [judgment before a ledger entry at a point](sinter:#judgment-acceptance-rule=v1) | of a ledger entry E of the kind `approval` or `decline` at a point P: the ledger entry at the greatest index before P at which the ledger entry counts and has the values of `subject` and `hash` of E, or none |
| [acceptance rule of `approval` and `decline`](sinter:#judgment-acceptance-rule=v1) | it holds for a ledger entry E of one of these kinds at a point P when E is not malformed, its `saw` is the kind of the judgment before E at P, or `none` when there is none, and, for an approval, its `saw` is not `approval` |
| [latest judgment](sinter:#latest-judgment=v1) | of a subject of approval of a tree at a point of a ledger, under a binding of `file-readers` and a binding of `external-namespaces`: of the ledger entries of the kind `approval` or `decline` that count at their indexes before the point and that name the subject text and the extent hash that the subject of approval has in the tree, the one at the greatest index, or none |
| [first-parent line](sinter:changes#first-parent-line=v1) | the sequence of commits that starts with a commit and goes on, from each commit, to its first parent, until a commit with no parent |
| [commit of the default branch](sinter:changes#default-branch-commit=v1) | under a binding of the parameter `default-branch-name`, the commit of the first of the three refs of the default branch that exists: the upstream of the branch, the branch itself, and the remote-tracking branch of `origin` with its name; none when none of them exists, when the first that exists has no commit, or when the binding is not a branch name |
| [has merged](sinter:#merged-content=v1) | under bindings of `default-branch-name`, `file-readers`, and `external-namespaces`, the revised content of a subject of approval in a tree has merged into the default branch of a git repository when the default branch of that git repository has a commit, and the tree of a commit of the first-parent line of that commit gives the same subject of approval the same extent hash |
| [approved, declined, neither](sinter:#subject-state=v1) | the three states of a subject of approval in a tree, at a point of the ledger of a git repository, under the bindings of the parameters |
| [in force](sinter:ontology#in-force-item=v1) | a declared item is in force in a tree, at a point of a ledger, when it is not retired there: when it still applies |
| [in force under the bindings](sinter:#bound-in-force-item=v1) | in force as the term `ontology#in-force-item` gives it, where the state approved of the source of each `supersedes` edge follows from the states that the term `subject-state` gives, and where each status tag and each edge is read under the bindings of `file-readers` and `external-namespaces` |
| [subject order](sinter:#subject-order=v1) | the order of the subjects of approval of a tree by the valid paths of the files of their declared items, and then by the positions of their declarations |
| [tree finding](sinter:documents#tree-finding=v1) | a finding of a tree with a given class, subject, and spot, that is not ackable |
| [subject of a finding](sinter:findings#finding-subject=v1) | the text that names what a finding is about |
| [position subject](sinter:documents#position-subject=v1) | the subject of a finding at a position, such as `src/fee.ml@L3C4` |

## 2. Judgments and approval states

### 2.1 Subjects that need approval

The parameter `approval-kinds` gives the kinds of subject of approval
that need approval by a person (term `approval-binding`). For example,
under the binding of the two kinds of subject of approval whose kind
words are `spec` and `req`, the subject of approval `req:billing#limit`
needs approval, and the subject of approval `design:billing` does not.
Under the empty binding, no subject of approval needs approval.

A subject of approval has a subject text (term `subject-text`): the kind
word of its kind of subject of approval, `:`, and the name of its
declared item. For example, the item of the kind requirement
`billing#limit` that the item of the kind design `billing` holds
directly has the subject text `req:billing#limit`, and the item of the
kind design `billing` has the subject text `design:billing`. An item of
the kind requirement that an item of the kind specification holds is no
subject of approval: its subject of approval is the subject of approval
of that item of the kind specification. Two subjects of approval of two
trees are the same subject of approval when, and only when, they have
the same subject text, because the kind word of the kind of subject of
approval gives the kind of item, and the name is the name of the
declared item. So a renamed item is another subject of approval.

### 2.2 The fields of `approval` and `decline` ledger entries

The ledger entries of the kinds `approval` and `decline` are judgments.
Their fields are `subject`, `hash`, and `saw`, and a decline can also
have the field `reason` (term `judgment-field`). For example, this is
the object of an approval, with the common fields of the Ledger:

```
{"by":"Ada Lovelace <ada@example.com>","hash":"50d858e0985ecc7f60418aaf0cc5ab587f42c2570a884095a9e8ccacd0f6545c","id":"e-6cff3eb61833","kind":"approval","saw":"none","seq":12,"subject":"req:billing#limit","v":1}
```

The field `subject` names the subject of approval by its subject text.
The field `hash` names the revised content by its extent hash: the
extent hash of the declared item of the subject of approval in the tree
whose revised content the person approved or declined (requirement
`record-judged-content`). After an edit back to a revised content that a
person approved or declined, the latest judgment of the subject of
approval can be the same ledger entry again, and it decides the state
again.

The field `saw` holds `none`, `approval`, or `decline`. Its value at the
point at which a program appends the ledger entry is fixed by condition
2 of the acceptance rule (term `judgment-acceptance-rule`) and by the
requirement `record-seen-judgments`. The field `reason` of a decline
holds the reason that the person gave. No state and no acceptance
depends on the member `reason`, whatever its value.

A malformed `approval` or `decline` ledger entry (term
`judgment-acceptance-rule`) is accepted at no point, so it decides no
state, and the ledger stays valid. For example, an approval whose
`subject` is `billing#limit`, with no kind word of a kind of subject of
approval, is malformed.

### 2.3 Acceptance

Each kind of ledger entry that a program appends has an acceptance rule
(term `ledger#accepted-entry`). The term `judgment-acceptance-rule`
gives the rule of the kinds `approval` and `decline`. It reads only the
ledger entry itself and the ledger entries before the point, never a
tree, a binding, or a commit. Its condition on `saw` reads the judgment
before the ledger entry at the point, and the rule compares `saw` only
with the kind of that judgment. A program appends a ledger entry only at
a point at which it is accepted (requirement
`ledger#append-only-accepted-entries`). Each index of a ledger has its
own point (term `ledger-index`), and the ledger entry at an index counts
there when it is accepted at the point of that index (term
`judgment-acceptance-rule`). Whether the ledger entry at an index counts
there follows from the ledger entry itself and the ledger entries before
it, in the order of the ledger.

These cases show the rule. In each, X is one subject text and one hash.

1. Clone A appends an approval of X with `saw` `none`. Before A pushes,
   clone B pushes a decline of X with `saw` `none`. A pulls: the decline
   of B comes first. The program did not give the person that decline,
   so the approval of A has `saw` `none`, and it is not accepted at its
   new point. So the pull drops it and reports it
   (requirement `ledger#report-leaving-entries`), and the person decides
   again.
2. A person declines X, and later approves X on purpose. The approval
   has `saw` `decline`, and it is accepted.
3. Two clones each approve X with `saw` `none`, one after the other. The
   second approval is not accepted at its point. An approval with `saw`
   `approval` is never accepted either. So no accepted approval of X has
   an approval as its judgment before it at its point.
4. A person declines X twice, with two reasons. The second decline has
   `saw` `decline`, and it is accepted.
5. A person approves X, and later declines it. The decline has `saw`
   `approval`, and it is accepted. A decline with `saw` `none` after
   that approval is not.
6. A ledger holds a decline D1 of X. Clone A appends an approval of X
   with `saw` `decline`. Before A pushes, clone B appends a second
   decline D2 of X with `saw` `decline` and pushes it. A pulls: D2
   comes before the approval, which is accepted at its new point,
   because its `saw` is the kind of D2. So an approval can stand after
   a decline that the program did not give the person, when it gave
   that person another decline of X.

Only an `approval` or `decline` ledger entry that counts at the index
where it stands can decide a state (term `latest-judgment`). So such a
ledger entry that is not accepted at the point of its index, such as a
repeated approval that a program that does not conform appended,
decides no state. When a repair removes an `approval` or `decline`
ledger entry, each later one of the same subject text and hash is
accepted, or not, by the ledger entries that remain before it.

### 2.4 The latest judgment and the states

A subject of approval of a tree has, at a point of a ledger, a latest
judgment, or none (term `latest-judgment`). The term `subject-state`
gives the three states approved, declined, and neither. The states
approved and declined that it gives are those of subjects of approval
that the term `ontology#approval-state` names.

For a subject of approval that needs approval, the latest judgment
decides. For example, a ledger holds an approval of `req:billing#limit`
with the extent hash H1, then an approval with the extent hash H2. In a
tree in which the requirement has the extent hash H1, it is approved;
with H2, it is approved; with a third extent hash, it is neither
approved nor declined.

For a subject of approval that does not need approval, the merge
decides (term `merged-content`). An `approval` or `decline` ledger entry
of such a subject of approval changes no state while the binding stays
the same. Under another binding, in which its kind needs approval, the
same ledger entry can decide the state.

Only `seq` orders `approval` and `decline` ledger entries, because it
gives the order of the ledger. The writer, the person, the branch, and
the time of a ledger entry change no state (requirement
`ontology#treat-ledger-entries-alike`), so an approval can decide a
state whatever person it records. The `approval` and `decline` ledger
entries that a pull brought from another clone decide states as those
of the clone itself do. One that a clone holds and for which its shared
clone does not account can decide a state in that clone.

### 2.5 Merges

The rule for merges (term `merged-content`) reads the first-parent line
of the commit of the default branch. A merge commit, a squash merge, and
a commit made straight on the default branch each put their tree on that
line, so revised content that came into the default branch in one of
these ways has merged. A commit that the default branch reaches only
through the second parent of a merge commit is not on the line. So when
the default branch fast-forwards to a commit whose first-parent line
leaves out earlier commits of the default branch, revised content that
only those earlier commits held has not merged. When a person moves the
default branch back, revised content that only the commits that left the
line held has not merged.

When the default branch has no commit, no revised content has merged.
A commit that the file `shallow` of a git repository names has no
parents (term `changes#commit`), so the first-parent line ends at that
commit. So the rule does not see revised content that merged only
before that commit.

### 2.6 Bindings and missing inputs

The extent hashes that a state uses, in the tree and in the tree of each
commit of the first-parent line, are those that one binding of
`file-readers` and one binding of `external-namespaces` give. The state
is under one binding of `approval-kinds`, and the commit of the default
branch is the one that one binding of `default-branch-name` gives (term
`subject-state`). The states and the findings are of a tree at a point
of the ledger of one git repository, whose default branch the rule for
merges reads. The requirement `give-no-states-under-invalid-bindings`
covers bindings that are not valid. The requirement
`ledger#give-states-only-from-valid-ledgers` covers a ledger that is
broken or newer and a git repository that does not hold its ledger
objects, also for a kind that does not need approval, and the
requirement `give-no-findings-from-invalid-ledgers` covers the findings
there. A program takes no git object from another git repository
(requirement `changes#take-objects-only-from-repositories`), so when a
git repository lacks the git objects of a tree of the first-parent line,
a program gives, by the requirement `give-subject-states`, the state
that the term `subject-state` gives, or no state.

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
is a subject text, such as `req:billing#limit`. A subject text matches
the production `subject` of the term `identifiers#ack-line`, and it
holds no line feed, so it is a subject of a finding (term
`findings#finding-subject`). Each of the three classes reports only a
subject of approval whose declared item is in force under the bindings,
or an edge whose cited item of the kind requirement is in force under
the bindings (term `bound-in-force-item`), so a retired item gives no
finding of these classes. A subject of approval that is declined gives
no finding of the class `awaiting-approval`. Two subjects of approval of
one tree whose declared items have the same kind of item and the same
name have the same subject text, so they give at most one finding of
each class. The spot of that finding is that of the first subject of
approval of the tree with that subject text in the subject order (term
`subject-order`), whatever its state and whether its declared item is in
force. So the spot does not depend on the ledger or on the states. Two
such subjects of approval can give a finding of the class `declined` and
a finding of the class `awaiting-approval`: both are in force, one of
them is declined, and the other needs approval and is neither.

The subject of a finding of the class `unapproved-req` is the position
subject of the citation entry of its edge, such as `src/fee.ml@L3C4`
(term `documents#position-subject`). An inline citation gives only edges
of the kind `cites`, so it gives no such finding.

## 3. Parameters

### 3.1 `approval-kinds`

The parameter `approval-kinds` gives the kinds of subject of approval
that need approval by a person (term
[`approval-binding`](sinter:#approval-binding=v1)).

## 4. Definitions

### 4.1 Bindings of `approval-kinds`

@term approval-binding=v1
@cites {
    ontology#{subject-of-approval=v1, parameter=v1, person=v1},
    text#{code-span=v1},
}

A binding of the parameter `approval-kinds` is a set of kinds of subject
of approval. The empty set is a binding. Under a binding A of
`approval-kinds`, a subject of approval needs approval by a person when,
and only when, its kind is in A.

### 4.2 Subject texts

@term subject-text=v1
@cites {
    rfc/5234,
    rfc/7405,
    identifiers#{slug=v1, full-name=v1, kind-word=v1},
    ontology#{
        subject-of-approval=v1, declared-item=v1, item-name=v1, tree=v1,
        term=v1, decision-record=v1, containment=v1,
    },
    text#{text=v1, production=v1, rule-name=v1, code-span=v1},
}

A subject text is a text that matches the production `subject-text`:

```abnf
subject-text  = ( %s"design" / %s"decision" ) ":" slug
              / ( %s"spec" / %s"req" / %s"term" ) ":" ( slug / full-name )
```

The five texts `design`, `spec`, `req`, `term`, and `decision` are kind
words of Identifiers. In a subject text, each of them names a kind of
subject of approval. The kind word of a kind of subject of approval is
`design` for an item of the kind design without the declared items that
it holds, `spec` for an item of the kind specification with the items
that it holds, `req` for an item of the kind requirement that an item of
the kind design holds directly, `term` for a term that an item of the
kind design holds directly, and `decision` for a decision record. The
subject text of a subject of approval of a tree is the kind word of its
kind of subject of approval, then `:`, then the name of its declared
item in that tree.

### 4.3 The fields of `approval` and `decline` ledger entries

@term judgment-field=v1
@cites {
    ledger#{entry-field=v1},
    data-forms#{json-value=v1, hash-form=v1},
    ontology#{ledger-entry=v1, subject-of-approval=v1, person=v1},
    text#{text=v1, code-span=v1},
    documents#{extent-hash=v1},
    #{subject-text=v1},
}

The fields of the kind `approval` and of the kind `decline` are these,
with these values:

- `subject`, a string that is a subject text: the subject text of the
  subject of approval that the person approved or declined;
- `hash`, a string that fits the hash form: the extent hash of the
  declared item of that subject of approval that the person approved or
  declined;
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
entries, and the indexes before the point of the first n ledger entries
are the indexes 1 to n.

### 4.5 The acceptance rule of `approval` and `decline` ledger entries

@term judgment-acceptance-rule=v1
@cites {
    ledger#{accepted-entry=v1},
    ontology#{ledger=v1, ledger-entry=v1},
    data-forms#{json-value=v1, hash-form=v1},
    text#{code-span=v1},
    #{subject-text=v1, judgment-field=v1, ledger-index=v1},
}

A ledger entry of the kind `approval` or `decline` is malformed when,
and only when, its object lacks one of the members `subject`, `hash`,
and `saw`, or the value of `subject` is not a string that is a subject
text, or the value of `hash` is not a string that fits the hash form,
or the value of `saw` is not one of the strings `none`, `approval`, and
`decline`.

The ledger entry at the index k of a ledger counts at that index when,
and only when, it is of the kind `approval` or `decline` and is accepted
at the point of the index k.

For a ledger entry E of the kind `approval` or `decline` and a point P
of a ledger, the judgment before E at P is the ledger entry at the
greatest index before P at which the ledger entry counts and whose
values of `subject` and `hash` are the values of `subject` and `hash`
of E. E has no judgment before it at P when no index before P is such.

The acceptance rule of the kinds `approval` and `decline` holds for a
ledger entry E of one of these kinds at a point P of a ledger when, and
only when, each of these is true:

1. E is not malformed.
2. The value of `saw` of E is the kind of the judgment before E at P, or
   `none` when E has no judgment before it at P.
3. When E is of the kind `approval`, the value of `saw` of E is not
   `approval`.

### 4.6 Latest judgments

@term latest-judgment=v1
@cites {
    data-forms#{json-value=v1, index=v1},
    ontology#{
        subject-of-approval=v1, ledger=v1, ledger-entry=v1, tree=v1,
    },
    identifiers#{binding=v1},
    documents#{extent-hash=v1, file-reader-binding=v1},
    text#{code-span=v1},
    #{
        subject-text=v1, judgment-field=v1, ledger-index=v1,
        judgment-acceptance-rule=v1,
    },
}

For a subject of approval S of a tree T, a binding F of `file-readers`,
a binding N of `external-namespaces`, and a point P of a ledger, the
latest judgment of S at P under F and N is the ledger entry at the
greatest index before P at which the ledger entry counts, whose value of
`subject` is the subject text of S in T, and whose value of `hash` is
the extent hash of the declared item of S in T under F and N. S has no
latest judgment at P under F and N when no index before P is such.

### 4.7 The rule for merges

@term merged-content=v1
@cites {
    changes#{commit=v1, default-branch-commit=v1, first-parent-line=v1},
    ontology#{
        subject-of-approval=v1, revised-content=v1, default-branch=v1,
        tree=v1, parameter=v1,
    },
    identifiers#{binding=v1},
    documents#{extent-hash=v1, file-reader-binding=v1},
    text#{code-span=v1},
}

For a git repository R, a subject of approval S of a tree T, a binding D
of `default-branch-name`, a binding F of `file-readers`, and a binding N
of `external-namespaces`, the revised content of S in T has merged into
the default branch of R under D, F, and N when, and only when, the
default branch of R has a commit under D, and a commit of the
first-parent line of that commit has a tree in which the declared item
of a subject of approval that is the same subject of approval as S has,
under F and N, the extent hash that the declared item of S has in T
under F and N. When the default branch of R has no commit under D, the
revised content of no subject of approval has merged into it under D,
F, and N.

### 4.8 The states of subjects of approval

@term subject-state=v1
@cites {
    ontology#{
        subject-of-approval=v1, approval-state=v1, tree=v1, ledger=v1,
        state=v1, default-branch=v1,
    },
    identifiers#{binding=v1},
    changes#{default-branch-commit=v1},
    ledger#{stored-ledger=v1},
    documents#{file-reader-binding=v1},
    text#{code-span=v1},
    #{approval-binding=v1, latest-judgment=v1, merged-content=v1},
}

For a git repository R, a binding A of `approval-kinds`, a binding D of
`default-branch-name`, a binding F of `file-readers`, a binding N of
`external-namespaces`, a tree T, and a point P of the ledger of R, each
subject of approval S of T is in exactly one of the states approved,
declined, and neither, in T at P under A, D, F, and N:

- When S needs approval under A, S is approved when, and only when, its
  latest judgment at P under F and N is of the kind `approval`; it is
  declined when, and only when, that latest judgment is of the kind
  `decline`; and it is neither when, and only when, it has no latest
  judgment at P under F and N.
- When S does not need approval under A, S is approved when, and only
  when, its revised content in T has merged into the default branch of R
  under D, F, and N; it is neither otherwise; and it is never declined.

The states approved and declined that this term gives are the states
approved and declined of S in T at P that the term
`ontology#approval-state` names. A subject of approval that is neither
is neither approved nor declined.

### 4.9 In force under the bindings

@term bound-in-force-item=v1
@cites {
    ontology#{
        declared-item=v1, in-force-item=v1, retired-item=v1,
        effective-supersedes-edge=v1, supersedes-edge=v1,
        approval-state=v1, edge=v1, tree=v1, ledger=v1,
    },
    identifiers#{binding=v1, status-tag=v1},
    changes#{default-branch-commit=v1},
    ledger#{stored-ledger=v1},
    documents#{file-reader-binding=v1},
    text#{code-span=v1},
    #{approval-binding=v1, subject-state=v1},
}

For a git repository R, a binding A of `approval-kinds`, a binding D of
`default-branch-name`, a binding F of `file-readers`, a binding N of
`external-namespaces`, a tree T, and a point P of the ledger of R, a
declared item of T is in force in T at P under A, D, F, and N when, and
only when, it is in force in T at P (term `ontology#in-force-item`),
read as this term gives. The terms `ontology#effective-supersedes-edge`
and `ontology#retired-item` read the state approved of the source of
each `supersedes` edge; that state follows, by the term
`ontology#approval-state`, from the states that the term
`subject-state` gives for R under A, D, F, and N. Each status tag and
each edge that these terms read is read under F and N.

### 4.10 The subject order

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
the origin position of the text of the tag line of the declaration of
its declared item comes before the origin position of the text of the
tag line of the declaration of the declared item of the other in the
order of positions.

### 4.11 Findings of the class `declined`

@term declined-finding=v1
@cites {
    ontology#{
        subject-of-approval=v1, declared-item=v1, tree=v1, ledger=v1,
    },
    identifiers#{binding=v1, tag-line-text=v1},
    documents#{
        file-reader-binding=v1, item-file=v1, origin=v1, run-spot=v1,
        tree-finding=v1,
    },
    changes#{default-branch-commit=v1},
    ledger#{stored-ledger=v1},
    findings#{finding-subject=v1},
    text#{code-span=v1},
    #{
        approval-binding=v1, subject-text=v1, subject-state=v1,
        bound-in-force-item=v1, subject-order=v1,
    },
}

For a git repository R, a binding A of `approval-kinds`, a binding D of
`default-branch-name`, a binding F of `file-readers`, a binding N of
`external-namespaces`, and a point P of the ledger of R, a tree T has,
at P under A, D, F, and N, one tree finding of the class `declined` for
each text t that is the subject text of a subject of approval S of T
such that S is declined in T at P under A, D, F, and N, and the
declared item of S is in force in T at P under A, D, F, and N. Its
subject is t. Its spot is the spot of the run of the text of the tag
line of the declaration of the declared item of the first subject of
approval of T whose subject text is t, in the subject order, in the text
of the file of that declared item.

### 4.12 Findings of the class `awaiting-approval`

@term awaiting-approval-finding=v1
@cites {
    ontology#{
        subject-of-approval=v1, declared-item=v1, tree=v1, ledger=v1,
    },
    identifiers#{binding=v1, tag-line-text=v1},
    documents#{
        file-reader-binding=v1, item-file=v1, origin=v1, run-spot=v1,
        tree-finding=v1,
    },
    changes#{default-branch-commit=v1},
    ledger#{stored-ledger=v1},
    findings#{finding-subject=v1},
    text#{code-span=v1},
    #{
        approval-binding=v1, subject-text=v1, subject-state=v1,
        bound-in-force-item=v1, subject-order=v1,
    },
}

For a git repository R, a binding A of `approval-kinds`, a binding D of
`default-branch-name`, a binding F of `file-readers`, a binding N of
`external-namespaces`, and a point P of the ledger of R, a tree T has,
at P under A, D, F, and N, one tree finding of the class
`awaiting-approval` for each text t that is the subject text of a
subject of approval S of T such that each of these is true:

1. S needs approval under A.
2. The declared item of S is in force in T at P under A, D, F, and N.
3. S is neither in T at P under A, D, F, and N.

Its subject is t. Its spot is the spot of the run of the text of the tag
line of the declaration of the declared item of the first subject of
approval of T whose subject text is t, in the subject order, in the text
of the file of that declared item.

### 4.13 Findings of the class `unapproved-req`

@term unapproved-req-finding=v1
@cites {
    identifiers#{binding=v1, citation-entry=v1},
    ontology#{
        edge=v1, satisfies-edge=v1, verifies-edge=v1,
        subject-of-approval=v1, declared-item=v1, tree=v1, ledger=v1,
    },
    documents#{
        file-reader-binding=v1, tree-edge=v1, origin=v1,
        origin-position=v1, position-subject=v1, run-spot=v1,
        tree-finding=v1,
    },
    changes#{default-branch-commit=v1},
    ledger#{stored-ledger=v1},
    text#{code-span=v1},
    #{approval-binding=v1, subject-state=v1, bound-in-force-item=v1},
}

For a git repository R, a binding A of `approval-kinds`, a binding D of
`default-branch-name`, a binding F of `file-readers`, a binding N of
`external-namespaces`, and a point P of the ledger of R, a tree T has,
at P under A, D, F, and N, one tree finding of the class
`unapproved-req` for each edge of T of the kind `satisfies` or
`verifies` that says what its kind of edge says, and whose cited item is
an item of the kind requirement that is in force in T at P under A, D,
F, and N, such that the subject of approval of that item of the kind
requirement needs approval under A and is not approved in T at P under
A, D, F, and N. Its subject is the position subject of the origin
position of the citation entry of the edge. Its spot is the spot of the
run of that citation entry in the text of the file of the edge.

## 5. Requirements

### 5.1 The states of subjects of approval

@req give-subject-states=v1
@cites {
    ontology#{subject-of-approval=v1, tree=v1, ledger=v1},
    identifiers#{binding=v1, accept-inputs=v1},
    changes#{default-branch-commit=v1},
    ledger#{stored-ledger=v1},
    documents#{file-reader-binding=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{approval-binding=v1, subject-state=v1},
}

Under a binding A of `approval-kinds`, a binding D of
`default-branch-name`, a valid binding F of `file-readers`, and a
binding N of `external-namespaces` for which a conforming program of the
design Identifiers gives the result "valid", when a conforming program
gives whether a subject of approval of a tree is approved or declined at
a point of the ledger of a git repository R under these bindings, it
must give that it is approved when, and only when, it is approved in
that tree at that point under A, D, F, and N, and that it is declined
when, and only when, it is declined there.

### 5.2 The acceptance of `approval` and `decline` ledger entries

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

### 5.3 What an `approval` or `decline` ledger entry records

@req record-judged-content=v1
@cites {
    ontology#{
        ledger-entry=v1, person=v1, subject-of-approval=v1,
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
    ontology#{subject-of-approval=v1, tree=v1, finding-class=v1},
    identifiers#{binding=v1, accept-inputs=v1},
    documents#{file-reader-binding=v1},
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
    ontology#{finding-class=v1, tree=v1, ledger=v1},
    identifiers#{binding=v1, accept-inputs=v1},
    changes#{default-branch-commit=v1},
    ledger#{stored-ledger=v1},
    documents#{file-reader-binding=v1, tree-finding=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{
        approval-binding=v1, declined-finding=v1,
        awaiting-approval-finding=v1, unapproved-req-finding=v1,
    },
}

Under a binding A of `approval-kinds`, a binding D of
`default-branch-name`, a valid binding F of `file-readers`, and a
binding N of `external-namespaces` for which a conforming program of the
design Identifiers gives the result "valid", when a conforming program
gives the findings of a tree at a point of the ledger of a git
repository R of one of the classes `declined`, `awaiting-approval`, and
`unapproved-req` under these bindings, it must give each tree finding of
that class that the tree has at that point under A, D, F, and N once,
and no other finding of that class.

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
follows from the requirements `record-judged-content`,
`record-seen-judgments`, `give-no-states-under-invalid-bindings`, and
`give-no-findings-from-invalid-ledgers`.

Each requirement from which vectors follow applies only when a program
gives the thing that it names, such as whether a ledger entry is
accepted at a point. So a vector holds a program only to what the
program gives for the input. The input of each vector stands for a valid
ledger of a git repository that holds its ledger objects; for a binding
of `file-readers` that is valid; for a binding of `external-namespaces`
for which a conforming program of Identifiers gives the result "valid";
and for one binding of `default-branch-name`. Under that binding, the
default branch of that git repository has the commit whose first-parent
line the member `line` of the input of a vector of the group `states`
gives, or no commit when that input has no member `line`; the inputs of
the groups `acceptance` and `findings` do not depend on that binding. No
other process changes these inputs while the program reads them.

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
binding, the kind word of that kind of subject of approval, such as
`"req"` for an item of the kind requirement that an item of the kind
design holds directly, each once, in code point order.

### 6.1 Acceptance

The group `acceptance` holds the vectors of the requirement
`give-judgment-acceptance`. Each vector gives a ledger whose ledger
entries of the kinds `approval` and `decline` are the given ones, in
order, and, for each of them, whether it is accepted at its point.

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
{"group":"acceptance","input":{"ledger":[{"hash":"7692c3ad3540bb803c020b3aee66cd8887123234ea0c6e7143c0add73ff431ed","kind":"decline","saw":"none","subject":"req:billing#limit"},{"hash":"7692c3ad3540bb803c020b3aee66cd8887123234ea0c6e7143c0add73ff431ed","kind":"approval","saw":"none","subject":"req:billing#limit"}]},"n":3,"note":"an approval after a decline that the person was not given is not accepted","rev":"v1","values":{"accepted":[true,false]}}
```

### 6.2 Findings

The group `findings` holds the vectors of the requirement
`give-approval-findings`. Each vector gives the subjects of approval of
a tree with their states, whether their declared items are in force,
and the edges of the tree, each with whether its cited item of the kind
requirement is in force, and it gives the findings of the three classes
of the tree at a point of a ledger, by their subjects.

- `input`: a JSON object with three members. `binding` is a binding of
  `approval-kinds`. `subjects` is the subjects of approval of the tree,
  as a sequence, each a JSON object with three members: `subject`, its
  subject text; `state`, its state in the tree at the point under the
  bindings, one of the JSON strings `"approved"`, `"declined"`, and
  `"neither"`; and `in-force`, `true` when its declared item is in force
  in the tree at the point under the bindings (term
  `bound-in-force-item`), and `false` when it is not. `edges` is the
  edges of the tree, as a sequence, each a JSON object with these
  members: `kind`, its kind of edge, a text; `fits`, `true` when the
  edge says what its kind of edge says, and `false` when it does not;
  `at`, the position subject of the origin position of its citation
  entry or of its inline citation (an inline citation gives only edges
  of the kind `cites`); and, when its cited item is an item of the
  kind requirement that has a subject of approval, two more members:
  `cited`, the index of that subject of approval in `subjects`, a JSON
  number written as the decimal numeral of a whole number of 1 or more,
  counted from 1; and `in-force`, `true` when that item of the kind
  requirement is in force in the tree at the point under the bindings
  (term `bound-in-force-item`), and `false` when it is not.
- `result`: no vector of the group has this member.
- `values`: a JSON object with one member, `findings`: a JSON object
  with three members, `awaiting-approval`, `declined`, and
  `unapproved-req`, each a JSON array of the subjects of the tree
  findings of that class that the tree has at the point, each once, in
  code point order.

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
binding of `approval-kinds`, the `approval` and `decline` ledger entries
of a ledger, and the trees of the commits of the first-parent line of
the commit of the default branch, and it gives the state of the subject
of approval in the tree at the point after the last ledger entry of the
ledger.

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
{"group":"states","input":{"binding":["spec"],"hash":"7692c3ad3540bb803c020b3aee66cd8887123234ea0c6e7143c0add73ff431ed","ledger":[],"line":[[{"hash":"3fc4ccfe745870e2c0d99f71f30ff0656c8dedd41cc1d7d3d376b0dbe685e2f3","subject":"req:billing#limit"}],[{"hash":"7692c3ad3540bb803c020b3aee66cd8887123234ea0c6e7143c0add73ff431ed","subject":"req:billing#limit"}],[]],"subject":"req:billing#limit"},"n":44,"note":"the revised content is in the tree of an earlier commit of the first-parent line","result":"approved","rev":"v1"}
```
