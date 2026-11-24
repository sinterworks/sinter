<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Approval
@design approval=v1
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
@cites ledger=v1
@cites rfc/5234
@cites rfc/7405
@cites rfc/8259
Specifies the subjects of approval that need approval by a person; the optional parameter `persons` of the persons whose judgments and voids count; the acceptance rule, latest counting judgments, agreement, and conflict of `approval` and `decline` statements; the rule for merges and incomplete first-parent lines; the states approved, declined, and neither of subjects of approval; the finding classes `declined`, `awaiting-approval`, and `unapproved-req`, and the conditions on `approval` and `decline` statements for the statement-check finding classes of the Ledger; and requirements for conforming programs that give these states, acceptance, and findings, and that write `approval` and `decline` statements in `.sinter/`.

A person approves or declines the revised content of a subject of
approval, such as the canonical object of an item of the kind
requirement. A binding of the parameter `approval-kinds` says which
kinds of subject of approval need approval by a person. For such a kind,
the latest counting `approval` and `decline` statements that judge the
current canonical object of the subject of approval decide its state.
For each other kind, a merge into the default branch approves it. An
optional binding of the parameter `persons` names the persons whose
judgments (of all four judgment kinds) and voids count. An `approval` or
`decline` statement lives in `.sinter/`, names its judged declared-item
object with both an `about` edge and a `judges` edge (by content id),
and names earlier approval or decline judgments that it replaces with
`revises` edges.

From Conformance (`conformance`), the design takes conforming programs,
inputs, dependence, objects, encodings, valid program's own stores, and
the general requirements that bind every conforming program, including
`conformance#end-runs-at-limits`, `conformance#reject-invalid-inputs`,
`conformance#report-missing-parts`,
`conformance#give-results-over-canonical-objects`, and
`conformance#read-defined-encodings`. From Text and notation (`text`),
the design takes texts, characters, whole numbers, decimal numerals,
code point order, positions, productions, rule names, code spans, and
results. From Identifiers (`identifiers`), the design takes slugs, full
names, kind words, content ids, citation entries, inline citations,
status tags, the texts of tag lines, the form of `@ack` lines with its
production `subject`, the parameter `external-namespaces`, and
`identifiers#validate-bindings`. From Files and paths (`files`), the
design takes valid paths. From Data forms (`data-forms`), the design
takes JSON values, the index of an element of a finite sequence, the
hash form, canonical byte sequences, vector lines, the forms of a group,
the meaning of a vector, and test-vector sets. The file that holds the
conformance vectors of the design is a test-vector set.

From the Ontology (`ontology`), the design takes subjects of approval,
their seven kinds, declared items, `same-item`, containment (including
`.sinter/` containment), schemas, atoms, terms, and decision records;
objects, the schema table `object-kind`, content hashes, content ids,
computed identity objects, revised content, and encodings; persons,
agents, statements, judgments, voids, object withdrawal and counting
voids, things and latest statements, agreement and conflicts, states,
approval states, deprecated items (including the `status` member in
`.sinter/`), effective `supersedes` edges, retired items, and in-force
items; trees, the default branch, tests, sites, edges with their kinds
and cited items, finding classes, and parameters; and the requirements
`ontology#treat-ledger-entries-alike` and
`ontology#write-judgments-only-for-persons`. From the Object store
(`object-store`), the design takes store files, valid object files, the
object store of a tree (with its validity and missing computed identity
objects), `object-store#write-object-files`, and the five store safety
obligations (`object-store#limit-store-writes`,
`object-store#keep-store-files-unchanged`,
`object-store#write-no-file-after-stop`,
`object-store#write-no-file-after-read-error`, and
`object-store#limit-store-deletions`). From the ledger (`ledger`), the
design takes acceptance rules (`ledger#accepted-entry`) and the
statement-check finding classes for unaccepted statements and conflicts.
From Documents (`documents`), the design takes declared items of the
text encoding with their files and declarations, the parameter
`file-readers`, read files, the edges of a tree, origins and origin
positions, position subjects, edge finding subjects, the order of
positions, the spots of runs, and tree findings. From Changes
(`changes`), the design takes commits and their parents, the files of
the tree of a commit, the parameter `default-branch-name`, the commit of
the default branch, first-parent lines, shallow commits, and repository
reads. From Findings (`findings`), the design takes finding subjects and
spots.

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
| [same subject of approval](sinter:ontology#subject-of-approval=v1) | two subjects of approval of two trees are the same when their declared items are the [same item](sinter:ontology#same-item=v1) (declared items with the same name, whatever their kinds and encodings) |
| [revised content](sinter:ontology#revised-content=v1) | the content that a declared item's canonical object represents; two revised contents of the same declared item are the same when, and only when, their canonical objects have the same [content hash](sinter:ontology#content-hash=v1) |
| [content hash](sinter:ontology#content-hash=v1), [content id](sinter:ontology#content-id=v1) | the SHA-256 hash (64 lowercase hex digits) of the canonical byte sequence of an object (no `id`, no final line feed); the object kind word of the object, `:`, and the first 32 hex digits of its content hash |
| [binding of `approval-kinds`](sinter:#approval-kinds=v1) | a set of kinds of subject of approval |
| [need approval](sinter:#approval-need=v1) | a subject of approval needs approval by a person under a valid binding of `approval-kinds` when its kind is in that binding |
| [binding of `persons`](sinter:#persons=v1), [listed person](sinter:#listed-person=v1) | an optional finite set of texts naming the persons whose judgments (all four kinds) and voids count by exact text equality with `by`; unbound means every person's judgments and voids count, and the empty set means no person's judgments or voids count |
| [kind word of a kind of subject of approval](sinter:#subject-text=v1) | `design`, `spec`, `schema`, `req`, `atom`, `term`, or `decision`, matching the object kind word of the declared item of that subject of approval |
| [subject text](sinter:#subject-text=v1) | a text that matches the production `subject-text`, such as `req:billing#limit`: the kind word of a subject of approval's kind, `:`, and the name of its declared item |
| [statement](sinter:ontology#statement=v1) | a record of one of the seven statement kinds stored as a fixed object file in `.sinter/` |
| [judgment](sinter:ontology#judgment=v1) | a statement that records a decision of a person: a statement of the kind `approval`, `decline`, `done`, or `abandoned` |
| approval or decline judgment | a statement of the kind `approval` (an **approval judgment**) or `decline` (a **decline judgment**), which judges one declared-item object |
| [counting void](sinter:ontology#object-withdrawal=v1), [withdrawn](sinter:ontology#object-withdrawal=v1) | a `void` statement in `.sinter/` that meets its acceptance rule, carries no `agent`, satisfies `listed-person`, and meets the copy rule when its withdrawn object is present; an object named by a counting void's `withdraws` edge |
| [store file](sinter:object-store#store-file=v1), [valid object file](sinter:object-store#valid-object-file=v1), [object store of a tree](sinter:object-store#tree-object-store=v1) | a file of a tree under `.sinter/` and outside `.sinter/local/`; a store object file whose line object meets its row of `ontology#object-kind`; the set of all store files of a tree, valid when every store file of the tree is a valid object file |
| [acceptance rule](sinter:ledger#accepted-entry=v1), [accepted](sinter:ontology#thing=v1) | the condition under which a statement of one kind is accepted in a tree; for `approval` and `decline`, the atom [`judgment-acceptance-rule`](sinter:#judgment-acceptance-rule=v1) |
| [counts](sinter:ontology#thing=v1), [latest counting judgment](sinter:#latest-judgment=v1) | an approval or decline judgment counts in a tree when it is accepted, not withdrawn by a counting void, carries no `agent`, and meets `listed-person`; a latest counting judgment of a declared-item object is a counting approval or decline judgment of that object that no other counting approval or decline judgment of that object replaces and that no counting void's copied `revises` edge keeps replaced |
| [agreement](sinter:#judgment-conflict=v1), [conflict](sinter:#judgment-conflict=v1) | two or more latest counting approval or decline judgments of one declared-item object agree when all are `approval` or all are `decline`, and conflict when at least one is `approval` and at least one is `decline` |
| [read file](sinter:documents#read-file=v1) | under a valid binding of `file-readers`, a file of a tree outside `.sinter/` whose valid path has a reader, has no line feed, and has no space and no tab as its first character or as its last character |
| [first-parent line](sinter:changes#first-parent-line=v1) | the sequence of commits that starts with a commit and goes on, from each commit, to its first parent, until a commit with no parent |
| [shallow commit](sinter:changes#shallow-commit=v1) | a commit of a git repository that the file `shallow` of its git folder names |
| [repository read](sinter:changes#repository-read=v1) | an operation in which a program takes things from a git repository or from a working tree of that git repository, with each fetch into that git repository that the program makes during that operation as part of it |
| [commit of the default branch](sinter:changes#default-branch-commit=v1) | the commit that the default branch has, under a valid binding of `default-branch-name` |
| [incomplete first-parent line](sinter:#incomplete-first-parent-line=v1), [complete](sinter:#incomplete-first-parent-line=v1), [visibly merged](sinter:#incomplete-first-parent-line=v1) | for the repository reads from which a program takes the first-parent line of the commit of the default branch and the files of the trees of its commits, a commit of that line is complete when the git repository holds its git tree object, every subtree object, every blob of a read file of its tree under `file-readers`, and every blob of a store file of its tree in `.sinter/` outside `.sinter/local/`; that line is incomplete when any commit of it is shallow, has a missing first parent, or is not complete; revised content has visibly merged when some complete commit of that incomplete line gives the same subject of approval the same content hash |
| [has merged](sinter:#merged-content=v1) | the revised content of a subject of approval in a tree has merged into the default branch of a git repository when the default branch has a commit and the tree of a commit of its first-parent line gives the same subject of approval the same content hash |
| [approved, declined, neither](sinter:#subject-state=v1) | the three states of a subject of approval in a tree, under the bindings of the parameters |
| [reads a merge](sinter:#merge-read-edge=v1) | a `supersedes` edge reads a merge when the state approved of its source can depend on a merge |
| [in force](sinter:ontology#in-force-item=v1) | a declared item is in force in a tree when it is not retired there: when it still applies |
| [in force under the bindings](sinter:#bound-in-force-item=v1) | in force as the atom `ontology#in-force-item` gives it, where the state approved of the source of each `supersedes` edge follows from `subject-state`, and where declared items, status tags (including member `status` in `.sinter/`), containment (`ontology#containment`), and edges come from both encodings |
| [subject order](sinter:#subject-order=v1) | the order of subjects of approval of a tree by the content id of their declared item's canonical object in code point order, and then (for equal canonical objects) file before no-file, valid path in code point order, and declaration origin position |
| [tree finding](sinter:documents#tree-finding=v1) | a finding of a tree with a given class, a given subject, and a given spot or no spot, that is not ackable |
| [subject of a finding](sinter:findings#finding-subject=v1) | the text that names what a finding is about |
| [position subject](sinter:documents#position-subject=v1) | the subject of a finding at a position, such as `src/fee.ml@L3C4` |
| [edge finding subject](sinter:documents#edge-finding-subject=v1) | the subject of a finding on a citation edge whose source is a declared item: the content id of the source, a space, the edge kind, a space, and the content id of the target |

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
item of the kind specification holds is no subject of approval; its
subject of approval is the subject of approval of that item of the kind
specification. Two subjects of approval of two trees are the same
subject of approval when their declared items are the same item
(`ontology#same-item`), and their revised contents are the same when
their canonical objects have the same content hash (and therefore the
same content id, covering `v`, `kind`, `name`, `label`, `status`,
`text`, and `edges`). Because an unpinned citation names a `name`
computed identity object rather than a kind word, changing the kind of
an unpinned target changes neither the canonical object nor the content
id of a citing subject of approval, so its approval stays.

### 2.2 Approval and decline statements and the parameter `persons`

Approval judgments (`approval`) and decline judgments (`decline`) are
statements stored as fixed object files in `.sinter/`, conforming to
their rows of `ontology#object-kind`. For example, this is the canonical
object of an approval judgment that replaces no earlier judgment:

```
{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"req:7692c3ad3540bb803c020b3aee66cd88"},{"kind":"judges","to":"req:7692c3ad3540bb803c020b3aee66cd88"}],"kind":"approval","v":1}
```

Both `about` and `judges` name the content id of the exact declared-item
object that the person approved or declined (requirement
`record-judged-content`). Because the content id comes from the
canonical byte sequence of that declared-item object, moving a declared
item between the text encoding and `.sinter/` without changing its
canonical object keeps its content id and keeps its approvals and
declines. Editing a declared item back to an earlier canonical object
restores that content id, so the approval or decline judgments of that
content id decide its state again.

Zero or more `revises` edges on an approval or decline judgment name the
latest counting approval or decline judgments of that same declared-item
object that the writer saw and replaces. Before a person confirms a
decision that writes an approval or decline judgment with `revises`
edges, the program shows the person each exact approval or decline
judgment that those `revises` edges name (requirement
`record-seen-judgments`). When no latest counting approval or decline
judgment exists — including when a counting void withdrew the only
latest counting judgment — the new statement holds no `revises` edge,
and the program shows no approval or decline judgment in place of a
withdrawn approval or decline judgment. The optional member `reason` of
a decline judgment holds a reason that the person gave; neither
acceptance nor any state depends on `reason`.

A conforming program writes `approval` and `decline` statements into
`.sinter/` through `object-store#write-object-files` and obeys the five
safety obligations of the Object store
(`object-store#limit-store-writes`,
`object-store#keep-store-files-unchanged`,
`object-store#write-no-file-after-stop`,
`object-store#write-no-file-after-read-error`, and
`object-store#limit-store-deletions`) together with
`conformance#end-runs-at-limits` and
`ontology#write-judgments-only-for-persons`. In a run that stops at a
limit of its own, the program ends the run, reports where it reached the
limit as far as it can, gives no other result, and writes nothing
durable. In a run in which the program could not read a file or a folder
under `conformance#input`, the program writes no file in `.sinter/`.

The optional parameter `persons` (schema `persons` and term
`listed-person`) names the persons whose judgments (all four kinds:
`approval`, `decline`, `done`, and `abandoned`) and voids (`void`)
count. Matching is exact text equality with the member `by`. When
`persons` is unbound, every person's judgments and voids count. When
`persons` is bound to the empty set, no person's judgments or voids
count. When `persons` is bound to a value that does not meet the schema
`persons`, whether a judgment or void that meets the other conditions
counts is withheld, and every result whose value depends on whether such
a judgment or void counts is withheld, while every result whose value
does not depend on it is unaffected.

### 2.3 Acceptance, counting, and conflicts

The atom `judgment-acceptance-rule` refines `ledger#accepted-entry` for
the kinds `approval` and `decline`. Acceptance checks that the statement
meets its row of `ontology#object-kind` and that each of its `revises`
edges names an `approval` or `decline` statement of the same
declared-item object (either present in the tree or withdrawn by a
counting void in the tree whose `withdrawn-kind` is `approval` or
`decline` and whose copied `about` edge names that same declared-item
object). Acceptance reads no declared item in the tree, so an approval
whose declared-item object is not yet in the tree is still accepted. An
approval judgment may replace an earlier approval judgment even when no
conflict exists.

Whether an approval or decline judgment counts in a tree follows
`ontology#thing` and `listed-person`: it must be accepted, not withdrawn
by a counting void, carry no `agent` member, and satisfy `listed-person`
under `persons`. A statement that does not count takes no part in the
`revises` graph of its declared-item object: it replaces nothing, is
never a latest counting judgment, and a `revises` edge naming it
replaces nothing. A counting void withdraws an approval or decline
judgment and keeps every earlier approval or decline judgment that the
withdrawn statement replaced out of the latest counting judgments
through the void's copied `revises` edges, whether the withdrawn
statement's file stays in `.sinter/` or is deleted.

For one declared-item object O, the term `latest-judgment` gives the set
of latest counting approval or decline judgments of O, and the atom
`judgment-conflict` refines `ontology#conflict` for them. These cases
show the rules:

1. Two branches each add an approval judgment of O with no `revises`
   edge. Both approval judgments are latest counting judgments. They
   agree, so O is approved and no conflict exists.
2. One branch adds an approval judgment A of O and another branch adds a
   decline judgment D of O, with no `revises` edge between them. Both A
   and D are latest counting judgments. They conflict, so O is neither
   approved nor declined, gives `awaiting-approval` and a conflict
   finding (and no `declined` finding). A person settles the conflict by
   writing one new approval or decline judgment whose `revises` edges
   name both A and D.
3. Ada approves O, and Bo later writes a second approval of O whose
   `revises` edge names Ada's approval. Bo's approval is accepted with
   no conflict, replaces Ada's approval, and leaves O approved.
4. Ada's approval A replaced Bo's earlier decline D (`revises` naming
   D). Cy writes a counting void V that withdraws A (copying A's `about`,
   `judges`, and `revises` edges). A is withdrawn, D stays replaced through V's
   copied `revises` edge, and O has no latest counting judgment (state
   neither). A later approval of O holds no `revises` edge, and the
   program shows no approval or decline judgment in place of A.
5. An approval judgment carries `agent`, has `by` outside a valid binding
   of `persons`, or fails `judgment-acceptance-rule` (for example, its
   `revises` edge names an approval or decline judgment of another
   declared-item object or an absent unvoided content id). That approval
   judgment does not count and does not replace an earlier counting
   decline of O.

### 2.4 States of subjects of approval

The atom `subject-state` refines `ontology#approval-state` and gives
each subject of approval of a tree one of the three states approved,
declined, and neither. For a subject of approval that needs approval
under `approval-kinds`, the latest counting approval or decline
judgments of its current declared-item object decide: non-empty and all
`approval` gives approved; non-empty and all `decline` gives declined;
empty or conflicting (both `approval` and `decline`) gives neither. For
a subject of approval that does not need approval under
`approval-kinds`, the merge into the default branch decides (term
`merged-content`): merged gives approved, not merged gives neither, and
it is never declined.

Under `ontology#treat-ledger-entries-alike`, `ts` and unlisted members
on records change no state, and `by` changes a state only through
membership in a bound `persons`.

### 2.5 Merges

The rule for merges (term `merged-content`) reads the first-parent line
of the commit of the default branch and compares content hashes across
both encodings (text files under `file-readers` and `external-namespaces`,
and valid object files in `.sinter/`). A merge commit, a squash merge,
and a commit made straight on the default branch each put their tree on
that line. A commit reached only through the second parent of a merge
commit is not on that line. When the default branch has no commit under
a valid binding of `default-branch-name`, no revised content has merged.

### 2.6 Bindings and missing inputs

The states and approval findings of a tree use one valid binding of
`approval-kinds`, one valid binding of `file-readers`, one valid binding
of `external-namespaces`, the optional parameter `persons`, a valid
object store of the tree (`object-store#tree-object-store`), and (when
needed for merge-approved kinds or `supersedes` edges that read a merge)
one valid binding of `default-branch-name`.

Any invalid store file (broken or newer) in `.sinter/` makes the object
store of the tree not valid (`object-store#tree-object-store`), so under
`conformance#reject-invalid-inputs` a conforming program gives no
approval state, no acceptance result, and no approval or statement-check
finding for that tree (also for kinds that do not need approval), and
the Object store still gives its `invalid-object-file` findings. By
contrast, acceptance (`give-judgment-acceptance`) and the statement
checks (`give-judgment-check-findings`) read only the object store of
`.sinter/` (and, for `void` acceptance on a change, any valid base-tree
object store that `ledger#accepted-entry` reads) and the optional
parameter `persons`, so they still run under an invalid binding of
`file-readers`, `external-namespaces`, `approval-kinds`, or
`default-branch-name`.
Approval reads no observations on the log branch, so a missing or
rewritten log branch does not hold back Approval's own statement
reading.

When a valid object store of a tree lacks a computed identity file
needed by a stored object (such as a `name` or `pin` object named by a
`supersedes` or `satisfies` edge of a declared item in `.sinter/`), the
object store stays valid (`object-store#tree-object-store`). When no
input of the run supplies that computed identity object or its key, it
is a missing part under `conformance#input`, so under
`conformance#report-missing-parts` a conforming program withholds only
results that need its key and gives every result that does not need its
key.

When the default branch has a commit under a valid binding of
`default-branch-name` and its first-parent line is incomplete for the
repository reads from which a program takes that line and the files of
its commit trees (term `incomplete-first-parent-line`, where commit
completeness covers both read files under `file-readers` and store files
in `.sinter/` outside `.sinter/local/`), a program still gives every
state and every finding that does not need the missing part of that
line, and gives that it cannot see the whole history when a requested
state or finding class depends on the missing part (requirements
`give-subject-states` and `give-approval-findings`).

What a program gives while another process changes a file, a ref, or the
object store is a matter of the quality of an implementation.

### 2.7 Findings

Approval defines three non-ackable tree finding classes and refines two
statement-check finding classes declared by the Ledger.

| class | atom |
|---|---|
| `declined` | [`declined-finding`](sinter:#declined-finding=v1) |
| `awaiting-approval` | [`awaiting-approval-finding`](sinter:#awaiting-approval-finding=v1) |
| `unapproved-req` | [`unapproved-req-finding`](sinter:#unapproved-req-finding=v1) |

The subject of a `declined` or `awaiting-approval` finding is a subject
text, such as `req:billing#limit`. Each of the three classes reports
only a subject of approval whose declared item is in force under the
bindings, or an edge whose cited item is in force under the bindings
(term `bound-in-force-item`, reading status tags from `@deprecated` in
text and from member `status` in `.sinter/`, and containment from
`ontology#containment`). A subject of approval whose latest counting
judgments conflict has state neither, so it gives `awaiting-approval`
and no `declined`. When two declared items of one tree share a subject
text, they give at most one finding of each class, and the spot comes
from the first of them in `subject-order` (content id in code point
order first, then file before no-file, valid path, and origin position):
its declaration tag-line run in text, its object file valid path alone
in `.sinter/`, or no spot when taken from a valid program's own store
with no file.

An `unapproved-req` finding reports a `satisfies` or `verifies` edge
that says what its kind says to an in-force requirement or schema whose
subject of approval needs approval and is not approved. When the source
of the edge is a declared item, the finding has the edge finding subject
and the declared-item edge spot of Documents, once for each distinct
canonical edge. When the source is a test or a site, the finding has the
position subject and the spot of the run of its citation entry, such as
`src/fee.ml@L3C4`.

In addition, requirement `give-judgment-check-findings` obliges a
conforming program to report, using the Ledger's finding classes
`unaccepted-statement` (check "Kind rules") and `statement-conflict`
(check "Conflicts"), each `approval` or `decline` statement in `.sinter/`
for which `judgment-acceptance-rule` does not hold, and each
declared-item content id for which `judgment-conflict` holds.

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

### 3.2 `persons`

@schema persons=v1
@cites {
    ontology#{parameter=v1, person=v1},
    text#{text=v1, code-span=v1},
}

The parameter `persons` is optional. A binding of the parameter
`persons` meets the schema `persons` when, and only when, that binding
is a finite set of texts. The empty set is a valid binding.

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

### 4.2 Listed persons

@term listed-person=v1
@cites {
    ontology#{
        parameter=v1, person=v1, judgment=v1, void-statement=v1,
        object-withdrawal=v1, thing=v1,
    },
    data-forms#{json-value=v1},
    text#{text=v1, code-span=v1},
    #{persons=v1},
}

The optional parameter `persons` gives the persons whose judgments (of
all four kinds: `approval`, `decline`, `done`, and `abandoned`) and
`void` statements count in `ontology#thing` and
`ontology#object-withdrawal`:

- When `persons` is unbound, every judgment and every `void` statement
  satisfies `listed-person`.
- When `persons` is bound to a valid binding L (schema `persons`), a
  judgment or a `void` statement satisfies `listed-person` under L when,
  and only when, the value of its member `by` is equal (as a text) to an
  element of L. Under the empty binding of `persons`, no judgment and no
  `void` statement satisfies `listed-person`.
- When `persons` is bound to a value that does not meet the schema
  `persons`, whether any judgment or `void` statement that meets the
  other conditions of `ontology#thing` or `ontology#object-withdrawal`
  counts is withheld, and every result whose value depends on whether
  such a judgment or `void` statement counts is withheld, while every
  result whose value does not depend on it is unaffected.

### 4.3 Subject texts

@term subject-text=v1
@cites {
    rfc/5234,
    rfc/7405,
    identifiers#{slug=v1, full-name=v1, kind-word=v1},
    ontology#{
        subject-of-approval=v1, declared-item=v1, item-name=v1,
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
a decision record. The subject text of a subject of approval is the kind
word of its kind of subject of approval, then `:`, then the name of its
declared item.

### 4.4 The acceptance rule of `approval` and `decline` statements

@atom judgment-acceptance-rule=v1
@refines ledger#accepted-entry=v1
@cites {
    ontology#{
        object=v1, object-kind=v1, content-id=v1, statement=v1,
        judgment=v1, void-statement=v1, object-withdrawal=v1, thing=v1,
        edge=v1, tree=v1, parameter=v1,
    },
    object-store#{valid-object-file=v1, tree-object-store=v1},
    data-forms#{json-value=v1},
    text#{code-span=v1},
    #{persons=v1, listed-person=v1},
}

This atom is for a tree T whose object store is valid (or a set of
canonical objects from valid encodings or valid program's own stores), a
statement E of the kind `approval` or `decline`, and the parameter
`persons` (unbound or bound).

The acceptance rule of the kinds `approval` and `decline` holds for E in
T when, and only when, both of these conditions hold:

1. E meets its row of `ontology#object-kind` (including that E holds one
   `about` edge naming a content id of one of the seven declared-item
   kinds, one `judges` edge naming that same content id, and only
   `revises` edges beyond those two, each naming a content id of kind
   `approval` or `decline`).
2. For each `revises` edge of E, naming a content id c, at least one of
   these holds in T:
   - T holds a canonical object of kind `approval` or `decline` with
     content id c that meets its row of `ontology#object-kind` and whose
     `about` edge names the same content id as the `about` edge of E; or
   - T holds a counting void (`ontology#object-withdrawal`, under
     `listed-person`) whose `withdraws` edge names c, whose member
     `withdrawn-kind` is `approval` or `decline`, and that holds an
     `about` edge naming the same content id as the `about` edge of E.

When E meets condition 1, no `revises` edge of E fails condition 2
outright, and for at least one `revises` edge of E naming a content id c
that T does not hold as a canonical `approval` or `decline` object, T
holds a `void` statement naming c with `withdraws` whose
`withdrawn-kind` is `approval` or `decline`, whose `about` edge names
the same content id as the `about` edge of E, and whose counting is
withheld under an invalid binding of `persons`, whether the acceptance
rule holds for E in T is withheld.

Whether the acceptance rule holds for E in T does not depend on whether
T holds the declared-item object named by the `about` and `judges` edges
of E, and does not forbid an `approval` statement from naming an
`approval` statement with `revises`.

### 4.5 Latest counting judgments

@term latest-judgment=v1
@cites {
    ontology#{
        object=v1, object-kind=v1, content-id=v1, statement=v1,
        judgment=v1, void-statement=v1, object-withdrawal=v1, thing=v1,
        edge=v1, tree=v1, parameter=v1, agent=v1,
    },
    object-store#{tree-object-store=v1},
    text#{code-span=v1},
    #{persons=v1, listed-person=v1, judgment-acceptance-rule=v1},
}

This term is for a tree T whose object store is valid (or a set of
canonical objects from valid encodings or valid program's own stores), a
declared-item content id t, and `persons` unbound or bound to a valid
binding L.

An `approval` or `decline` statement E in T counts for t in T (under
`persons`) when, and only when, all five of these conditions hold
(`ontology#thing`):

1. The acceptance rule `judgment-acceptance-rule` holds for E in T.
2. No counting void in T (`ontology#object-withdrawal`, under
   `listed-person`) withdraws E.
3. E does not carry the member `agent`.
4. E satisfies `listed-person` under `persons`.
5. The `about` and `judges` edges of E name t.

An `approval` or `decline` statement that does not count for t in T
takes no part in the replacement graph of t: it replaces nothing, is
never a latest counting judgment of t, and a `revises` edge naming it
replaces nothing.

A statement E that counts for t in T is replaced in T (under `persons`)
when, and only when, either of these holds:

- another `approval` or `decline` statement that counts for t in T holds
  a `revises` edge naming the content id of E; or
- a counting void in T (`ontology#object-withdrawal`, under
  `listed-person`) whose `withdrawn-kind` is `approval` or `decline` and
  that holds an `about` edge naming t also holds a `revises` edge naming
  the content id of E.

The latest counting judgments of t in T (under `persons`) are the
`approval` and `decline` statements that count for t in T and are not
replaced in T.

### 4.6 Agreement and conflict of approval and decline judgments

@atom judgment-conflict=v1
@refines ontology#conflict=v1
@cites {
    ontology#{content-id=v1, thing=v1, tree=v1, parameter=v1},
    object-store#{tree-object-store=v1},
    text#{code-span=v1},
    #{persons=v1, latest-judgment=v1},
}

This atom is for a tree T whose object store is valid (or a set of
canonical objects from valid encodings or valid program's own stores), a
declared-item content id t, and `persons` unbound or bound to a valid
binding L. Let J be the set of latest counting judgments of t in T under
`persons` (`latest-judgment`):

- The latest counting judgments of t agree in T when J has two or more
  elements and either every element of J is of the kind `approval` or
  every element of J is of the kind `decline`.
- A conflict exists for t in T (the latest counting judgments of t
  conflict in T) when J holds at least one statement of the kind
  `approval` and at least one statement of the kind `decline`.

### 4.7 The rule for merges

@term merged-content=v1
@cites {
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
    },
    ontology#{
        subject-of-approval=v1, declared-item=v1, same-item=v1,
        revised-content=v1, content-hash=v1, default-branch=v1, tree=v1,
        parameter=v1, encoding=v1,
    },
    object-store#{tree-object-store=v1},
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1},
    conformance#{conforming-program=v1},
    text#{result=v1, code-span=v1},
}

This term is for a git repository R, a tree T whose object store is
valid, a valid binding D of `default-branch-name`, a valid binding F of
`file-readers`, and a binding N of `external-namespaces` for which a
conforming program of the design Identifiers gives the result "valid".
For a subject of approval S that T has (from the text encoding under F
and N or from the valid object store of T), the revised content of S in
T has merged into the default branch of R under D, F, and N when, and
only when, two conditions are true. First, the default branch of R has a
commit H under D. Second, some commit C of the first-parent line of H
has a tree (whose object store is valid) that has, in either encoding
under F and N, a subject of approval S2 that is the same subject of
approval as S, and the canonical object of the declared item of S2 in
the tree of C has the same content hash (`ontology#content-hash`) as the
canonical object of the declared item of S in T. When the default branch
of R has no commit under D, the revised content of no subject of
approval has merged into the default branch of R under D, F, and N.

### 4.8 The states of subjects of approval

@atom subject-state=v1
@refines ontology#approval-state=v1
@cites {
    ontology#{
        subject-of-approval=v1, declared-item=v1, content-id=v1,
        tree=v1, state=v1, default-branch=v1, parameter=v1, encoding=v1,
    },
    object-store#{tree-object-store=v1},
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
    },
    documents#{file-readers=v1},
    conformance#{conforming-program=v1},
    text#{result=v1, code-span=v1},
    #{
        approval-kinds=v1, persons=v1, approval-need=v1,
        latest-judgment=v1, judgment-conflict=v1, merged-content=v1,
    },
}

This atom is for a git repository R, a valid binding A of
`approval-kinds`, a valid binding F of `file-readers`, a binding N of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", `persons` unbound or bound to a
valid binding L, a tree T whose object store is valid, and, for a
subject of approval that does not need approval under A, a valid binding
D of `default-branch-name`. Each subject of approval S that T has (from
the text encoding under F and N or from the valid object store of T),
with declared-item canonical object content id t, is in exactly one of
the states approved, declined, and neither:

- When S needs approval under A, let J be the set of latest counting
  judgments of t in T under `persons` (`latest-judgment`):
  - S is approved when, and only when, J is not empty and every element
    of J is of the kind `approval`.
  - S is declined when, and only when, J is not empty and every element
    of J is of the kind `decline`.
  - S is neither when, and only when, J is empty or a conflict exists
    for t in T (`judgment-conflict`).
- When S does not need approval under A, S is approved when, and only
  when, the revised content of S in T has merged into the default branch
  of R under D, F, and N (`merged-content`). When S does not need
  approval under A, S is neither when the revised content of S in T has
  not merged into the default branch of R under D, F, and N. When S does
  not need approval under A, S is never declined.

The states approved and declined that this atom gives are the states
approved and declined of S in T that the term `ontology#approval-state`
names. A subject of approval that is neither is neither approved nor
declined.

### 4.9 Edges that read a merge

@term merge-read-edge=v1
@cites {
    ontology#{
        edge=v1, supersedes-edge=v1, declared-item=v1,
        subject-of-approval=v1, approval-state=v1, schema=v1, atom=v1,
        term=v1, containment=v1, tree=v1, parameter=v1, encoding=v1,
    },
    object-store#{tree-object-store=v1},
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1},
    conformance#{conforming-program=v1},
    text#{result=v1, code-span=v1},
    #{approval-kinds=v1, approval-need=v1},
}

Under a valid binding A of `approval-kinds`, a valid binding F of
`file-readers`, and a binding N of `external-namespaces` for which a
conforming program of the design Identifiers gives the result "valid",
for a tree T whose object store is valid, a `supersedes` edge that T has
(in either encoding, with containment under `ontology#containment`)
reads a merge under A when, and only when, one or both of these
conditions are true:

1. The source of the edge has a subject of approval, and that subject of
   approval does not need approval under A.
2. The source of the edge is an item of the kind design, and the subject
   of approval of an item of the kind specification that the source
   holds, or of a schema, an item of the kind requirement, an atom, or a
   term that the source holds directly, does not need approval under A.

### 4.10 In force under the bindings

@term bound-in-force-item=v1
@cites {
    ontology#{
        declared-item=v1, containment=v1, deprecated-item=v1,
        in-force-item=v1, retired-item=v1,
        effective-supersedes-edge=v1, supersedes-edge=v1,
        approval-state=v1, edge=v1, tree=v1, parameter=v1,
        subject-of-approval=v1, encoding=v1,
    },
    object-store#{tree-object-store=v1},
    identifiers#{external-namespaces=v1, validate-bindings=v1, status-tag=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
    },
    documents#{file-readers=v1},
    conformance#{conforming-program=v1},
    text#{result=v1, code-span=v1},
    #{
        approval-kinds=v1, persons=v1, approval-need=v1,
        subject-state=v1, merge-read-edge=v1,
    },
}

This term is for a git repository R, a valid binding A of
`approval-kinds`, a valid binding F of `file-readers`, a binding N of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", `persons` unbound or bound to a
valid binding L, a tree T whose object store is valid, and, when T has a
`supersedes` edge that reads a merge under A (term `merge-read-edge`), a
valid binding D of `default-branch-name`. A declared item that T has (in
the text encoding under F and N or in the valid object store of T) is in
force in T under these bindings when, and only when, that declared item
is in force in T (atom `ontology#in-force-item`), read as this term
gives. The atoms `ontology#effective-supersedes-edge` and
`ontology#retired-item` read the state approved of the source of each
`supersedes` edge from the states that `subject-state` gives for R and T
under these bindings. Each declared item, status tag (in text under F
and N, and in `.sinter/` from its canonical member `status` per
`ontology#deprecated-item`), containment relation
(`ontology#containment`), and edge comes from both encodings of T.

### 4.11 The subject order

@term subject-order=v1
@cites {
    files#{path=v1},
    text#{code-point-order=v1, position=v1},
    identifiers#{tag-line-text=v1},
    ontology#{
        subject-of-approval=v1, declared-item=v1, content-id=v1,
        tree=v1, encoding=v1,
    },
    object-store#{valid-object-file=v1},
    documents#{item-file=v1, origin-position=v1, position-order=v1},
    conformance#{own-store=v1},
}

One subject of approval S1 of a tree T comes before another subject of
approval S2 of T in the subject order when, and only when, one of these
four conditions holds:

1. The content id of the canonical object of the declared item of S1
   comes before the content id of the canonical object of the declared
   item of S2 in code point order.
2. Those two content ids are equal, the declared item of S1 stands in a
   file of T (a text file or a valid object file of `.sinter/`), and the
   declared item of S2 stands in no file of T (comes from a valid
   program's own store with no file).
3. Those two content ids are equal, both declared items stand in files
   of T, and the valid path of the file of the declared item of S1 comes
   before the valid path of the file of the declared item of S2 in code
   point order.
4. Those two content ids are equal, both declared items stand in the
   same text file of T, and the origin position of the text of the tag
   line of the declaration of the declared item of S1 comes before the
   origin position of the text of the tag line of the declaration of the
   declared item of S2 in the order of positions.

### 4.12 Findings of the class `declined`

@atom declined-finding=v1
@cites {
    ontology#{
        subject-of-approval=v1, declared-item=v1, supersedes-edge=v1,
        tree=v1, parameter=v1, encoding=v1,
    },
    object-store#{valid-object-file=v1, tree-object-store=v1},
    identifiers#{
        external-namespaces=v1, validate-bindings=v1, tag-line-text=v1,
    },
    documents#{
        file-readers=v1, item-file=v1, origin=v1, run-spot=v1,
        tree-finding=v1,
    },
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
    },
    findings#{finding-subject=v1, spot=v1},
    conformance#{conforming-program=v1, own-store=v1},
    text#{result=v1, code-span=v1},
    #{
        approval-kinds=v1, persons=v1, approval-need=v1,
        subject-text=v1, subject-state=v1, merge-read-edge=v1,
        bound-in-force-item=v1, subject-order=v1,
    },
}

This atom is for a git repository R, a valid binding A of
`approval-kinds`, a valid binding F of `file-readers`, a binding N of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", `persons` unbound or bound to a
valid binding L, a tree T whose object store is valid, and, when T has a
`supersedes` edge that reads a merge under A (term `merge-read-edge`), a
valid binding D of `default-branch-name`. T has, under these bindings,
one tree finding of the class `declined` for each text t that is the
subject text of a subject of approval S of T such that both of these are
true:

1. S is declined in T under these bindings (`subject-state`).
2. The declared item of S is in force in T under these bindings
   (`bound-in-force-item`).

Its subject is t. Let S0 be the first subject of approval of T, in the
subject order (`subject-order`), whose subject text is t:

- When the declared item of S0 stands in a text file of T, the spot of
  the finding is the spot of the run of the text of the tag line of its
  declaration in the text of that file.
- When the declared item of S0 stands in a valid object file of
  `.sinter/` of T, the spot of the finding is the valid path of that
  valid object file alone, with no span.
- When the declared item of S0 stands in no file of T (comes from a
  valid program's own store with no file), the finding has no spot.

### 4.13 Findings of the class `awaiting-approval`

@atom awaiting-approval-finding=v1
@cites {
    ontology#{
        subject-of-approval=v1, declared-item=v1, supersedes-edge=v1,
        tree=v1, parameter=v1, encoding=v1,
    },
    object-store#{valid-object-file=v1, tree-object-store=v1},
    identifiers#{
        external-namespaces=v1, validate-bindings=v1, tag-line-text=v1,
    },
    documents#{
        file-readers=v1, item-file=v1, origin=v1, run-spot=v1,
        tree-finding=v1,
    },
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
    },
    findings#{finding-subject=v1, spot=v1},
    conformance#{conforming-program=v1, own-store=v1},
    text#{result=v1, code-span=v1},
    #{
        approval-kinds=v1, persons=v1, approval-need=v1,
        subject-text=v1, subject-state=v1, merge-read-edge=v1,
        bound-in-force-item=v1, subject-order=v1,
    },
}

This atom is for a git repository R, a valid binding A of
`approval-kinds`, a valid binding F of `file-readers`, a binding N of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", `persons` unbound or bound to a
valid binding L, a tree T whose object store is valid, and, when T has a
`supersedes` edge that reads a merge under A (term `merge-read-edge`), a
valid binding D of `default-branch-name`. T has, under these bindings,
one tree finding of the class `awaiting-approval` for each text t that
is the subject text of a subject of approval S of T such that each of
these is true:

1. S needs approval under A.
2. The declared item of S is in force in T under these bindings
   (`bound-in-force-item`).
3. S is neither in T under these bindings (`subject-state`).

Its subject is t. Let S0 be the first subject of approval of T, in the
subject order (`subject-order`), whose subject text is t:

- When the declared item of S0 stands in a text file of T, the spot of
  the finding is the spot of the run of the text of the tag line of its
  declaration in the text of that file.
- When the declared item of S0 stands in a valid object file of
  `.sinter/` of T, the spot of the finding is the valid path of that
  valid object file alone, with no span.
- When the declared item of S0 stands in no file of T (comes from a
  valid program's own store with no file), the finding has no spot.

### 4.14 Findings of the class `unapproved-req`

@atom unapproved-req-finding=v1
@cites {
    identifiers#{
        external-namespaces=v1, validate-bindings=v1, citation-entry=v1,
    },
    ontology#{
        edge=v1, satisfies-edge=v1, verifies-edge=v1, supersedes-edge=v1,
        subject-of-approval=v1, declared-item=v1, schema=v1, test=v1,
        site=v1, tree=v1, parameter=v1, encoding=v1,
    },
    object-store#{valid-object-file=v1, tree-object-store=v1},
    documents#{
        file-readers=v1, tree-edge=v1, origin=v1,
        origin-position=v1, position-subject=v1,
        edge-finding-subject=v1, run-spot=v1, tree-finding=v1,
    },
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
    },
    findings#{finding-subject=v1, spot=v1},
    conformance#{conforming-program=v1, own-store=v1},
    text#{result=v1, code-span=v1},
    #{
        approval-kinds=v1, persons=v1, approval-need=v1,
        subject-state=v1, merge-read-edge=v1, bound-in-force-item=v1,
    },
}

This atom is for a git repository R, a valid binding A of
`approval-kinds`, a valid binding F of `file-readers`, a binding N of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", `persons` unbound or bound to a
valid binding L, a tree T whose object store is valid, and, when T has a
`supersedes` edge that reads a merge under A (term `merge-read-edge`), a
valid binding D of `default-branch-name`. T has, under these bindings,
the tree findings of the class `unapproved-req` that the last paragraph
of this atom gives for the edges that T has (in either encoding) such
that all four of these conditions are true:

1. The edge is of the kind `satisfies` or `verifies`, and says what its
   kind of edge says.
2. The cited item of the edge is an item of the kind requirement that
   has a subject of approval, or a schema that has a subject of
   approval.
3. That cited item is in force in T under these bindings
   (`bound-in-force-item`).
4. The subject of approval of that cited item needs approval under A and
   is not approved in T under these bindings (`subject-state`).

When the source of such an edge is a declared item (in a text file, in a
valid object file of `.sinter/`, or from a valid program's own store), T
has one finding for each distinct canonical edge of such edges. Its
subject is the edge finding subject of that canonical edge, and its spot
is the declared-item edge spot of that canonical edge
(`documents#edge-finding-subject`). When the source of such an edge is a
test or a site, T has one finding for that edge. Its subject is the
position subject of the origin position of its citation entry
(`documents#position-subject`), and its spot is the spot of the run of
that citation entry in the text of the file of the edge
(`documents#run-spot`).

### 4.15 Incomplete first-parent lines

@term incomplete-first-parent-line=v1
@cites {
    ontology#{
        default-branch=v1, tree=v1, parameter=v1,
        subject-of-approval=v1, revised-content=v1, content-hash=v1,
        content-id=v1, declared-item=v1, same-item=v1, containment=v1,
        deprecated-item=v1, in-force-item=v1, retired-item=v1,
        effective-supersedes-edge=v1, supersedes-edge=v1, edge=v1,
        approval-state=v1, encoding=v1,
    },
    object-store#{store-file=v1, tree-object-store=v1},
    identifiers#{external-namespaces=v1, validate-bindings=v1, status-tag=v1},
    changes#{
        commit=v1, commit-file=v1, shallow-commit=v1,
        default-branch-name=v1, default-branch-commit=v1,
        first-parent-line=v1, repository-read=v1,
    },
    documents#{file-readers=v1, read-file=v1},
    conformance#{conforming-program=v1},
    text#{result=v1, code-span=v1},
    #{
        approval-kinds=v1, persons=v1, approval-need=v1,
        latest-judgment=v1, declined-finding=v1,
        awaiting-approval-finding=v1, unapproved-req-finding=v1,
    },
}

For a git repository R, a valid binding D of `default-branch-name` under
which the default branch of R has a commit H, a valid binding F of
`file-readers`, and the repository reads from which a program takes the
first-parent line of H and the files of the trees of the commits of that
first-parent line, R holds a git object when R holds that git object at
the end of those repository reads.

A commit C of the first-parent line of H is complete in R under F for
those repository reads when, and only when, R holds the git tree object
of C, every git tree object that a tree entry of the git tree object of
C names, every blob that a regular-file entry of the git tree object of
C names when that regular-file entry gives a file of the tree of C that
is a read file of the tree of C under F, and every blob that a
regular-file entry of the git tree object of C names when that
regular-file entry gives a store file of the tree of C (in `.sinter/`
and outside `.sinter/local/`, `object-store#store-file`).

The first-parent line of H under F is incomplete for those repository
reads when, and only when, one or more of these three conditions is
true:

1. A commit of the first-parent line of H is a shallow commit of R.
2. For some commit C of the first-parent line of H, C is not a shallow
   commit of R, and the commit object of C names as the first parent of
   C a git object that is not a commit of R.
3. Some commit C of the first-parent line of H is not complete in R
   under F for those repository reads.

Under a binding N of `external-namespaces` for which a conforming
program of the design Identifiers gives the result "valid", when the
first-parent line of H under F is incomplete for those repository reads,
the revised content of a subject of approval S of a tree T has visibly
merged in R under D, F, and N for those repository reads when, and only
when, some commit C of the first-parent line of H that is complete in R
under F for those repository reads has a tree (whose object store is
valid) that has, in either encoding under F and N, a subject of approval
S2 that is the same subject of approval as S and whose declared item's
canonical object in the tree of C has the same content hash
(`ontology#content-hash`) as the canonical object of the declared item
of S in T.

Under a valid binding A of `approval-kinds`, D, F, N, and `persons`
unbound or bound to a valid binding L, for a tree T whose object store
is valid, when the first-parent line of H under F is incomplete for
those repository reads:

- Under the least merge for those repository reads, each subject of
  approval S of T (with declared-item object content id t) that needs
  approval under A is approved when, and only when, the set of latest
  counting judgments of t in T under `persons` (`latest-judgment`) is
  not empty and every element of that set is of the kind `approval`; and
  each subject of approval S of T that does not need approval under A is
  approved when, and only when, the revised content of S in T has
  visibly merged in R under D, F, and N for those repository reads.
- For each of the classes `declined`, `awaiting-approval`, and
  `unapproved-req`, the findings of that class under the least merge for
  those repository reads are the tree findings that the atom of that
  class (`declined-finding`, `awaiting-approval-finding`, or
  `unapproved-req-finding`) gives for T under A, F, N, and `persons`
  when `ontology#in-force-item`, `ontology#retired-item`, and
  `ontology#effective-supersedes-edge` read the state approved of the
  source of each `supersedes` edge from the states under the least merge
  for those repository reads (reading declared items, status tags
  including member `status` in `.sinter/`, containment under
  `ontology#containment`, and edges from both encodings).

For a git repository R, a valid binding A of `approval-kinds`, a valid
binding F of `file-readers`, a binding N of `external-namespaces` for
which a conforming program of the design Identifiers gives the result
"valid", `persons` unbound or bound to a valid binding L, and a tree T
whose object store is valid:

- Under the greatest merge, each subject of approval S of T (with
  declared-item object content id t) that needs approval under A is
  approved when, and only when, the set of latest counting judgments of
  t in T under `persons` (`latest-judgment`) is not empty and every
  element of that set is of the kind `approval`; and each other subject
  of approval of T is approved.
- For each of the classes `declined`, `awaiting-approval`, and
  `unapproved-req`, the findings of that class under the greatest merge
  are the tree findings that the atom of that class (`declined-finding`,
  `awaiting-approval-finding`, or `unapproved-req-finding`) gives for T
  under A, F, N, and `persons`, with no binding of
  `default-branch-name`, when `ontology#in-force-item`,
  `ontology#retired-item`, and `ontology#effective-supersedes-edge` read
  the state approved of the source of each `supersedes` edge from the
  states under the greatest merge (reading declared items, status tags
  including member `status` in `.sinter/`, containment under
  `ontology#containment`, and edges from both encodings).

## 5. Requirements

### 5.1 The states of subjects of approval

@req give-subject-states=v1
@cites {
    ontology#{subject-of-approval=v1, tree=v1, state=v1, parameter=v1},
    object-store#{tree-object-store=v1},
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
        repository-read=v1,
    },
    documents#{file-readers=v1},
    conformance#{conforming-program=v1, dependence=v1},
    text#{result=v1, code-span=v1},
    #{
        approval-kinds=v1, persons=v1, approval-need=v1,
        listed-person=v1, subject-state=v1,
        incomplete-first-parent-line=v1,
    },
}

This requirement applies for a git repository R, a tree T whose object
store is valid (`object-store#tree-object-store`), a valid binding A of
`approval-kinds`, a valid binding F of `file-readers`, a binding N of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", `persons` unbound or bound, and a
subject of approval S of T.

When S needs approval under A and `persons` is unbound or bound to a
valid binding L, when a conforming program gives whether S is approved
or declined in T under A, F, N, and `persons`, that conforming program
must give exactly one result, and only "approved", "declined", or
"neither":

- That conforming program must give "approved" when S is approved in T
  under A, F, N, and `persons`.
- That conforming program must give "declined" when S is declined in T
  under A, F, N, and `persons`.
- That conforming program must give "neither" when S is neither in T
  under A, F, N, and `persons`.
- That conforming program must not give that it cannot see the whole
  history for S.

When S needs approval under A and `persons` is bound to a value that
does not meet the schema `persons`, if every valid binding of `persons`
and unbound `persons` give the same state for S in T, the conforming
program must give that state and must not give that it cannot see the
whole history for S; otherwise, the state of S depends on `persons`, and
the conforming program must give no state ("approved", "declined", or
"neither") for S.

When S does not need approval under A, under a valid binding D of
`default-branch-name` (whatever the binding of `persons` is), when a
conforming program gives whether S is approved or declined in T under A,
D, F, and N, these rules apply for the repository reads from which that
conforming program takes the first-parent line of the commit of the
default branch and the files of the trees of its commits:

- When the default branch of R has no commit under D, or when the
  default branch of R has a commit H under D and the first-parent line
  of H under F is not incomplete for those repository reads, that
  conforming program must give exactly one result, and only "approved"
  or "neither": "approved" when S is approved in T under A, D, F, and N,
  and "neither" when S is neither in T under A, D, F, and N; and that
  conforming program must not give that it cannot see the whole history
  for S.
- When the default branch of R has a commit H under D, the first-parent
  line of H under F is incomplete for those repository reads, and the
  revised content of S in T has visibly merged in R under D, F, and N
  for those repository reads, that conforming program must give exactly
  one result, and only "approved", and must not give that it cannot see
  the whole history for S.
- When the default branch of R has a commit H under D, the first-parent
  line of H under F is incomplete for those repository reads, and the
  revised content of S in T has not visibly merged in R under D, F, and
  N for those repository reads, that conforming program must give no
  state ("approved", "declined", or "neither") for S and must give that
  it cannot see the whole history for S.

### 5.2 The acceptance of `approval` and `decline` statements

@req give-judgment-acceptance=v1
@cites {
    ledger#{accepted-entry=v1},
    ontology#{statement=v1, tree=v1, parameter=v1},
    object-store#{tree-object-store=v1},
    conformance#{conforming-program=v1},
    text#{result=v1, code-span=v1},
    #{persons=v1, judgment-acceptance-rule=v1},
}

This requirement applies for a tree T whose object store is valid
(`object-store#tree-object-store`), `persons` unbound or bound, and a
statement E of the kind `approval` or `decline`. When a conforming
program gives whether E is accepted in T:

- When `judgment-acceptance-rule` holds for E in T (and is not withheld
  under an invalid binding of `persons`), that conforming program must
  give exactly one result, "accepted".
- When `judgment-acceptance-rule` does not hold for E in T (and is not
  withheld under an invalid binding of `persons`), that conforming
  program must give exactly one result, "not accepted".
- When whether `judgment-acceptance-rule` holds for E in T is withheld
  under an invalid binding of `persons`, that conforming program must
  give neither "accepted" nor "not accepted" for E.

### 5.3 What an `approval` or `decline` statement records

@req record-judged-content=v1
@cites {
    ontology#{
        object=v1, object-kind=v1, content-id=v1, statement=v1,
        person=v1, subject-of-approval=v1, revised-content=v1, tree=v1,
        edge=v1, parameter=v1, write-judgments-only-for-persons=v1,
    },
    object-store#{
        tree-object-store=v1, write-object-files=v1,
        limit-store-writes=v1, keep-store-files-unchanged=v1,
        write-no-file-after-stop=v1,
        write-no-file-after-read-error=v1, limit-store-deletions=v1,
    },
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1},
    conformance#{conforming-program=v1, end-runs-at-limits=v1},
    text#{result=v1, code-span=v1},
    #{persons=v1, judgment-acceptance-rule=v1},
}

This requirement applies for a working tree T whose object store is
valid (`object-store#tree-object-store`), a valid binding F of
`file-readers`, a binding N of `external-namespaces` for which a
conforming program of the design Identifiers gives the result "valid",
`persons` unbound or bound to a valid binding L, and a subject of
approval S of T whose declared item has canonical object content id t.
When a conforming program writes in `.sinter/` of T a statement E of the
kind `approval` or `decline` to record a decision of a person on the
revised content of S in T, all of these rules apply:

- E must meet its row of `ontology#object-kind`, with `kind` equal to
  `approval` when the person approved that revised content and `decline`
  when the person declined that revised content.
- The one `about` edge and the one `judges` edge of E must both have
  `to` equal to t.
- E must carry no member `agent`.
- The acceptance rule `judgment-acceptance-rule` must hold for E in T
  under `persons`.
- The conforming program must write E as a store object file in
  `.sinter/` of T under `object-store#write-object-files` (and obey
  `object-store#limit-store-writes`,
  `object-store#keep-store-files-unchanged`,
  `object-store#write-no-file-after-stop`, and
  `object-store#write-no-file-after-read-error`).

### 5.4 What `revises` edges on a written approval or decline judgment record

@req record-seen-judgments=v1
@cites {
    ontology#{
        statement=v1, judgment=v1, void-statement=v1,
        object-withdrawal=v1, person=v1, edge=v1, tree=v1, parameter=v1,
    },
    object-store#{tree-object-store=v1},
    conformance#{conforming-program=v1},
    text#{code-span=v1},
    #{persons=v1, latest-judgment=v1},
}

This requirement applies for a working tree T whose object store is
valid (`object-store#tree-object-store`) and `persons` unbound or bound
to a valid binding L. When a conforming program writes in `.sinter/` of
T a statement E of the kind `approval` or `decline` whose `about` and
`judges` edges name declared-item content id t:

- Each `revises` edge of E must name a latest counting judgment of t in
  T under `persons` (`latest-judgment`).
- Before the person whose decision E records confirmed that decision,
  the conforming program must have given that person each exact approval
  or decline judgment that a `revises` edge of E names.
- When t has no latest counting judgment in T under `persons` (including
  when a counting void in T withdrew the only latest counting judgment
  of t), E must hold no `revises` edge, and the conforming program must
  give that person no approval or decline judgment in place of a
  withdrawn approval or decline judgment.

### 5.5 The approval findings of a tree

@req give-approval-findings=v1
@cites {
    ontology#{
        finding-class=v1, subject-of-approval=v1, supersedes-edge=v1,
        tree=v1, parameter=v1,
    },
    object-store#{tree-object-store=v1},
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
        repository-read=v1,
    },
    documents#{file-readers=v1, tree-finding=v1},
    conformance#{
        conforming-program=v1, dependence=v1, report-missing-parts=v1,
    },
    text#{result=v1, code-span=v1},
    #{
        approval-kinds=v1, persons=v1, approval-need=v1,
        listed-person=v1, merge-read-edge=v1, declined-finding=v1,
        awaiting-approval-finding=v1, unapproved-req-finding=v1,
        incomplete-first-parent-line=v1,
    },
}

This requirement applies for a git repository R, a tree T whose object
store is valid (`object-store#tree-object-store`), a valid binding A of
`approval-kinds`, a valid binding F of `file-readers`, a binding N of
`external-namespaces` for which a conforming program of the design
Identifiers gives the result "valid", a binding D of
`default-branch-name`, and `persons` unbound or bound. When a conforming
program gives the findings of one of the classes `declined`,
`awaiting-approval`, and `unapproved-req` of T under these bindings,
these rules apply for the repository reads from which that conforming
program takes the first-parent line of the commit of the default branch
and the files of the trees of its commits:

- When `persons` is unbound or bound to a valid binding L, and either T
  has no `supersedes` edge that reads a merge under A (term
  `merge-read-edge`), or D is a valid binding of `default-branch-name`
  and either the default branch of R has no commit under D or the
  default branch of R has a commit H under D and the first-parent line
  of H under F is not incomplete for those repository reads, that
  conforming program must give each tree finding of that class that T
  has under these bindings once, must give no other finding of that
  class, and must not give that it cannot see the whole history for that
  class.
- When `persons` is unbound or bound to a valid binding L, T has a
  `supersedes` edge that reads a merge under A (term `merge-read-edge`),
  D is a valid binding of `default-branch-name`, the default branch of R
  has a commit H under D, and the first-parent line of H under F is
  incomplete for those repository reads, that conforming program must
  give each finding of that class under the greatest merge once, and
  must give no other finding of that class. In that case, when the
  findings of that class under the least merge for those repository
  reads hold a finding that the findings of that class under the
  greatest merge do not hold, that conforming program must give that it
  cannot see the whole history for that class; otherwise, that conforming
  program must not give that it cannot see the whole history for that
  class.
- When `persons` is unbound or bound to a valid binding L, T has a
  `supersedes` edge that reads a merge under A (term `merge-read-edge`),
  and D is not a valid binding of `default-branch-name`, that conforming
  program must give each finding of that class under the greatest merge
  once, and must give no other finding of that class.
- When `persons` is bound to a value that does not meet the schema
  `persons`, that conforming program must give once each finding of that
  class that holds under every valid binding of `persons` and when
  `persons` is unbound (under the three rules of this requirement for
  unbound or valid bindings of `persons`), and must give no
  finding of that class whose existence depends on the binding of
  `persons`, and no other finding of that class.

### 5.6 Statement-check findings for `approval` and `decline`

@req give-judgment-check-findings=v1
@cites {
    ontology#{
        finding-class=v1, statement=v1, content-id=v1, tree=v1,
        parameter=v1,
    },
    object-store#{tree-object-store=v1},
    ledger#{
        accepted-entry=v1, unaccepted-statement-finding=v1,
        statement-conflict-finding=v1,
    },
    conformance#{conforming-program=v1},
    text#{code-span=v1},
    #{
        persons=v1, listed-person=v1, judgment-acceptance-rule=v1,
        judgment-conflict=v1,
    },
}

This requirement applies for a tree T whose object store is valid
(`object-store#tree-object-store`) and `persons` unbound or bound.

- When a conforming program gives the findings of the Ledger's check
  "Kind rules" (finding class `unaccepted-statement`,
  `ledger#unaccepted-statement-finding`) for `approval` and `decline`
  statements of T: for each `approval` or `decline` statement E in the
  object store of T for which `judgment-acceptance-rule` does not hold
  in T (and is not withheld under an invalid binding of `persons`), the
  conforming program must give once the finding of that class for E, and
  must give no finding of that class for any `approval` or `decline`
  statement in T for which `judgment-acceptance-rule` holds or is
  withheld.
- When a conforming program gives the findings of the Ledger's check
  "Conflicts" (finding class `statement-conflict`,
  `ledger#statement-conflict-finding`) for `approval` and `decline`
  judgments of T: for each declared-item content id t for which a
  conflict exists in T (`judgment-conflict`, when `persons` is unbound
  or valid, or when the conflict holds under every valid binding of
  `persons` and when `persons` is unbound), the conforming program must
  give once the finding of that class for t, and must give no finding of
  that class for any declared-item content id t for which no conflict
  holds or whether a conflict holds depends on an invalid binding of
  `persons`.

## 6. Conformance

A program conforms to this design when it is a
[conforming program](sinter:conformance#conforming-program=v1) of this design.

The vectors of this design are in the file
[`approval.test-vectors.jsonl`](approval.test-vectors.jsonl), in the
same folder as this design. The file is a test-vector set, as the
specification [`test-vectors`](sinter:data-forms#test-vectors=v1) of
Data forms gives it. A vector is an input and what a conforming program
gives for it. Each vector follows from the requirements and adds nothing
to them. The vectors are in four groups: `acceptance`, `checks`,
`findings`, and `states`. Each group has a subsection below that gives
the forms of that group, as the term
[`group-form-list`](sinter:data-forms#group-form-list=v1) gives the
forms of a group. No vector follows from the operational requirements
`record-judged-content` and `record-seen-judgments`.

Each requirement from which vectors follow applies only when a program
gives the thing that the requirement names, such as whether an
`approval` or `decline` statement is accepted in a tree. So a vector
holds a program only to what the program gives for the input.

### 6.1 Acceptance

@schema acceptance-vector=v1
@cites {
    rfc/8259,
    conformance#{conforming-program=v1},
    text#{text=v1, character=v1, code-point-order=v1, result=v1, code-span=v1},
    data-forms#{
        group-form-list=v1, vector-meaning=v1, json-value=v1,
        vector-line=v1, canonical-byte-sequence=v1,
    },
    ontology#{
        object=v1, object-kind=v1, content-id=v1, statement=v1,
        void-statement=v1, parameter=v1, tree=v1,
    },
    object-store#{tree-object-store=v1},
    #{
        persons=v1, judgment-acceptance-rule=v1,
        give-judgment-acceptance=v1,
    },
}

The group `acceptance` holds the vectors of the requirement
`give-judgment-acceptance`. Each vector gives a set of `approval` and
`decline` statements, an optional set of `void` statements, and an
optional valid binding of `persons`, standing for a tree whose object
store is valid and holds those statements. For each statement in
`judgments`, the vector gives whether `judgment-acceptance-rule` holds
in that tree. The group uses no need, so these forms give no need names.

The input of each vector stands for a tree whose object store is valid
and holds the given statements; when `persons` is present, for that
valid binding of `persons`, and when `persons` is absent, for `persons`
unbound. No other process changes these inputs while the program reads
them.

The JSON values, objects, arrays, strings, numbers, and the literal
names `true` and `false` of this schema are as RFC 8259 defines them.
Inside `input` and `values`, a text is a JSON string whose characters
are the characters of the text, in order, and a sequence is a JSON array
of its elements, in order. Each element of `judgments` and `voids` is
the canonical JSON object of that statement (with no `id` member); its
content id is the `ontology#content-id` computed from its canonical byte
sequence.

- `input`: a JSON object with `judgments`, and optionally `voids` and
  `persons`. `judgments` is a sequence of canonical `approval` and
  `decline` statement objects in `.sinter/` (its order serves only to
  align with `accepted`). `voids`, when present, is a sequence of
  canonical `void` statement objects in `.sinter/`; when absent, the
  store holds no `void` statement. `persons`, when present, is a JSON
  array of distinct JSON strings in code point order giving a valid
  binding of `persons`; when absent, `persons` is unbound.
- `result`: no vector of the group has this member; these forms name no
  question for `result`.
- `values`: a JSON object with one member, `accepted`. `accepted` is a
  JSON array with one element for each element of `judgments`, in the
  same order: `true` when `judgment-acceptance-rule` holds for that
  statement in that tree, and `false` when it does not hold.

When a conforming program gives whether one of these statements is
accepted in that tree, the program gives "accepted" when its element of
`accepted` is `true`, and "not accepted" when its element of `accepted`
is `false`.

```
{"form":"#acceptance-vector=v1","group":"acceptance","input":{"judgments":[{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"req:3fc4ccfe745870e2c0d99f71f30ff065"},{"kind":"judges","to":"req:3fc4ccfe745870e2c0d99f71f30ff065"}],"kind":"approval","v":1},{"by":"Bo Chen <bo@example.com>","edges":[{"kind":"about","to":"req:7692c3ad3540bb803c020b3aee66cd88"},{"kind":"judges","to":"req:7692c3ad3540bb803c020b3aee66cd88"},{"kind":"revises","to":"approval:09dfaa1f3d6939a31d86c31bba0c6049"}],"kind":"approval","v":1}]},"note":"an approval revising a judgment whose `about` edge names another declared-item object is not accepted","values":{"accepted":[true,false]}}
```

### 6.2 Findings

@schema findings-vector=v1
@cites {
    rfc/8259,
    conformance#{conforming-program=v1},
    text#{
        text=v1, character=v1, whole-number=v1, decimal-numeral=v1,
        code-point-order=v1, result=v1, code-span=v1,
    },
    data-forms#{
        index=v1, group-form-list=v1, vector-meaning=v1, json-value=v1,
        vector-line=v1,
    },
    identifiers#{
        external-namespaces=v1, validate-bindings=v1, citation-entry=v1,
        inline-citation=v1,
    },
    ontology#{
        subject-of-approval=v1, declared-item=v1, schema=v1, test=v1,
        site=v1, tree=v1, edge=v1, finding-class=v1, parameter=v1,
    },
    object-store#{tree-object-store=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
    },
    documents#{
        file-readers=v1, tree-edge=v1, origin-position=v1,
        position-subject=v1, edge-finding-subject=v1, tree-finding=v1,
    },
    findings#{finding-subject=v1},
    #{
        approval-kinds=v1, persons=v1, subject-text=v1,
        subject-state=v1, bound-in-force-item=v1, declined-finding=v1,
        awaiting-approval-finding=v1, unapproved-req-finding=v1,
        incomplete-first-parent-line=v1, give-approval-findings=v1,
    },
}

The group `findings` holds the vectors of the requirement
`give-approval-findings`. Each vector gives the subjects of approval of
a tree, their states, and whether their declared items are in force. The
vector gives the edges of the tree. For each edge, when its cited item
is a requirement or a schema with a subject of approval, the vector
gives whether that cited item is in force. The vector gives the findings
of the three classes of the tree, by the subjects of those findings. The
group uses no need, so these forms give no need names.

The input of each vector stands for a tree whose object store is valid;
for a binding of `file-readers` that is valid; for a binding of
`external-namespaces` for which a conforming program of Identifiers
gives the result "valid"; for `persons` unbound or bound to a valid
binding; and for a valid binding of `default-branch-name` (the input
does not depend on that binding) under which, when the default branch
has a commit, its first-parent line is not incomplete. No other process
changes these inputs while the program reads them.

The JSON values, objects, arrays, strings, numbers, and the literal
names `true` and `false` of this schema are as RFC 8259 defines them.
Inside `input` and `values`, a text, such as a subject text, an edge
finding subject, or a position subject, is a JSON string whose characters
are the characters of the text, in order. A sequence is a JSON array of
its elements, in order. A valid binding of `approval-kinds` is a JSON
array of JSON strings holding, for each kind of subject of approval in
the binding, the kind word of that kind, each once, in code point order.

- `input`: a JSON object with three members. `binding` is a valid
  binding of `approval-kinds`. `subjects` is the subjects of approval of
  the tree, as a sequence. Each subject of approval in `subjects` is a
  JSON object with three members: `subject` (subject text), `state` (one
  of `"approved"`, `"declined"`, and `"neither"`), and `in-force`
  (`true` when its declared item is in force under `bound-in-force-item`,
  and `false` otherwise). `edges` is the edges of the tree, as a
  sequence. Each edge in `edges` is a JSON object with `kind` (kind of
  edge), `fits` (`true` when the edge says what its kind of edge says,
  `false` otherwise), and `at` (the subject of the finding for the edge:
  an edge finding subject when its source is a declared item, and a
  position subject when its source is a test or a site), and, when
  its cited item is a requirement or a schema with a subject of
  approval, two more members: `cited` (the 1-based index of that subject
  of approval in `subjects`) and `in-force` (`true` when that cited item
  is in force under `bound-in-force-item`, and `false` otherwise).
- `result`: no vector of the group has this member; these forms name no
  question for `result`.
- `values`: a JSON object with one member, `findings`. `findings` is a
  JSON object with three members: `awaiting-approval`, `declined`, and
  `unapproved-req`. Each is a JSON array of the subjects of the tree
  findings of that class that the tree has, each once, in code point
  order.

When a conforming program gives the findings of one of the three classes
of the tree, the program gives one finding with each subject in the
member of `findings` for that class, and gives no other finding of that
class.

```
{"form":"#findings-vector=v1","group":"findings","input":{"binding":["req"],"edges":[],"subjects":[{"in-force":true,"state":"declined","subject":"req:billing#limit"},{"in-force":true,"state":"declined","subject":"req:billing#limit"},{"in-force":true,"state":"neither","subject":"req:billing#limit"}]},"note":"two declared items with the same kind and name give one finding of a class","values":{"findings":{"awaiting-approval":["req:billing#limit"],"declined":["req:billing#limit"],"unapproved-req":[]}}}
```

### 6.3 States

@schema states-vector=v1
@cites {
    rfc/8259,
    conformance#{conforming-program=v1},
    text#{
        text=v1, character=v1, code-point-order=v1, result=v1,
        code-span=v1,
    },
    data-forms#{
        group-form-list=v1, vector-meaning=v1, json-value=v1,
        hash-form=v1, vector-line=v1,
    },
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ontology#{
        subject-of-approval=v1, content-hash=v1, content-id=v1,
        tree=v1, statement=v1, void-statement=v1, default-branch=v1,
        parameter=v1,
    },
    object-store#{tree-object-store=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
    },
    documents#{file-readers=v1},
    #{
        approval-kinds=v1, persons=v1, subject-text=v1,
        subject-state=v1, incomplete-first-parent-line=v1,
        give-subject-states=v1, acceptance-vector=v1,
        findings-vector=v1,
    },
}

The group `states` holds the vectors of the requirement
`give-subject-states`. Each vector gives one subject of approval of a
tree by its subject text and the content hash of its declared item's
canonical object (so its declared-item object's content id is its kind
word, `:`, and the first 32 characters of `hash`); a valid binding of
`approval-kinds`; the `approval` and `decline` statements (and optional
`void` statements) of `.sinter/`; an optional valid binding of
`persons`; and the trees of the commits of the first-parent line of the
commit of the default branch. The vector gives the state of that subject
of approval in that tree. The group uses no need, so these forms give no
need names.

The input of each vector stands for a tree whose object store is valid;
for a binding of `file-readers` that is valid; for a binding of
`external-namespaces` for which a conforming program of Identifiers
gives the result "valid"; for `persons` as given (or unbound when
absent); and for a valid binding of `default-branch-name`. When the
input has `line`, the default branch has the commit whose complete
first-parent line `line` gives. When the input has no `line`, the
default branch has no commit. No other process changes these inputs
while the program reads them.

The JSON values, objects, arrays, strings, and numbers of this schema
are as RFC 8259 defines them. Inside `input` and `result`, a text is a
JSON string, a sequence is a JSON array, a valid binding of
`approval-kinds` has the form of `findings-vector`, and `judgments`,
`voids`, and `persons` have the forms of `acceptance-vector`.

- `input`: a JSON object with `binding`, `subject`, `hash`, and
  `judgments`, and optionally `voids`, `persons`, and `line`. `binding`
  is a valid binding of `approval-kinds`. `subject` is the subject text
  of the subject of approval. `hash` is a string fitting `hash-form`,
  the content hash (`ontology#content-hash`) of the canonical object of
  the declared item of that subject of approval in the tree. `judgments`
  and optional `voids` and `persons` have the forms of
  `acceptance-vector`. When the default branch has a commit, `line` is
  the sequence of commits of its first-parent line, where each commit is
  a JSON array of JSON objects `{"hash":…,"subject":…}` giving the
  subject text and content hash of each subject of approval in that
  commit's tree. When the default branch has no commit, `line` is
  absent.
- `result`: `"approved"`, `"declined"`, or `"neither"`, matching
  `subject-state`.
- `values`: no vector of the group has this member; these forms give no
  fixed form for `values`.

When a conforming program gives whether the subject of approval is
approved or declined in the tree, the program gives `"approved"`,
`"declined"`, or `"neither"` as `result` states, and gives no other
result.

```
{"form":"#states-vector=v1","group":"states","input":{"binding":["req","spec"],"hash":"7692c3ad3540bb803c020b3aee66cd8887123234ea0c6e7143c0add73ff431ed","judgments":[{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"req:7692c3ad3540bb803c020b3aee66cd88"},{"kind":"judges","to":"req:7692c3ad3540bb803c020b3aee66cd88"}],"kind":"decline","v":1},{"by":"Bo Chen <bo@example.com>","edges":[{"kind":"about","to":"req:7692c3ad3540bb803c020b3aee66cd88"},{"kind":"judges","to":"req:7692c3ad3540bb803c020b3aee66cd88"}],"kind":"approval","v":1}],"subject":"req:billing#limit"},"note":"a decline and an approval with no `revises` edge conflict and give neither","result":"neither"}
```

### 6.4 Statement checks

@schema checks-vector=v1
@cites {
    rfc/8259,
    conformance#{conforming-program=v1},
    text#{text=v1, character=v1, code-point-order=v1, code-span=v1},
    data-forms#{
        group-form-list=v1, vector-meaning=v1, json-value=v1,
        vector-line=v1,
    },
    ontology#{content-id=v1, statement=v1, void-statement=v1, tree=v1},
    object-store#{tree-object-store=v1},
    ledger#{
        unaccepted-statement-finding=v1, statement-conflict-finding=v1,
    },
    #{
        persons=v1, judgment-acceptance-rule=v1, judgment-conflict=v1,
        give-judgment-check-findings=v1, acceptance-vector=v1,
    },
}

The group `checks` holds the vectors of the requirement
`give-judgment-check-findings`. Each vector gives a set of `approval`
and `decline` statements, an optional set of `void` statements, and an
optional valid binding of `persons`, standing for a tree whose object
store is valid and holds those statements. The vector gives the content
ids of unaccepted `approval` and `decline` statements (check "Kind
rules", class `unaccepted-statement`) and of declared-item objects with
conflicting latest counting judgments (check "Conflicts", class
`statement-conflict`). The group uses no need, so these forms give no
need names.

The input of each vector stands for a tree whose object store is valid
and holds the given statements; when `persons` is present, for that
valid binding of `persons`, and when `persons` is absent, for `persons`
unbound. No other process changes these inputs while the program reads
them.

The JSON values, objects, arrays, strings, and numbers of this schema
are as RFC 8259 defines them. `judgments`, `voids`, and `persons` have
the forms of `acceptance-vector`.

- `input`: a JSON object with `judgments`, and optionally `voids` and
  `persons`, in the forms of `acceptance-vector`.
- `result`: no vector of the group has this member; these forms name no
  question for `result`.
- `values`: a JSON object with two members: `unaccepted`, a JSON array
  of the content ids of the `approval` and `decline` statements in
  `judgments` for which `judgment-acceptance-rule` does not hold, each
  once in code point order; and `conflicts`, a JSON array of the
  declared-item content ids for which `judgment-conflict` holds in that
  tree, each once in code point order.

When a conforming program gives the findings of the classes
`unaccepted-statement` (check "Kind rules") and `statement-conflict`
(check "Conflicts") for the `approval` and `decline` statements of that
tree, the program gives one `unaccepted-statement` finding for each
content id in `unaccepted`, one `statement-conflict` finding for each
content id in `conflicts`, and no other finding of those classes for
`approval` and `decline`.

```
{"form":"#checks-vector=v1","group":"checks","input":{"judgments":[{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"req:7692c3ad3540bb803c020b3aee66cd88"},{"kind":"judges","to":"req:7692c3ad3540bb803c020b3aee66cd88"}],"kind":"approval","v":1},{"by":"Bo Chen <bo@example.com>","edges":[{"kind":"about","to":"req:7692c3ad3540bb803c020b3aee66cd88"},{"kind":"judges","to":"req:7692c3ad3540bb803c020b3aee66cd88"}],"kind":"decline","reason":"needs a clearer bound","v":1}]},"note":"an approval and a decline of the same declared-item object give a conflict finding","values":{"conflicts":["req:7692c3ad3540bb803c020b3aee66cd88"],"unaccepted":[]}}
```
