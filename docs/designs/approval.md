<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Approval
@design approval=v1
@cites {
    conformance=v1, text=v1, identifiers=v1, files=v1, data-forms=v1,
    ontology=v1, object-store=v1, changes=v1, findings=v1, documents=v1,
    ledger=v1, rfc/5234, rfc/7405,
}
Conforming programs validate and write person judgments in `.sinter/`,
determine subject approval states from judgments or default-branch
merges, and return findings for declined or unapproved items.

A project chooses which kinds of subject of approval need approval by a
person and which kinds gain approval by merging into the default
branch. An optional parameter names the persons whose judgments and
voids count in the repository.

A person records an approval or decline as a canonical statement in
`.sinter/` tied to one declared-item object and to any earlier
judgments that the statement replaces. Together with default-branch
merge history, those judgments determine whether a subject of approval
is approved or declined, which declared items stay in force, and which
approval findings a program returns.

## Parameters

### Approval kinds

@schema approval-kinds=v1
@cites ontology#{
    subject-of-approval=v1, declared-item=v1, person=v1, parameter=v1,
}

The `parameter` `approval-kinds` names the kinds of
`subject-of-approval` that need approval by a `person`. A binding of
`approval-kinds` meets `approval-kinds` when the binding is a subset of
the seven kinds of `subject-of-approval` (corresponding to the seven
`declared-item` kinds: `design`, `spec`, `schema`, `req`, `atom`,
`term`, and `decision`). The empty set is a valid binding. Otherwise,
the binding is invalid.

Under a valid binding `A` of `approval-kinds`, a `subject-of-approval`
**needs approval** (needs approval by a `person`) when its kind is in
`A`, and needs no approval by a person otherwise.

### Persons

@schema persons=v1
@cites {ontology#{parameter=v1, person=v1}, text#text=v1}

The `parameter` `persons` is optional and supplies a list of `person`s.
A binding of `persons` meets `persons` when the binding is a finite set
of `text`s. The empty set is a valid binding. Otherwise, the binding is
invalid.

## Definitions

### Listed persons

@term listed-person=v1
@cites {
    ontology#{
        parameter=v1, person=v1, judgment=v1, void-statement=v1,
        object-withdrawal=v1, topic=v1,
    },
    data-forms#json-value=v1,
    text#text=v1,
    #persons=v1,
}

The optional `parameter` `persons` names the `person`s whose
`judgment`s (of all four kinds: `"approval"`, `"decline"`, `"done"`,
and `"abandoned"`) and `"void"` statements (`void-statement`) count
under `ontology#topic` and `ontology#object-withdrawal`:

- When `persons` is unbound, every `judgment` and every `"void"`
  statement satisfies `listed-person`.
- When `persons` is bound to a valid binding `L` (`persons`), a
  `judgment` or a `"void"` statement satisfies `listed-person` under
  `L` when the value of its member `by` (`json-value`) is equal as a
  `text` to an element of `L`, and does not satisfy `listed-person`
  otherwise. Under the empty binding of `persons`, no `judgment` and no
  `"void"` statement satisfies `listed-person`.
- When `persons` is bound to a value that does not meet `persons`,
  whether any `judgment` or `"void"` statement that meets the other
  conditions of `ontology#topic` or `ontology#object-withdrawal` counts
  is withheld, and every result whose value depends on whether such a
  `judgment` or `"void"` statement counts is withheld, while every
  result whose value does not depend on whether such a statement counts
  is unaffected.

## Approval and decline judgments

@spec judgments=v1

An `"approval"` or `"decline"` statement in `.sinter/` records a
person's decision on one canonical declared-item object and names any
earlier judgments that the statement replaces with `revises` edges.

### Definitions

#### Judgment acceptance rule

@atom judgment-acceptance-rule=v1
@refines ledger#accepted-record=v1
@cites {
    ontology#{
        object=v1, object-kind=v1, content-id=v1, declared-item=v1,
        statement=v1, void-statement=v1, object-withdrawal=v1,
        edge=v1, tree=v1, parameter=v1,
    },
    object-store#tree-object-store=v1,
    #{persons=v1, listed-person=v1},
}

For a `tree` `T` whose `tree-object-store` is valid, a `statement` `E`
of kind `"approval"` or `"decline"`, and the `parameter` `persons`
(unbound or bound), `judgment-acceptance-rule` holds for `E` in `T`
when both of these conditions hold:

1. `E` meets its row of `ontology#object-kind`, holding one `about`
   `edge` naming a `content-id` of one of the seven `declared-item`
   kinds, one `judges` edge naming that same content ID, and only
   `revises` edges beyond those two, each naming a content ID of kind
   `"approval"` or `"decline"`.
2. For each `revises` edge of `E`, naming a content ID `c`, at least
   one of these conditions holds in `T`:
   - `T` holds a canonical `object` of kind `"approval"` or `"decline"`
     with content ID `c` that meets its row of `ontology#object-kind`
     and whose `about` edge names the same content ID as the `about`
     edge of `E`; or
   - `T` holds a counting void (`object-withdrawal`, under
     `listed-person`) whose `withdraws` edge names `c`, whose member
     `withdrawn-kind` is `"approval"` or `"decline"`, and that holds an
     `about` edge naming the same content ID as the `about` edge of `E`.

Whether `judgment-acceptance-rule` holds for `E` in `T` is withheld
when all three of these conditions hold:

- `E` meets condition 1;
- no `revises` edge of `E` fails condition 2 outright (every `revises`
  edge of `E` either satisfies condition 2 or targets an absent content
  ID `c` covered by the next bullet); and
- for at least one `revises` edge of `E` naming a content ID `c` that
  `T` does not hold as a canonical `"approval"` or `"decline"` object,
  `T` holds a `"void"` statement (`void-statement`) whose `withdraws`
  edge names `c`, whose member `withdrawn-kind` is `"approval"` or
  `"decline"`, whose `about` edge names the same content ID as the
  `about` edge of `E`, and whose counting is withheld under an invalid
  binding of `persons` (`listed-person`).

Whether `judgment-acceptance-rule` holds for `E` in `T` does not depend
on whether `T` holds the declared-item object named by the `about` and
`judges` edges of `E`, and does not forbid an `"approval"` statement
from naming an `"approval"` statement with `revises`.

@example This canonical `"approval"`
[statement](sinter:ontology#statement=v1) meets its row of
[object-kind](sinter:ontology#object-kind=v1), names one
[declared-item](sinter:ontology#declared-item=v1) object by
[content ID](sinter:ontology#content-id=v1) on both `about` and
`judges` [edges](sinter:ontology#edge=v1), and carries no `revises`
edge, so that statement is accepted in a [tree](sinter:ontology#tree=v1)
whose [object store](sinter:object-store#tree-object-store=v1) is valid,
even when that tree does not hold
`req:7692c3ad3540bb803c020b3aee66cd88`:

```json
{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"req:7692c3ad3540bb803c020b3aee66cd88"},{"kind":"judges","to":"req:7692c3ad3540bb803c020b3aee66cd88"}],"kind":"approval","v":1}
```

#### Latest counting judgment

@term latest-judgment=v1
@cites {
    ontology#{
        object=v1, object-kind=v1, content-id=v1, declared-item=v1,
        statement=v1, judgment=v1, void-statement=v1,
        object-withdrawal=v1, topic=v1, edge=v1, tree=v1, parameter=v1,
        agent=v1,
    },
    object-store#tree-object-store=v1,
    #{persons=v1, listed-person=v1, judgment-acceptance-rule=v1},
}

For a `tree` `T` whose `tree-object-store` is valid, a `declared-item`
`object`'s `content-id` `t`, and the `parameter` `persons` unbound or
bound to a valid binding `L`, an `"approval"` or `"decline"` `statement`
`E` in `T` **counts for `t` in `T`** (under `persons`) when all five of
these conditions hold (`ontology#topic`):

1. `judgment-acceptance-rule` holds for `E` in `T`.
2. No counting void (`object-withdrawal`, under `listed-person`) in `T`
   withdraws `E`.
3. `E` carries no member `agent` (`ontology#agent`).
4. `E` satisfies `listed-person` under `persons`.
5. The `about` and `judges` `edge`s of `E` name `t`.

An `"approval"` or `"decline"` statement that does not count for `t` in
`T` replaces nothing, is never a latest counting `judgment` of `t`, and
a `revises` edge naming that statement replaces nothing.

A statement `E` that counts for `t` in `T` is **replaced** in `T`
(under `persons`) when either of these conditions holds:

- another `"approval"` or `"decline"` statement that counts for `t` in
  `T` holds a `revises` edge naming the content ID of `E`; or
- a counting void (`object-withdrawal`, `void-statement`, under
  `listed-person`) in `T` whose `withdrawn-kind` (`object-kind`) is
  `"approval"` or `"decline"` and that holds an `about` edge naming `t`
  also holds a `revises` edge naming the content ID of `E`.

The **latest counting judgments** of `t` in `T` (under `persons`) are
the `"approval"` and `"decline"` statements that count for `t` in `T`
and are not replaced in `T`.

#### Judgment conflict

@atom judgment-conflict=v1
@refines ontology#conflict=v1
@cites {
    ontology#{
        declared-item=v1, content-id=v1, statement=v1, tree=v1,
        parameter=v1,
    },
    object-store#tree-object-store=v1,
    #{persons=v1, latest-judgment=v1},
}

For a `tree` `T` whose `tree-object-store` is valid, a `declared-item`
`content-id` `t`, and the `parameter` `persons` unbound or bound to a
valid binding `L`, let `J` be the set of latest counting judgments of
`t` in `T` under `persons` (`latest-judgment`):

- The latest counting judgments of `t` **agree** in `T` when `J` holds
  two or more elements and either every element of `J` is a `statement`
  of kind `"approval"` or every element of `J` is a `statement` of kind
  `"decline"`.
- A **conflict** exists for `t` in `T` (the latest counting judgments
  of `t` **conflict** in `T`) when `J` holds at least one `statement`
  of kind `"approval"` and at least one `statement` of kind `"decline"`.

@example Five scenarios for one
[declared-item](sinter:ontology#declared-item=v1) object `O` under
[latest-judgment](sinter:#latest-judgment=v1):

1. Two concurrent `"approval"`
   [judgments](sinter:ontology#judgment=v1) of `O` with no `revises`
   [edge](sinter:ontology#edge=v1) are both latest counting judgments
   and agree, so no conflict exists.
2. One `"approval"` judgment `A` of `O` and one `"decline"` judgment
   `D` of `O` with no `revises` edge between them are both latest
   counting judgments and conflict; one new `"approval"` or `"decline"`
   judgment with `revises` edges naming both `A` and `D` settles the
   conflict.
3. Ada writes an `"approval"` judgment of `O`, and Bo writes a second
   `"approval"` judgment of `O` whose `revises` edge names Ada's
   judgment; Bo's judgment is accepted although no conflict exists
   ([judgment-acceptance-rule](sinter:#judgment-acceptance-rule=v1)),
   replaces Ada's judgment, and leaves one latest counting `"approval"`.
4. Ada's `"approval"` `A` replaced Bo's `"decline"` `D`, and Cy writes
   a [counting void](sinter:ontology#object-withdrawal=v1) `V`
   withdrawing `A` (copying `A`'s `about`, `judges`, and `revises`
   edges per [object-kind](sinter:ontology#object-kind=v1)); `A` is
   withdrawn, `D` stays replaced through `V`'s copied `revises` edge,
   and `O` has zero latest counting judgments.
5. An `"approval"` carrying [agent](sinter:ontology#agent=v1), with
   `by` outside a valid binding of [persons](sinter:#persons=v1)
   ([listed-person](sinter:#listed-person=v1)), or failing
   [judgment-acceptance-rule](sinter:#judgment-acceptance-rule=v1) does
   not count and neither replaces nor conflicts with an earlier
   counting `"decline"` of `O`.

### Returning judgment acceptance

@req give-judgment-acceptance=v1
@cites {
    conformance#conforming-program=v1,
    ledger#accepted-record=v1,
    ontology#{statement=v1, tree=v1, parameter=v1},
    object-store#tree-object-store=v1,
    #{persons=v1, judgment-acceptance-rule=v1},
}

For a `tree` `T` whose `tree-object-store` is valid, the `parameter`
`persons` (unbound or bound), and a `statement` `E` of kind
`"approval"` or `"decline"`, when a conforming program returns whether
`E` is accepted in `T` (`accepted-record`):

- When `judgment-acceptance-rule` holds for `E` in `T` (and is not
  withheld under an invalid binding of `persons`), the program must
  return `"accepted"` and no other acceptance result for `E`.
- When `judgment-acceptance-rule` does not hold for `E` in `T` (and is
  not withheld under an invalid binding of `persons`), the program must
  return `"not accepted"` and no other acceptance result for `E`.
- When whether `judgment-acceptance-rule` holds for `E` in `T` is
  withheld under an invalid binding of `persons`, the program must
  return neither `"accepted"` nor `"not accepted"` for `E`.

### Writing approval and decline judgments

@req write-judgments=v1
@cites {
    conformance#conforming-program=v1,
    ontology#{
        object=v1, object-kind=v1, content-id=v1, statement=v1,
        judgment=v1, void-statement=v1, object-withdrawal=v1,
        person=v1, agent=v1, subject-of-approval=v1, declared-item=v1,
        revised-content=v1, tree=v1, edge=v1, parameter=v1,
        write-judgments-only-for-persons=v1,
    },
    object-store#{tree-object-store=v1, write-object-files=v1},
    #{persons=v1, judgment-acceptance-rule=v1, latest-judgment=v1},
}

For a working `tree` `T` whose `tree-object-store` is valid, the
`parameter` `persons` unbound or bound to a valid binding `L`, and a
`subject-of-approval` `S` of `T` whose `declared-item` has canonical
`object` `content-id` `t`, when a conforming program writes in
`.sinter/` of `T` a `statement` `E` of kind `"approval"` or `"decline"`
to record a decision of a `person` on the `revised-content` of `S` in
`T`, all of these rules apply:

- The program must write `E` only to record a decision that the
  `person` confirmed under `write-judgments-only-for-persons`.
- `E` must meet its row of `ontology#object-kind`, with `kind` equal to
  `"approval"` when the person approved that revised content and
  `"decline"` when the person declined that revised content.
- The one `about` `edge` and the one `judges` `edge` of `E` must both
  have `to` equal to `t`.
- `E` must carry no member `agent` (`ontology#agent`).
- `judgment-acceptance-rule` must hold for `E` in `T` under `persons`.
- Each `revises` `edge` of `E` must name a latest counting `judgment`
  of `t` in `T` under `persons` (`latest-judgment`).
- Before the `person` whose decision `E` records confirms that
  decision, the program must show that person each exact `"approval"`
  or `"decline"` judgment that a `revises` edge of `E` names.
- When `t` has no latest counting judgment in `T` under `persons`
  (including when a counting void (`object-withdrawal`,
  `void-statement`) in `T` withdrew the only latest counting judgment
  of `t`), `E` must hold no `revises` edge, and the program must show
  that person no `"approval"` or `"decline"` judgment in place of a
  withdrawn judgment.
- The program must write `E` as a store object file in `.sinter/` of
  `T` under `write-object-files`.

### Returning judgment check findings

@req give-judgment-check-findings=v1
@cites {
    conformance#conforming-program=v1,
    ontology#{
        finding-class=v1, statement=v1, judgment=v1, declared-item=v1,
        content-id=v1, tree=v1, parameter=v1,
    },
    object-store#tree-object-store=v1,
    ledger#{
        unaccepted-statement-finding=v1,
        statement-conflict-finding=v1,
    },
    #{
        persons=v1, listed-person=v1, judgment-acceptance-rule=v1,
        judgment-conflict=v1,
    },
}

For a `tree` `T` whose `tree-object-store` is valid and the `parameter`
`persons` (unbound or bound):

- When a conforming program returns findings of the `finding-class`
  `unaccepted-statement` (`unaccepted-statement-finding`) for
  `"approval"` and `"decline"` statements of `T`: for each `"approval"`
  or `"decline"` `statement` `E` in the object store of `T` for which
  `judgment-acceptance-rule` does not hold in `T` (and is not withheld
  under an invalid binding of `persons`), the program must return once
  the `unaccepted-statement-finding` for `E`, and must return no
  `unaccepted-statement-finding` for any `"approval"` or `"decline"`
  statement in `T` for which `judgment-acceptance-rule` holds or is
  withheld.
- When a conforming program returns findings of the `finding-class`
  `statement-conflict` (`statement-conflict-finding`) for `"approval"`
  and `"decline"` `judgment`s of `T`: when `persons` is unbound or
  bound to a valid binding `L`, for each `declared-item` `content-id`
  `t` for which `judgment-conflict` holds in `T`, the program must
  return once the `statement-conflict-finding` for `t`, and must return
  no `statement-conflict-finding` for any `declared-item` `content-id`
  `t` for which `judgment-conflict` does not hold in `T`. When
  `persons` is bound to an invalid binding, the program must return no
  `statement-conflict-finding` for `"approval"` and `"decline"`
  judgments of `T` (`listed-person`).

### Test vectors

Test vectors for `judgments` live in
[approval.test-vectors.jsonl](approval.test-vectors.jsonl) as a
test-vector set under [test-vectors](sinter:data-forms#test-vectors=v1).
Neither group uses `needs`, and neither group uses `result`.

#### Acceptance vectors

@schema acceptance-vector=v1
@cites {
    conformance#conforming-program=v1,
    text#{text=v1, code-point-order=v1},
    data-forms#{
        group-schema=v1, vector-meaning=v1, line-object=v1,
        vector-line=v1, canonical-byte-sequence=v1,
    },
    ontology#{
        object=v1, content-id=v1, statement=v1, void-statement=v1,
        parameter=v1, tree=v1,
    },
    object-store#tree-object-store=v1,
    #{
        persons=v1, judgment-acceptance-rule=v1,
        give-judgment-acceptance=v1,
    },
}

`acceptance-vector` is a `group-schema` for group `acceptance` and
tests `give-judgment-acceptance`. Each line is a `vector-line` whose
meaning follows `vector-meaning`. Each vector represents a `tree` whose
`tree-object-store` is valid and holds the listed statements, together
with the optional `parameter` `persons`.

| field | type | meaning |
|---|---|---|
| `input.judgments` | array of objects | canonical `"approval"` and `"decline"` `statement` objects (`line-object` with no `id` member; each `object`'s `content-id` comes from its `canonical-byte-sequence`), in an order that aligns with `values.accepted` |
| `input.voids` | array of objects (optional) | canonical `"void"` `statement` objects (`void-statement`, `line-object` with no `id` member); absent when the store holds no `"void"` statement |
| `input.persons` | array of strings (optional) | distinct `text` strings in `code-point-order` forming a valid binding of `persons`; absent when `persons` is unbound |
| `values.accepted` | array of booleans | one boolean per element of `input.judgments` in the same order: `true` when `judgment-acceptance-rule` holds in that tree, `false` otherwise |

The objects `input` and `values` hold only the members listed in this
table. When a `conforming-program` returns whether an element of
`input.judgments` is accepted in that tree under
`give-judgment-acceptance`, the program returns `"accepted"` when the
matching element of `values.accepted` is `true`, and `"not accepted"`
when that element is `false`.

@example Sample lines testing
[give-judgment-acceptance](sinter:#give-judgment-acceptance=v1) and
[judgment-acceptance-rule](sinter:#judgment-acceptance-rule=v1) on an
accepted `"approval"` and on an unaccepted `"approval"` whose `revises`
[edge](sinter:ontology#edge=v1) targets another
[declared-item](sinter:ontology#declared-item=v1) object
([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#acceptance-vector=v1","group":"acceptance","input":{"judgments":[{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"req:7692c3ad3540bb803c020b3aee66cd88"},{"kind":"judges","to":"req:7692c3ad3540bb803c020b3aee66cd88"}],"kind":"approval","v":1}]},"note":"a first approval with no `revises` edge is accepted","values":{"accepted":[true]}}
{"form":"#acceptance-vector=v1","group":"acceptance","input":{"judgments":[{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"req:3fc4ccfe745870e2c0d99f71f30ff065"},{"kind":"judges","to":"req:3fc4ccfe745870e2c0d99f71f30ff065"}],"kind":"approval","v":1},{"by":"Bo Chen <bo@example.com>","edges":[{"kind":"about","to":"req:7692c3ad3540bb803c020b3aee66cd88"},{"kind":"judges","to":"req:7692c3ad3540bb803c020b3aee66cd88"},{"kind":"revises","to":"approval:09dfaa1f3d6939a31d86c31bba0c6049"}],"kind":"approval","v":1}]},"note":"an approval revising a judgment whose `about` edge names another declared-item object is not accepted","values":{"accepted":[true,false]}}
```

#### Statement-check vectors

@schema checks-vector=v1
@cites {
    conformance#conforming-program=v1,
    text#{text=v1, code-point-order=v1},
    data-forms#{
        group-schema=v1, vector-meaning=v1, line-object=v1,
        vector-line=v1, canonical-byte-sequence=v1,
    },
    ontology#{
        object=v1, content-id=v1, declared-item=v1, statement=v1,
        void-statement=v1, parameter=v1, tree=v1,
    },
    object-store#tree-object-store=v1,
    ledger#{
        unaccepted-statement-finding=v1,
        statement-conflict-finding=v1,
    },
    #{
        persons=v1, judgment-acceptance-rule=v1, judgment-conflict=v1,
        give-judgment-check-findings=v1,
    },
}

`checks-vector` is a `group-schema` for group `checks` and tests
`give-judgment-check-findings`. Each line is a `vector-line` whose
meaning follows `vector-meaning`. Each vector represents a `tree` whose
`tree-object-store` is valid and holds the listed statements, together
with the optional `parameter` `persons`.

| field | type | meaning |
|---|---|---|
| `input.judgments` | array of objects | canonical `"approval"` and `"decline"` `statement` objects (`line-object` with no `id` member; each `object`'s `content-id` comes from its `canonical-byte-sequence`) |
| `input.voids` | array of objects (optional) | canonical `"void"` `statement` objects (`void-statement`, `line-object` with no `id` member); absent when the store holds no `"void"` statement |
| `input.persons` | array of strings (optional) | distinct `text` strings in `code-point-order` forming a valid binding of `persons`; absent when `persons` is unbound |
| `values.unaccepted` | array of strings | `content-id` values of the `"approval"` and `"decline"` statements in `input.judgments` for which `judgment-acceptance-rule` does not hold in that tree, each once in `code-point-order` |
| `values.conflicts` | array of strings | `declared-item` `content-id` values for which `judgment-conflict` holds in that tree, each once in `code-point-order` |

The objects `input` and `values` hold only the members listed in this
table. When a `conforming-program` returns
`unaccepted-statement-finding` or `statement-conflict-finding` findings
for `"approval"` and `"decline"` statements of that tree under
`give-judgment-check-findings`, the program returns one
`unaccepted-statement-finding` for each `content-id` in
`values.unaccepted`, one `statement-conflict-finding` for each
`content-id` in `values.conflicts`, and no other finding of those
classes for `"approval"` and `"decline"` statements.

@example Sample lines testing
[give-judgment-check-findings](sinter:#give-judgment-check-findings=v1)
for [judgment-conflict](sinter:#judgment-conflict=v1)
([statement-conflict](sinter:ledger#statement-conflict-finding=v1)) and
for
[unaccepted-statement](sinter:ledger#unaccepted-statement-finding=v1)
under [judgment-acceptance-rule](sinter:#judgment-acceptance-rule=v1)
([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#checks-vector=v1","group":"checks","input":{"judgments":[{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"req:7692c3ad3540bb803c020b3aee66cd88"},{"kind":"judges","to":"req:7692c3ad3540bb803c020b3aee66cd88"}],"kind":"approval","v":1},{"by":"Bo Chen <bo@example.com>","edges":[{"kind":"about","to":"req:7692c3ad3540bb803c020b3aee66cd88"},{"kind":"judges","to":"req:7692c3ad3540bb803c020b3aee66cd88"}],"kind":"decline","reason":"needs a clearer bound","v":1}]},"note":"an approval and a decline of the same declared-item object give a conflict finding","values":{"conflicts":["req:7692c3ad3540bb803c020b3aee66cd88"],"unaccepted":[]}}
{"form":"#checks-vector=v1","group":"checks","input":{"judgments":[{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"req:3fc4ccfe745870e2c0d99f71f30ff065"},{"kind":"judges","to":"req:3fc4ccfe745870e2c0d99f71f30ff065"}],"kind":"approval","v":1},{"by":"Bo Chen <bo@example.com>","edges":[{"kind":"about","to":"req:7692c3ad3540bb803c020b3aee66cd88"},{"kind":"judges","to":"req:7692c3ad3540bb803c020b3aee66cd88"},{"kind":"revises","to":"approval:09dfaa1f3d6939a31d86c31bba0c6049"}],"kind":"approval","v":1},{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"req:7692c3ad3540bb803c020b3aee66cd88"},{"kind":"judges","to":"req:7692c3ad3540bb803c020b3aee66cd88"},{"kind":"revises","to":"approval:00000000000000000000000000000000"}],"kind":"approval","v":1}]},"note":"each unaccepted approval or decline gives an unaccepted-statement finding by its content id","values":{"conflicts":[],"unaccepted":["approval:6798359519a793343925504ffa036d0c","approval:7ff01153e5d4dc943d42e371068fea54"]}}
```

## Approval states

@spec states=v1

Each subject of approval in a repository tree takes one of three
states: approved, declined, or neither. The judgments of persons, or
the merge history of the default branch, decide the state of a subject
of approval. That state decides whether a `supersedes` edge takes
effect and which declared items stay in force.

### Definitions

#### Subject text

@term subject-text=v1
@cites {
    rfc/5234,
    rfc/7405,
    identifiers#{slug=v1, full-name=v1, kind-word=v1},
    ontology#{
        subject-of-approval=v1, declared-item=v1, item-name=v1,
        containment=v1,
    },
    text#{text=v1, production=v1},
}

A **subject text** is a `text` that matches the `production`
`subject-text` (written in ABNF per RFC 5234 with the case-sensitive
strings of RFC 7405):

```abnf
subject-text  = ( %s"design" / %s"decision" ) ":" slug
              / ( %s"spec" / %s"schema" / %s"req" / %s"atom"
                  / %s"term" ) ":" ( slug / full-name )
```

Each of the seven `kind-word`s maps to one kind of
`subject-of-approval` (its **kind word**):

| kind word | kind of subject of approval |
|---|---|
| `design` | an item of the kind design, without the declared items that it holds (`containment`) |
| `spec` | an item of the kind specification, with the schemas, items of the kind requirement, atoms, and terms that it holds |
| `schema` | a schema that an item of the kind design holds directly |
| `req` | an item of the kind requirement that an item of the kind design holds directly |
| `atom` | an atom that an item of the kind design holds directly |
| `term` | a term that an item of the kind design holds directly |
| `decision` | a decision record |

The **subject text** of a `subject-of-approval` is the kind word of its
kind of subject of approval, followed by `:`, followed by the
`item-name` of its `declared-item`.

#### Merged content

@term merged-content=v1
@cites {
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
    },
    documents#file-readers=v1,
    identifiers#external-namespaces=v1,
    object-store#tree-object-store=v1,
    ontology#{
        subject-of-approval=v1, declared-item=v1, same-item=v1,
        revised-content=v1, object=v1, content-hash=v1,
        default-branch=v1, tree=v1, parameter=v1, encoding=v1,
    },
}

For a git repository `R`, a `tree` `T` whose object store is valid
(`tree-object-store`), and valid bindings of the `parameter`s
`default-branch-name` (`D`), `file-readers` (`F`), and
`external-namespaces` (`N`), let `S` be a `subject-of-approval` of `T`
(from the text `encoding` under `F` and `N`, or from the valid object
store of `T`). The `revised-content` of `S` in `T` **merged** into the
`default-branch` of `R` under `D`, `F`, and `N` when both of these
conditions hold:

1. The default branch of `R` has a `commit` `H` under `D`
   (`default-branch-commit`).
2. Some commit `C` of the `first-parent-line` of `H` has a tree
   (`commit-file`) whose object store is valid and that holds, in
   either encoding under `F` and `N`, a subject of approval `S2` that
   is the same subject of approval as `S` (`same-item`) and whose
   `declared-item`'s canonical `object` in the tree of `C` has the same
   `content-hash` as the canonical object of the declared item of `S`
   in `T`.

Otherwise, the revised content of `S` in `T` did not merge into the
default branch of `R` under `D`, `F`, and `N`.

#### Subject state

@atom subject-state=v1
@refines ontology#approval-state=v1
@cites {
    changes#default-branch-name=v1,
    documents#file-readers=v1,
    identifiers#external-namespaces=v1,
    object-store#tree-object-store=v1,
    ontology#{
        subject-of-approval=v1, declared-item=v1, content-id=v1,
        revised-content=v1, default-branch=v1, tree=v1, parameter=v1,
        encoding=v1,
    },
    #{
        approval-kinds=v1, persons=v1, latest-judgment=v1,
        judgment-conflict=v1, merged-content=v1,
    },
}

For a git repository `R`, a `tree` `T` whose object store is valid
(`tree-object-store`), valid bindings of the `parameter`s
`approval-kinds` (`A`), `file-readers` (`F`), and `external-namespaces`
(`N`), `persons` unbound or bound to a valid binding `L`, and—for a
subject of approval that does not need approval under `A`—a valid
binding `D` of `default-branch-name`, each `subject-of-approval` `S` of
`T` (in either `encoding`, with declared-item canonical object
`content-id` `t`) has exactly one of the three states `"approved"`,
`"declined"`, and `"neither"`:

- When `S` needs approval under `A` (`approval-kinds`), let `J` be the
  set of latest counting judgments of `t` in `T` under `persons`
  (`latest-judgment`):
  - `S` is `"approved"` when `J` is not empty and every element of `J`
    has kind `"approval"`.
  - `S` is `"declined"` when `J` is not empty and every element of `J`
    has kind `"decline"`.
  - `S` is `"neither"` when `J` is empty or `judgment-conflict` holds
    for `t` in `T`.
- When `S` does not need approval under `A`:
  - `S` is `"approved"` when the `revised-content` of `S` in `T` merged
    into the `default-branch` of `R` under `D`, `F`, and `N`
    (`merged-content`).
  - `S` is `"neither"` when the revised content of `S` in `T` did not
    merge into the default branch of `R` under `D`, `F`, and `N`.
  - `S` is never `"declined"`.

The states `"approved"`, `"declined"`, and `"neither"` are the states
approved, declined, and neither of `S` in `T` under
`ontology#approval-state`.

@example Editing a trailing `@example` block on a text-encoded
[declared item](sinter:ontology#declared-item=v1) `billing#limit` leaves
its [hashed lines](sinter:documents#hashed-line=v1), its canonical
[object](sinter:documents#canonical-object=v1), and its
[content hash](sinter:ontology#content-hash=v1) unchanged. Because an
`"approval"` judgment targets that canonical object by
[content ID](sinter:ontology#content-id=v1)
([latest-judgment](sinter:#latest-judgment=v1)) and
[merged-content](sinter:#merged-content=v1) compares content hashes,
`billing#limit` keeps its `"approved"` state without re-approval.

#### Merge-dependent edge

@term merge-dependent-edge=v1
@cites {
    documents#file-readers=v1,
    identifiers#external-namespaces=v1,
    object-store#tree-object-store=v1,
    ontology#{
        edge=v1, supersedes-edge=v1, declared-item=v1,
        subject-of-approval=v1, containment=v1, tree=v1, parameter=v1,
        encoding=v1,
    },
    #approval-kinds=v1,
}

For a `tree` `T` whose object store is valid (`tree-object-store`) and
valid bindings of the `parameter`s `approval-kinds` (`A`),
`file-readers` (`F`), and `external-namespaces` (`N`), a `supersedes`
`edge` (`supersedes-edge`) of `T` (in either `encoding`, with
`containment`) is **merge-dependent** under `A` when one or both of
these conditions hold:

1. The source of the edge has a `subject-of-approval`, and that subject
   of approval does not need approval under `A`.
2. The source of the edge is an item of the kind design, and at least
   one of these subjects of approval does not need approval under `A`:
   the subject of approval of an item of the kind specification that
   the source holds, or the subject of approval of a schema, an item of
   the kind requirement, an atom, or a term that the source holds
   directly.

Otherwise, the `supersedes` edge is not merge-dependent under `A`.

#### In-force item

@term in-force-item=v1
@cites {
    changes#default-branch-name=v1,
    documents#file-readers=v1,
    identifiers#{external-namespaces=v1, status-tag=v1},
    object-store#tree-object-store=v1,
    ontology#{
        declared-item=v1, containment=v1, deprecated-item=v1,
        retired-item=v1, effective-supersedes-edge=v1,
        supersedes-edge=v1, approval-state=v1, edge=v1, tree=v1,
        parameter=v1, encoding=v1,
    },
    #{
        approval-kinds=v1, persons=v1, subject-state=v1,
        merge-dependent-edge=v1,
    },
}

For a git repository `R`, a `tree` `T` whose object store is valid
(`tree-object-store`), valid bindings of the `parameter`s
`approval-kinds` (`A`), `file-readers` (`F`), and `external-namespaces`
(`N`), `persons` unbound or bound to a valid binding `L`, and—when `T`
holds a `merge-dependent-edge` under `A`—a valid binding `D` of
`default-branch-name`, a `declared-item` of `T` (from either `encoding`)
is **in force under the bindings** in `T` when that declared item is in
force in `T` under `ontology#retired-item`, evaluated with:

- the `approval-state` of the source of each `supersedes-edge` (read by
  `effective-supersedes-edge`) taken from `subject-state` for `R` and
  `T` under these bindings; and
- every declared item, `status-tag` (in text under `F` and `N`, and in
  `.sinter/` from canonical member `status` per `deprecated-item`),
  `containment` relation, and `edge` taken from both encodings of `T`.

Otherwise, that declared item is retired under the bindings in `T`.

#### Incomplete first-parent line

@term incomplete-first-parent-line=v1
@cites {
    changes#{
        commit=v1, commit-file=v1, shallow-commit=v1,
        default-branch-name=v1, default-branch-commit=v1,
        first-parent-line=v1, repository-read=v1,
    },
    documents#{file-readers=v1, read-file=v1},
    identifiers#external-namespaces=v1,
    object-store#{store-file=v1, tree-object-store=v1},
    ontology#{
        default-branch=v1, tree=v1, parameter=v1,
        subject-of-approval=v1, declared-item=v1, same-item=v1,
        revised-content=v1, object=v1, content-hash=v1, content-id=v1,
        approval-state=v1, encoding=v1,
    },
    #{approval-kinds=v1, persons=v1, latest-judgment=v1},
}

For a git repository `R`, a valid binding `D` of the `parameter`
`default-branch-name` under which the `default-branch` of `R` has a
`commit` `H` (`default-branch-commit`), a valid binding `F` of
`file-readers`, and the `repository-read`s from which a program reads
the `first-parent-line` of `H` and the files of the trees of its
commits (`commit-file`), `R` **holds** a git object when `R` holds that
git object at the end of those repository reads.

A commit `C` of the `first-parent-line` of `H` is **complete** in `R`
under `F` for those repository reads when `R` holds all four of these:

1. the git tree object of `C`;
2. every git tree object that a tree entry of the git tree object of
   `C` names (`commit-file`);
3. every blob that a regular-file entry of the git tree object of `C`
   names when that entry yields a `read-file` of the tree of `C` under
   `F`; and
4. every blob that a regular-file entry of the git tree object of `C`
   names when that entry yields a `store-file` of the tree of `C` (in
   `.sinter/` and outside `.sinter/local/`).

The `first-parent-line` of `H` under `F` is **incomplete** for those
repository reads when one or more of these three conditions hold:

1. Some commit of the first-parent line of `H` is a `shallow-commit` of
   `R`.
2. Some commit `C` of the first-parent line of `H` is not a
   `shallow-commit` of `R`, and the commit object of `C` names as its
   first parent a git object that is not a `commit` of `R`.
3. Some commit `C` of the first-parent line of `H` is not complete in
   `R` under `F` for those repository reads.

Under a valid binding `N` of `external-namespaces`, when the
first-parent line of `H` under `F` is incomplete for those repository
reads, the `revised-content` of a `subject-of-approval` `S` of a `tree`
`T` **visibly merged** in `R` under `D`, `F`, and `N` for those
repository reads when some commit `C` of the first-parent line of `H`
that is complete in `R` under `F` for those repository reads has a tree
whose object store is valid (`tree-object-store`) and that holds, in
either `encoding` under `F` and `N`, a subject of approval `S2` that is
the same subject of approval as `S` (`same-item`) and whose
`declared-item`'s canonical `object` in the tree of `C` has the same
`content-hash` as the canonical object of the declared item of `S` in
`T`.

Under valid bindings `A` of `approval-kinds`, `D`, `F`, and `N`, and
`persons` unbound or bound to a valid binding `L`, for a `tree` `T`
whose object store is valid, when the first-parent line of `H` under
`F` is incomplete for those repository reads, the **least merge**
defines whether each subject of approval `S` of `T` (with declared-item
canonical object `content-id` `t`) is approved (`approval-state`):

- When `S` needs approval under `A`, `S` is approved when the set of
  latest counting judgments of `t` in `T` under `persons`
  (`latest-judgment`) is not empty and every element of that set has
  kind `"approval"`, and is not approved otherwise.
- When `S` does not need approval under `A`, `S` is approved when the
  revised content of `S` in `T` visibly merged in `R` under `D`, `F`,
  and `N` for those repository reads, and is not approved otherwise.

Under `A`, `F`, `N`, and `persons` (needing no binding of
`default-branch-name`), for a `tree` `T` whose object store is valid,
the **greatest merge** defines whether each subject of approval `S` of
`T` (with declared-item canonical object `content-id` `t`) is approved
(`approval-state`):

- When `S` needs approval under `A`, `S` is approved when the set of
  latest counting judgments of `t` in `T` under `persons`
  (`latest-judgment`) is not empty and every element of that set has
  kind `"approval"`, and is not approved otherwise.
- When `S` does not need approval under `A`, `S` is approved.

### Returning subject states

@req give-subject-states=v1
@cites {
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
        repository-read=v1,
    },
    conformance#{conforming-program=v1, dependence=v1},
    documents#file-readers=v1,
    identifiers#external-namespaces=v1,
    object-store#tree-object-store=v1,
    ontology#{
        subject-of-approval=v1, revised-content=v1, default-branch=v1,
        tree=v1, parameter=v1,
    },
    #{
        approval-kinds=v1, persons=v1, listed-person=v1,
        subject-state=v1, incomplete-first-parent-line=v1,
    },
}

For a git repository `R`, a `tree` `T` whose object store is valid
(`tree-object-store`), valid bindings of the `parameter`s
`approval-kinds` (`A`), `file-readers` (`F`), and `external-namespaces`
(`N`), `persons` unbound or bound, and a `subject-of-approval` `S` of
`T`, when a `conforming-program` returns whether `S` is approved or
declined in `T`, these rules apply:

- When `S` needs approval under `A` (`approval-kinds`) and `persons` is
  unbound or bound to a valid binding, the program must return exactly
  one result—`"approved"`, `"declined"`, or `"neither"`—matching
  `subject-state` for `S` in `T`, and must not return that the program
  cannot see the whole history for `S`.
- When `S` needs approval under `A` and `persons` is bound to an
  invalid value (one that does not meet `persons`):
  - if every valid binding of `persons` and unbound `persons` yield the
    same `subject-state` for `S` in `T`, the program must return that
    single result and must not return that the program cannot see the
    whole history for `S`;
  - otherwise, the state of `S` depends on `persons` (`dependence`,
    `listed-person`), and the program must return no state
    (`"approved"`, `"declined"`, or `"neither"`) for `S`.
- When `S` does not need approval under `A`, under a valid binding `D`
  of `default-branch-name` (regardless of whether `persons` is unbound,
  valid, or invalid), for the `repository-read`s from which the program
  reads the `first-parent-line` of the `default-branch-commit` and the
  files of the trees of its commits (`commit-file`):
  - when the `default-branch` of `R` has no `commit` under `D`, or has
    a commit `H` under `D` whose first-parent line under `F` is not
    incomplete (`incomplete-first-parent-line`) for those repository
    reads, the program must return exactly one result—`"approved"` or
    `"neither"`—matching `subject-state` for `S` in `T`, and must not
    return that the program cannot see the whole history for `S`;
  - when the default branch of `R` has a commit `H` under `D`, its
    first-parent line under `F` is incomplete for those repository
    reads, and the `revised-content` of `S` in `T` visibly merged
    (`incomplete-first-parent-line`) in `R` under `D`, `F`, and `N` for
    those repository reads, the program must return exactly one result,
    `"approved"`, and must not return that the program cannot see the
    whole history for `S`;
  - when the default branch of `R` has a commit `H` under `D`, its
    first-parent line under `F` is incomplete for those repository
    reads, and the revised content of `S` in `T` did not visibly merge
    in `R` under `D`, `F`, and `N` for those repository reads, the
    program must return no state (`"approved"`, `"declined"`, or
    `"neither"`) for `S` and must return that the program cannot see
    the whole history for `S`.

### Test vectors

@schema states-vector=v1
@cites {
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
    },
    conformance#conforming-program=v1,
    data-forms#{
        line-object=v1, canonical-byte-sequence=v1, hash-form=v1,
        vector-line=v1, test-vector-set=v1, group-schema=v1,
        vector-meaning=v1,
    },
    documents#file-readers=v1,
    identifiers#external-namespaces=v1,
    object-store#tree-object-store=v1,
    ontology#{
        subject-of-approval=v1, declared-item=v1, object-kind=v1,
        content-hash=v1, content-id=v1, tree=v1, statement=v1,
        void-statement=v1, default-branch=v1, parameter=v1,
    },
    text#{text=v1, code-point-order=v1},
    #{
        approval-kinds=v1, persons=v1, subject-text=v1,
        subject-state=v1, incomplete-first-parent-line=v1,
        give-subject-states=v1,
    },
}

`states-vector` is a `group-schema` for group `states` in
[approval.test-vectors.jsonl](approval.test-vectors.jsonl) and tests
`give-subject-states`. That file is a `test-vector-set` of
`vector-line` entries whose meaning follows `vector-meaning`. Group
`states` uses no `needs` and omits `values`.

| field | type | meaning |
|---|---|---|
| `input.binding` | array of strings | valid binding of `approval-kinds`, holding the kind word (`subject-text`) of each kind of subject of approval in the binding, each once, in `code-point-order` |
| `input.subject` | string | `subject-text` of the queried `subject-of-approval` `S` of `tree` `T` |
| `input.hash` | string | `text` matching `hash-form`: the `content-hash` of the canonical object of the `declared-item` of `S` in `T` (so its `content-id` is the kind word of `S`, `:`, and the first 32 characters of `input.hash`) |
| `input.judgments` | array of objects | canonical `"approval"` and `"decline"` `statement` objects (`line-object`s meeting their rows of `object-kind`, with no `id` member) in the valid object store of `T`; each object's `content-id` derives from its `canonical-byte-sequence` |
| `input.voids` | array of objects (optional) | canonical `"void"` `void-statement` objects (`line-object`s meeting their row of `object-kind`, with no `id` member) in the valid object store of `T`; when absent, the object store holds no `"void"` statement |
| `input.persons` | array of strings (optional) | distinct strings in `code-point-order` representing a valid binding of `persons`; when absent, `persons` is unbound |
| `input.line` | array of arrays of objects (optional) | when present, the `default-branch` has a `default-branch-commit` whose complete `first-parent-line` (`incomplete-first-parent-line` does not hold) appears in sequence from head commit to root commit; each inner array lists the subjects of approval of that commit's tree (`commit-file`, with valid object store); when absent, the default branch has no `commit` |
| `input.line[][].subject` | string | `subject-text` of a subject of approval in that commit's tree |
| `input.line[][].hash` | string | `text` matching `hash-form`: the `content-hash` of that subject of approval's declared-item canonical object in that commit's tree |
| `result` | string | `"approved"`, `"declined"`, or `"neither"`, matching `subject-state` |

The object `input` and each object of `input.line[][]` hold only the
members listed in this table. Each vector stands for a tree `T` whose
object store is valid (`tree-object-store`), valid bindings of the
`parameter`s `file-readers`, `external-namespaces`, and
`default-branch-name`, `approval-kinds` bound to `input.binding`, and
`persons` bound to `input.persons` (or unbound when absent), with no
other process changing those inputs while the program reads them.

When a `conforming-program` returns whether `S` is approved or declined
in `T` under `give-subject-states`, the program returns the string
value of `result` and no other result.

@example Sample lines testing
[give-subject-states](sinter:#give-subject-states=v1) for a subject of
approval with no judgment under
[subject-state](sinter:#subject-state=v1) and for merge approval under
the empty binding of [approval-kinds](sinter:#approval-kinds=v1)
([merged-content](sinter:#merged-content=v1),
[vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#states-vector=v1","group":"states","input":{"binding":["req","spec"],"hash":"7692c3ad3540bb803c020b3aee66cd8887123234ea0c6e7143c0add73ff431ed","judgments":[],"subject":"req:billing#limit"},"note":"no judgment","result":"neither"}
{"form":"#states-vector=v1","group":"states","input":{"binding":[],"hash":"8b5b9db0c13db24256c829aa364aa90c6d2eba318b9232a4ab9313b954d3555f","judgments":[],"line":[[{"hash":"8b5b9db0c13db24256c829aa364aa90c6d2eba318b9232a4ab9313b954d3555f","subject":"decision:ledger-ref"}]],"subject":"decision:ledger-ref"},"note":"under the empty binding, each subject is approved by the merge","result":"approved"}
```

## Approval findings

@spec findings=v1

Approval findings tell a team which subjects of approval and which
claims of code still wait on a person's approval or carry a decline.

### Definitions

#### Subject order

@term subject-order=v1
@cites {
    conformance#own-store=v1,
    files#path=v1,
    text#code-point-order=v1,
    identifiers#tag-line-text=v1,
    ontology#{
        subject-of-approval=v1, declared-item=v1, object=v1,
        content-id=v1, tree=v1,
    },
    object-store#valid-object-file=v1,
    findings#location=v1,
    documents#{
        item-file=v1, origin=v1, origin-position=v1, position-order=v1,
        slice-location=v1,
    },
    #subject-text=v1,
}

One `subject-of-approval` `S1` of a `tree` `T` comes before another
`subject-of-approval` `S2` of `T` in the **subject order** when, and
only when, one of these four conditions holds:

1. The `content-id` of the canonical `object` of the `declared-item` of
   `S1` comes before the `content-id` of the canonical `object` of the
   `declared-item` of `S2` in `code-point-order`.
2. Those two content IDs are equal, the declared item of `S1` stands in
   a file of `T` (a text file under `item-file` or a `valid-object-file`
   of `.sinter/`), and the declared item of `S2` stands in no file of
   `T` (comes from a valid `own-store` with no file).
3. Those two content IDs are equal, both declared items stand in files
   of `T`, and the valid `path` of the file of the declared item of `S1`
   comes before the valid `path` of the file of the declared item of
   `S2` in `code-point-order`.
4. Those two content IDs are equal, both declared items stand in the
   same text file of `T`, and the `origin-position` of the
   `tag-line-text` of the declaration of the declared item of `S1` comes
   before the `origin-position` of the `tag-line-text` of the
   declaration of the declared item of `S2` in `position-order`.

For a `tree` `T` and a `subject-text` `t` that is the subject text of
one or more subjects of approval of `T`, let `S0` be the first subject
of approval of `T`, in the subject order, whose subject text is `t`. The
**subject location** of `t` in `T` is:

- when the declared item of `S0` stands in a text file of `T`
  (`item-file`), the `slice-location` of the `origin` slice of the
  `tag-line-text` of its declaration in the text of that file;
- when the declared item of `S0` stands in a `valid-object-file` of
  `.sinter/` of `T`, the valid `path` of that valid object file alone,
  with no span (`findings#location`);
- when the declared item of `S0` stands in no file of `T` (comes from a
  valid `own-store` with no file), no location.

#### Declined findings

@atom declined-finding=v1
@cites {
    ontology#{subject-of-approval=v1, declared-item=v1, tree=v1},
    documents#tree-finding=v1,
    #{
        subject-text=v1, subject-state=v1, in-force-item=v1,
        subject-order=v1,
    },
}

For a `tree` `T` under the bindings for which `in-force-item` is
defined, `T` has one `tree-finding` of the class `declined` for each
`subject-text` `t` that is the subject text of at least one
`subject-of-approval` `S` of `T` such that both of these conditions
hold:

1. `S` is `"declined"` in `T` under those bindings (`subject-state`).
2. The `declared-item` of `S` is in force in `T` under those bindings
   (`in-force-item`).

Its subject is `t`, and its location is the subject location of `t` in
`T` (`subject-order`).

#### Awaiting-approval findings

@atom awaiting-approval-finding=v1
@cites {
    ontology#{subject-of-approval=v1, declared-item=v1, tree=v1},
    documents#tree-finding=v1,
    #{
        approval-kinds=v1, subject-text=v1, subject-state=v1,
        in-force-item=v1, subject-order=v1,
    },
}

For a `tree` `T` under the bindings for which `in-force-item` is
defined, `T` has one `tree-finding` of the class `awaiting-approval`
for each `subject-text` `t` that is the subject text of at least one
`subject-of-approval` `S` of `T` such that all three of these
conditions hold:

1. `S` needs approval under the binding of `approval-kinds`.
2. The `declared-item` of `S` is in force in `T` under those bindings
   (`in-force-item`).
3. `S` is `"neither"` in `T` under those bindings (`subject-state`).

Its subject is `t`, and its location is the subject location of `t` in
`T` (`subject-order`).

#### Unapproved-requirement findings

@atom unapproved-req-finding=v1
@cites {
    conformance#own-store=v1,
    identifiers#citation-entry=v1,
    ontology#{
        edge=v1, satisfies-edge=v1, verifies-edge=v1,
        subject-of-approval=v1, declared-item=v1, test=v1, site=v1,
        tree=v1, encoding=v1,
    },
    object-store#valid-object-file=v1,
    documents#{
        tree-edge=v1, origin=v1, origin-position=v1,
        position-subject=v1, edge-finding-subject=v1,
        slice-location=v1, tree-finding=v1,
    },
    #{approval-kinds=v1, subject-state=v1, in-force-item=v1},
}

For a `tree` `T` under the bindings for which `in-force-item` is
defined, consider each `tree-edge` of `T` (in either `encoding`, or
from a valid `own-store`) such that all four of these conditions hold:

1. The edge is of the kind `satisfies` (`satisfies-edge`) or `verifies`
   (`verifies-edge`), and fits its kind (`ontology#edge`).
2. The cited item of the edge is a `declared-item` of the kind
   requirement or schema that has a `subject-of-approval`.
3. That cited item is in force in `T` under those bindings
   (`in-force-item`).
4. The subject of approval of that cited item needs approval under the
   binding of `approval-kinds` and is not `"approved"` in `T` under
   those bindings (`subject-state`).

`T` has these `tree-finding` values of the class `unapproved-req`:

- When the source of such an edge is a `declared-item` (in a text file,
  in a `valid-object-file` of `.sinter/`, or from a valid `own-store`),
  `T` has one finding for each distinct canonical edge among those
  edges. Its subject is the `edge-finding-subject` of that canonical
  edge, and its location is the object edge location of that canonical
  edge (`edge-finding-subject`).
- When the source of such an edge is a `test` or a `site`, `T` has one
  finding for that edge. Its subject is the `position-subject` of the
  `origin-position` of its `citation-entry`, and its location is the
  `slice-location` of the `origin` slice of that citation entry in the
  text of the file of the edge.

### Returning approval findings

@req give-approval-findings=v1
@cites {
    conformance#{
        conforming-program=v1, dependence=v1, report=v1,
        reject-invalid-inputs=v1, report-missing-parts=v1,
    },
    identifiers#external-namespaces=v1,
    ontology#{
        finding-class=v1, tree=v1, approval-state=v1,
        supersedes-edge=v1,
    },
    object-store#tree-object-store=v1,
    changes#{
        commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, first-parent-line=v1,
        repository-read=v1,
    },
    documents#{file-readers=v1, tree-finding=v1},
    #{
        approval-kinds=v1, persons=v1, listed-person=v1,
        subject-state=v1, merge-dependent-edge=v1, in-force-item=v1,
        incomplete-first-parent-line=v1, declined-finding=v1,
        awaiting-approval-finding=v1, unapproved-req-finding=v1,
    },
}

This requirement applies for a git repository `R`, a `tree` `T` with a
valid `tree-object-store`, valid bindings `A` of `approval-kinds`, `F`
of `file-readers`, and `N` of `external-namespaces`, a binding `D` of
`default-branch-name`, and `persons` unbound or bound.

For a `finding-class` `c` among `declined`, `awaiting-approval`, and
`unapproved-req`, with `persons` unbound or bound to a valid binding:

- When `D` is a valid binding of `default-branch-name`, the default
  branch of `R` has a `default-branch-commit` `H` under `D`, and the
  `first-parent-line` of `H` under `F` is incomplete for the
  `repository-read`s from which a program reads that first-parent line
  and the files of the trees of its commits (`commit-file`)
  (`incomplete-first-parent-line`), the **findings of `c` under the
  least merge** are the `tree-finding` values that the atom of `c`
  (`declined-finding`, `awaiting-approval-finding`, or
  `unapproved-req-finding`) defines for `T` under `A`, `F`, `N`, and
  `persons` when `in-force-item` takes the `approval-state` of the
  source of each `supersedes-edge` from the states under the least
  merge for those repository reads (`incomplete-first-parent-line`) in
  place of `subject-state`.
- The **findings of `c` under the greatest merge** need no binding of
  `default-branch-name`. Those findings are the `tree-finding` values
  that the atom of `c` (`declined-finding`, `awaiting-approval-finding`,
  or `unapproved-req-finding`) defines for `T` under `A`, `F`, `N`, and
  `persons` when `in-force-item` takes the `approval-state` of the
  source of each `supersedes-edge` from the states under the greatest
  merge (`incomplete-first-parent-line`) in place of `subject-state`.

When a conforming program returns the findings of `T` of a finding class
`c` among `declined`, `awaiting-approval`, and `unapproved-req` under
these bindings, these four rules apply for the `repository-read`s from
which the program reads the `first-parent-line` of the
`default-branch-commit` and the files of the trees of its commits
(`commit-file`):

1. When `persons` is unbound or bound to a valid binding, and either `T`
   has no `merge-dependent-edge` under `A`, or `D` is a valid binding of
   `default-branch-name` and either the default branch of `R` has no
   commit under `D` or the default branch of `R` has a commit `H` under
   `D` whose `first-parent-line` under `F` is not incomplete for those
   repository reads (`incomplete-first-parent-line`): the program must
   return once each `tree-finding` of class `c` that `T` has under those
   bindings, must return no other finding of class `c`, and must return
   no `conformance#report` stating that the program cannot see the whole
   history for class `c`.
2. When `persons` is unbound or bound to a valid binding, `T` has a
   `merge-dependent-edge` under `A`, `D` is a valid binding of
   `default-branch-name`, the default branch of `R` has a commit `H`
   under `D`, and the `first-parent-line` of `H` under `F` is incomplete
   for those repository reads: the program must return once each finding
   of class `c` under the greatest merge, and must return no other
   finding of class `c`. If the findings of class `c` under the least
   merge for those repository reads hold a finding that the findings of
   class `c` under the greatest merge do not hold, the program must
   return one `conformance#report` stating that the program cannot see
   the whole history for class `c` (as the report for that missing part
   under `report-missing-parts`); otherwise, the program must return no
   such report for class `c`.
3. When `persons` is unbound or bound to a valid binding, `T` has a
   `merge-dependent-edge` under `A`, and `D` is not a valid binding of
   `default-branch-name`: the program must return once each finding of
   class `c` under the greatest merge, and must return no other finding
   of class `c` (`reject-invalid-inputs`).
4. When `persons` is bound to a value that does not meet `persons`: the
   program must return once each finding of class `c` that rules 1 to 3
   oblige with no dependence (`dependence`) on `persons`
   (`listed-person`), and must return no other finding of class `c`
   (`reject-invalid-inputs`).

@example Suppose [approval-kinds](sinter:#approval-kinds=v1) is bound to
requirements only (`req`), so a design needs no approval by a person and
a merge approves it. A tree holds a design `old-billing` containing a
[declined](sinter:#subject-state=v1) requirement `old-billing#cap`, and
an empty design `new-billing` carrying `@supersedes old-billing=v1` (a
[merge-dependent](sinter:#merge-dependent-edge=v1)
[supersedes edge](sinter:ontology#supersedes-edge=v1)). On an
[incomplete first-parent line](sinter:#incomplete-first-parent-line=v1)
where `new-billing` did not visibly merge: under the greatest merge
`new-billing` is approved, so the edge
[takes effect](sinter:ontology#effective-supersedes-edge=v1) and retires
`old-billing` and its held requirement `old-billing#cap`
([retired-item](sinter:ontology#retired-item=v1)), producing no
[declined finding](sinter:#declined-finding=v1); under the least merge
`new-billing` is not approved, so `old-billing#cap` stays in force and
produces `declined` for `req:old-billing#cap`. The least merge holds a
finding that the greatest merge omits, so the program returns no
`declined` finding for `req:old-billing#cap` and returns one
[report](sinter:conformance#report=v1) stating that the program cannot
see the whole history for `declined`.

### Test vectors

@schema findings-vector=v1
@cites {
    data-forms#{
        index=v1, group-schema=v1, vector-line=v1, test-vector-set=v1,
        vector-meaning=v1,
    },
    text#code-point-order=v1,
    identifiers#external-namespaces=v1,
    ontology#{
        subject-of-approval=v1, declared-item=v1, test=v1, site=v1,
        tree=v1, edge=v1,
    },
    object-store#tree-object-store=v1,
    changes#{
        default-branch-name=v1, default-branch-commit=v1,
        first-parent-line=v1,
    },
    documents#{
        file-readers=v1, tree-edge=v1, position-subject=v1,
        edge-finding-subject=v1, tree-finding=v1,
    },
    findings#finding-subject=v1,
    #{
        approval-kinds=v1, persons=v1, subject-text=v1,
        subject-state=v1, in-force-item=v1,
        incomplete-first-parent-line=v1, declined-finding=v1,
        awaiting-approval-finding=v1, unapproved-req-finding=v1,
        give-approval-findings=v1,
    },
}

`findings-vector` is a `group-schema` for group `findings` in
[approval.test-vectors.jsonl](approval.test-vectors.jsonl) and tests
`give-approval-findings`. That file is a `test-vector-set` of
`vector-line` entries whose meaning follows `vector-meaning`. Group
`findings` uses no `needs` and omits `result`. Each vector stands for a
git repository and a `tree` with a valid `tree-object-store`, valid
bindings of `approval-kinds`, `file-readers`, `external-namespaces`, and
`default-branch-name`, and `persons` unbound or bound to a valid
binding, where the `first-parent-line` of the `default-branch-commit`
(when the default branch has a commit) is not incomplete
(`incomplete-first-parent-line`), no other process changes the inputs
during the run, and the program returns the expected `tree-finding`
values under `give-approval-findings` with no report that the program
cannot see the whole history.

| field | type | meaning |
|---|---|---|
| `input.binding` | array of strings | valid binding of `approval-kinds`: kind words of the kinds in the binding (`subject-text`), each once, in `code-point-order` |
| `input.subjects` | array of objects | sequence of the subjects of approval (`subject-of-approval`) of the `tree` |
| `input.subjects[].subject` | string | `subject-text` of the subject of approval |
| `input.subjects[].state` | string | `"approved"`, `"declined"`, or `"neither"` (`subject-state`) |
| `input.subjects[].in-force` | boolean | `true` when the `declared-item` of the subject of approval is in force (`in-force-item`), `false` otherwise |
| `input.edges` | array of objects | sequence of the `tree-edge` values of the `tree` |
| `input.edges[].kind` | string | kind of edge (`ontology#edge`) |
| `input.edges[].fits` | boolean | `true` when the edge fits its kind (`ontology#edge`), `false` otherwise |
| `input.edges[].at` | string | `finding-subject` for the edge: `edge-finding-subject` when its source is a `declared-item`, or `position-subject` when its source is a `test` or `site` |
| `input.edges[].cited` | integer (`>= 1`, optional) | present (with `in-force`) when the edge's cited item is a requirement or schema with a `subject-of-approval`: 1-based `index` of that subject of approval in `input.subjects`; absent otherwise |
| `input.edges[].in-force` | boolean (optional) | present (with `cited`) when the edge's cited item is a requirement or schema with a `subject-of-approval`: `true` when that cited item is in force (`in-force-item`), `false` otherwise; absent otherwise |
| `values.findings.awaiting-approval` | array of strings | `finding-subject` values of all `awaiting-approval-finding` findings of the tree, each once, in `code-point-order` |
| `values.findings.declined` | array of strings | `finding-subject` values of all `declined-finding` findings of the tree, each once, in `code-point-order` |
| `values.findings.unapproved-req` | array of strings | `finding-subject` values of all `unapproved-req-finding` findings of the tree, each once, in `code-point-order` |

Each JSON object in `input` and `values` holds only the members listed
in this table, with `input.edges[].cited` and `input.edges[].in-force`
either both present or both absent.

@example Sample lines testing
[give-approval-findings](sinter:#give-approval-findings=v1) under an
empty [approval-kinds](sinter:#approval-kinds=v1) binding and on a
subject in [conflict](sinter:#judgment-conflict=v1) that produces
[awaiting-approval-finding](sinter:#awaiting-approval-finding=v1) and
[unapproved-req-finding](sinter:#unapproved-req-finding=v1)
([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#findings-vector=v1","group":"findings","input":{"binding":[],"edges":[{"at":"src/fee.ml@L3C4","cited":1,"fits":true,"in-force":true,"kind":"satisfies"}],"subjects":[{"in-force":true,"state":"neither","subject":"req:billing#limit"},{"in-force":true,"state":"approved","subject":"spec:billing#auth"}]},"note":"under the empty binding, nothing waits for a person","values":{"findings":{"awaiting-approval":[],"declined":[],"unapproved-req":[]}}}
{"form":"#findings-vector=v1","group":"findings","input":{"binding":["req"],"edges":[{"at":"src/limit.ml@L10C4","cited":1,"fits":true,"in-force":true,"kind":"satisfies"}],"subjects":[{"in-force":true,"state":"neither","subject":"req:billing#limit"}]},"note":"a subject in conflict has state neither and gives `awaiting-approval` and `unapproved-req`, not `declined`","values":{"findings":{"awaiting-approval":["req:billing#limit"],"declined":[],"unapproved-req":["src/limit.ml@L10C4"]}}}
```
