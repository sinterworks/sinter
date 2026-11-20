<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Work
@design work=v1
@cites text=v1
@cites identifiers=v1
@cites files=v1
@cites data-forms=v1
@cites ontology=v1
@cites changes=v1
@cites documents=v1
@cites ledger=v1
@cites rfc/5234
@cites rfc/7405
@cites rfc/8259
@cites gitdoc/gitglossary
Specifies the parameter `exempt-paths`; work item ids, commit object names, task promises, and task hashes; the fields and acceptance rules of `task`, `plan`, `done`, `abandoned`, and `delivered` ledger entries; the forms of delivery lines and task lines; and requirements for conforming programs that assign ids, compute task hashes, read message lines, decide acceptance, compute task states, plan states, readiness, and requirement accounting, and append `done` ledger entries.

Tasks and plans record planned work in the ledger of a git repository,
and commits name the tasks whose work they advance or finish in task
lines and delivery lines. A task definition fixes a task's display name,
paths, promises, waits, optional holding plan, and optional external
item. A plan definition fixes a plan's display name, waits, optional
holding plan, and carried-out items. Acceptance rules decide which
ledger entries of the five work kinds can stand at each point of a
ledger, and the accepted entries give each work item's state, each
task's readiness, and which requirements work accounts for.

From Text and notation (`text`), the design takes characters, texts,
whole numbers, decimal numerals, hex digits, code point order, lines,
line numbers, code spans, the notation of productions and rule names,
and what a conforming program, an input, and a result are. From
Identifiers (`identifiers`), it takes slugs, full names, labels,
external ids, bindings of the parameter `external-namespaces`, and the
result "valid" of such a binding. From Files and paths (`files`), it
takes path sets and valid path sets. From Data forms (`data-forms`), it
takes indexes, JSON values, canonical forms, canonical byte sequences,
hashes, hash forms, id prefixes, hash-id forms, test-vector sets, vector
lines, the forms of a group, and the meaning of a vector.

From the Ontology (`ontology`), the design takes trees, declared items,
item names, current revisions, revised content, external items, work
items, tasks, promises, plans, waits, carried-out items, work item
definitions, delivery lines, task lines, ledger entries, the ledger and
its points, definition entries, judgments, records of the job, work item
states, met waits, ready tasks, accounted-for requirements, parameters,
and the requirements on who appends each kind of entry. From Changes
(`changes`), it takes commits and the texts of commit messages. From
Documents (`documents`), it takes the declared items of a tree, extent
hashes, bindings of the parameter `file-readers`, and sets of stopped
files. From the Ledger (`ledger`), it takes the fields of a kind of
ledger entry, acceptance rules, valid ledgers, ledger objects, and
stored ledgers.

The productions are written in ABNF, the notation of RFC 5234, with the
case-sensitive strings `%s"..."` of RFC 7405. From RFC 8259, the design
takes JSON texts, with their objects, members, arrays, strings, and
numbers. From the git manual page `gitglossary`, it takes commit objects
and their object names.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [exempt paths](sinter:#exempt-paths=v1) | a valid path set given by a binding of the parameter `exempt-paths` |
| [task id](sinter:#work-item-id=v1), [plan id](sinter:#work-item-id=v1) | a text that fits the hash-id form with the id prefix `t-` (for a task) or `p-` (for a plan) and 12 hex digits, such as `t-3f2a9c1d07e4` or `p-0a1b2c3d4e5f` |
| [commit object name](sinter:#commit-object-name=v1) | the object name of a commit object as `gitglossary` defines it, written as 40 or 64 lowercase hex digits |
| [promise object](sinter:#task-promise=v1), [promise order](sinter:#task-promise=v1) | a JSON object with `kind` (`satisfies` or `verifies`) and `req` (a slug or full name); promise order sorts first by `kind` and then by `req`, each in code point order |
| [task-hash pre-image](sinter:#task-hash=v1), [task hash](sinter:#task-hash=v1) | the canonical form of the JSON object holding a task definition's sorted `paths` and sorted `promises`, and the SHA-256 hash of its canonical byte sequence |
| [index in a ledger](sinter:#ledger-index=v1), [point of an index](sinter:#ledger-index=v1) | the number, counted from 1, of an element of the sequence of a ledger; the point of index k is the point of the first k − 1 ledger entries; the indexes before the point of the first n ledger entries are 1 to n |
| [fields of a `task` ledger entry](sinter:#task-field=v1) | `work-item`, `def`, `name`, `paths`, `promises`, `waits`, and optional `item` and `plan` |
| [fields of a `plan` ledger entry](sinter:#plan-field=v1) | `work-item`, `def`, `name`, `waits`, `carries-out`, and optional `plan` |
| [fields of a `done` ledger entry](sinter:#done-field=v1) | `work-item`, `requirements`, and optional `note` |
| [fields of an `abandoned` ledger entry](sinter:#abandoned-field=v1) | `work-item` and `reason` |
| [fields of a `delivered` ledger entry](sinter:#delivered-field=v1) | `work-item`, `commit`, `merge`, `head`, `hash`, and `definitions` |
| [work-graph cycle](sinter:#work-graph-cycle=v1) | a cycle in the composition edges from plans to their parts or in the combined directed graph of composition edges, direct waits, and waits inherited from holding plans |
| [acceptance rule](sinter:ledger#accepted-entry=v1), [accepted](sinter:ledger#accepted-entry=v1) | the condition under which a ledger entry of a given kind can stand at a point of a ledger; a ledger entry is accepted at a point when the acceptance rule of its kind holds for it there |
| [delivery line](sinter:#delivery-line-form=v1), [malformed delivery line](sinter:#delivery-line-form=v1) | a line matching `Delivers: t-<12 hex> <6 hex>` with optional trailing spaces, tabs, or carriage returns; a line that starts with `Delivers: ` and does not match that form |
| [task line](sinter:#task-line-form=v1) | a line matching `Task: t-<12 hex>` with optional trailing spaces, tabs, or carriage returns |
| [counts at a point](sinter:#counting-delivery-line=v1) | a delivery line counts at a point of a ledger when its task exists at that point and its six hex digits are the first six characters of the task hash of the current definition of that task at that point |
| [set of stopped files](sinter:documents#unreadable-file=v1) | a set of files of a tree that a program takes as an input of its own and stops reading for limits of its own |

## 2. Tasks, plans, delivery, and states

### 2.1 Work item ids and definitions

Each task has a [task id](sinter:#work-item-id=v1) such as
`t-3f2a9c1d07e4`, and each plan has a [plan id](sinter:#work-item-id=v1)
such as `p-0a1b2c3d4e5f`. Because task ids start with `t-` and plan ids
start with `p-`, a task id never equals a plan id. When a program
creates a new task or plan, it chooses an id of the right form that no
existing work item has at the point of the first definition entry
(requirement `assign-new-work-item-id`).

A `task` ledger entry records one whole definition of a task, and a
`plan` ledger entry records one whole definition of a plan (schemas
`task-field` and `plan-field`). The integer `def` numbers the
definitions of one work item in order, starting at `1` at creation and
rising by `1` at each accepted change. A task with an external item in
`item`, such as `gh/42`, may carry an empty string in `name`; a task
without `item`, and every plan, carries a non-empty `name`. A task's
`paths` holds a valid path set, which can be empty (`[]`). For example,
a `task` ledger entry with common fields from the Ledger looks like
this:

```
{"by":"Ada Lovelace <ada@example.com>","def":1,"id":"e-11111111111111111111111111111111","kind":"task","name":"Enforce billing limit","paths":["src/billing/**","!src/billing/generated/**"],"promises":[{"kind":"satisfies","req":"billing#limit"},{"kind":"verifies","req":"billing#limit"}],"seq":1,"v":1,"waits":[],"work-item":"t-3f2a9c1d07e4"}
```

A `plan` ledger entry carries `carries-out` in place of `paths`,
`promises`, and `item`. For example:

```
{"by":"Ada Lovelace <ada@example.com>","carries-out":["billing"],"def":1,"id":"e-22222222222222222222222222222222","kind":"plan","name":"Billing rollout","seq":2,"v":1,"waits":[],"work-item":"p-0a1b2c3d4e5f"}
```

### 2.2 Acceptance of the five work kinds

Each of the five kinds `task`, `plan`, `done`, `abandoned`, and
`delivered` has an acceptance rule (atoms `definition-acceptance-rule`,
`work-judgment-acceptance-rule`, and `delivered-acceptance-rule`). Every
acceptance rule reads only the candidate ledger entry and the ledger
entries before its point, and never a tree, a commit, a binding, or test
evidence. Therefore, every clone with the same ledger gives the same
acceptance results and the same work item states.

Each acceptance rule requires that the candidate ledger entry meet the
schema of its kind. An entry of one of these five kinds that fails its
schema is accepted at no point and changes no state.

A `task` or `plan` entry is accepted only when its `def` is the next
number for its work item, its work item is not closed, every work item
in `waits` exists at the point, any named `plan` exists and is not
abandoned at the point, and the new definition creates no
[work-graph cycle](sinter:#work-graph-cycle=v1). A done task and an
abandoned task are closed; an abandoned plan is closed; a done plan is
not closed, so a new part can name a done plan and reopen it, and a
`plan` entry can edit a done plan.

A work-graph cycle covers three cases in one graph: a cycle of holding
plans (such as plan `p1` under `p2` and `p2` under `p1`), a cycle of
waits (such as `t1` waiting for `t2` and `t2` waiting for `t1`), and a
cycle mixing both. Because every work item under a plan inherits the
waits of that plan, a plan waiting for one of its own parts creates a
cycle from that part to itself, and a task under `p1` waiting for `t2`
under `p2` while `p2` waits for `p1` creates a cycle through both plans.

A `done` entry is accepted only when its task exists, is unfinished
(open or delivered), and lists in `requirements` the exact set of
distinct requirement names promised by the current definition of that
task. An `abandoned` entry is accepted for a task only when the task
exists and is unfinished, and for a plan only when the plan exists and
is open. A done plan cannot be abandoned.

A `delivered` entry is accepted when its task exists at the point
(whatever the state of the task), no earlier accepted `delivered` entry
records the same `(commit, work-item, hash)` triple, and every object in
`definitions` names the full task hash of an earlier accepted definition
of that task with that definition's exact set of promises. A `delivered`
entry for a task that is already done or abandoned is accepted as a
recorded fact and changes no state.

### 2.3 Task hashes, delivery lines, and task lines

The [task hash](sinter:#task-hash=v1) of a task definition uses only its
`paths` and its `promises`. The task id, the display name, the external
item, the holding plan, and the waits do not enter the task hash. To
make the hash independent of the order in which a ledger entry lists
paths or promises, the pre-image object sorts `paths` in code point
order and `promises` in [promise order](sinter:#task-promise=v1).
Changing a task's display name or waits keeps the same task hash.

A [delivery line](sinter:#delivery-line-form=v1) in a commit message has
the form `Delivers: t-3f2a9c1d07e4 0e515c`, with optional spaces, tabs,
or carriage returns at the end of the line. A delivery line can stand on
any line of any paragraph of a commit message. A
[task line](sinter:#task-line-form=v1) has the form
`Task: t-3f2a9c1d07e4` with no hash. A delivery line
[counts at a point](sinter:#counting-delivery-line=v1) when its task
exists at that point and its six hex digits match the first six hex
digits of the task hash of the current definition of that task at that
point, whatever the task's state.

### 2.4 States, readiness, and requirement accounting

Ontology defines task states, plan states, met waits, ready tasks, and
accounted-for requirements from accepted ledger entries. The atom
`delivered-task-completion` supplies the concrete conditions on
`delivered` and `done` entries that those rules read.

A `delivered` entry carries `definitions`, one entry for each distinct
full task hash among the definitions of the task that its six hex digits
named. The entry makes its task done when the task was not abandoned at
the entry's point, the six hex digits match the first six characters of
the current definition's task hash, `definitions` holds an element for
that full task hash, and every promise in that element has the outcome
`kept`. A `verifies` promise with the outcome `no-result` counts as not
kept, so the task becomes delivered rather than done.

When a person appends a `done` entry, the program records for each
promised requirement the current label and extent hash of that
requirement in the tree in which the person judged the work (requirement
`record-done-requirements`). When that tree has no single declared item
of the kind requirement with that name (because the item is missing, the
only item with that name has another kind, two declarations share the
name, or its file cannot be read), the entry omits `label` and `hash`
for that requirement. An entry that omits `label` and `hash` for a
requirement never accounts for that requirement.

What a program gives while another process changes a file, a ref, or the
ledger is a matter of the quality of an implementation.

## 3. Parameters

### 3.1 `exempt-paths`

@schema exempt-paths=v1
@cites {
    files#{path-set=v1, valid-path-set=v1},
    ontology#{parameter=v1},
    text#{code-span=v1},
}

A binding of the parameter `exempt-paths` is a path set. A binding of
`exempt-paths` meets the schema `exempt-paths` when, and only when, it
is a valid path set.

## 4. Definitions

### 4.1 Work item ids

@term work-item-id=v1
@cites {
    data-forms#{id-prefix=v1, hash-id-form=v1},
    ontology#{work-item=v1, task=v1, plan=v1},
    text#{text=v1, hex-digit=v1, whole-number=v1, code-span=v1},
}

A task id is a text that fits the hash-id form with the id prefix `t-`
and 12 hex digits. A plan id is a text that fits the hash-id form with
the id prefix `p-` and 12 hex digits. The work item id of a task is a
task id. The work item id of a plan is a plan id.

### 4.2 Commit object names

@term commit-object-name=v1
@cites {
    gitdoc/gitglossary,
    rfc/5234,
    changes#{commit=v1},
    text#{text=v1, hex-digit=v1, production=v1, rule-name=v1, code-span=v1},
}

A commit object name is a text that matches the production
`commit-object-name`:

```abnf
commit-object-name  = 40hex-digit / 64hex-digit
```

The commit object name of a commit is the object name of that commit
object, as the page `gitglossary` defines object names, written in hex
digits.

### 4.3 Task promises

@term task-promise=v1
@cites {
    identifiers#{slug=v1, full-name=v1},
    ontology#{promise=v1},
    data-forms#{json-value=v1},
    text#{text=v1, code-point-order=v1, production=v1, code-span=v1},
}

A promise object is a JSON object that has the member `kind`, has the
member `req`, and has no other member. The value of `kind` is the string
`satisfies` or the string `verifies`. The value of `req` is a string
that matches the production `slug` or the production `full-name` of
Identifiers.

Two promise objects are equal when, and only when, they have the same
value of `kind` and the same value of `req`. In promise order, a promise
object A comes before a promise object B that is not equal to A when,
and only when, one of these two conditions is true:

1. The value of `kind` of A comes before the value of `kind` of B in
   code point order.
2. The value of `kind` of A and the value of `kind` of B are the same
   text, and the value of `req` of A comes before the value of `req` of
   B in code point order.

### 4.4 Task hashes

@term task-hash=v1
@cites {
    files#{path-set=v1, valid-path-set=v1},
    data-forms#{
        json-value=v1, canonical-form=v1, canonical-byte-sequence=v1,
        hash=v1,
    },
    ontology#{work-item-definition=v1, task=v1, promise=v1},
    text#{text=v1, code-point-order=v1, code-span=v1},
    #{task-promise=v1},
}

For a valid path set P and a finite set Q of promise objects in which no
two promise objects are equal, the task-hash object of P and Q is the
JSON object with exactly two members:

- `paths`, an array whose elements are the path set members of P, each
  as a string, in code point order;
- `promises`, an array whose elements are the promise objects of Q, in
  promise order.

The task-hash pre-image of P and Q is the canonical form of the
task-hash object of P and Q. The task hash of P and Q is the hash of the
canonical byte sequence of the task-hash object of P and Q. For a
definition of a task whose paths are P and whose promises are Q, the
task-hash pre-image of that definition is the task-hash pre-image of P
and Q, and the task hash of that definition is the task hash of P and Q.

### 4.5 Indexes in a ledger

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

### 4.6 The fields of `task` ledger entries

@schema task-field=v1
@cites {
    ledger#{entry-field=v1},
    data-forms#{json-value=v1},
    files#{path-set=v1, valid-path-set=v1},
    identifiers#{external-id=v1},
    ontology#{ledger-entry=v1, task=v1, work-item-definition=v1},
    text#{text=v1, whole-number=v1, production=v1, code-span=v1},
    #{work-item-id=v1, task-promise=v1},
}

The fields of the kind `task` are these required fields, with these
values:

- `work-item`, a string that is a task id;
- `def`, an integer of 1 or more;
- `name`, a string; when the ledger entry has no member `item`, `name`
  is not the empty text;
- `paths`, an array of strings whose elements, in their order, are a
  valid path set;
- `promises`, an array of promise objects in which no two elements are
  equal;
- `waits`, an array of strings that are each a task id or a plan id, in
  which no two elements are the same text.

A ledger entry of the kind `task` can also have these optional fields:

- `item`, a string that matches the production `external-ref` of the
  term `identifiers#external-id`;
- `plan`, a string that is a plan id.

A ledger entry of the kind `task` meets the schema `task-field` when,
and only when, its object has each required field of the kind `task`
with a value of the form that this schema gives, and each optional field
of the kind `task` that its object has holds a value of the form that
this schema gives.

### 4.7 The fields of `plan` ledger entries

@schema plan-field=v1
@cites {
    ledger#{entry-field=v1},
    data-forms#{json-value=v1},
    identifiers#{slug=v1, full-name=v1},
    ontology#{
        ledger-entry=v1, plan=v1, carried-out-item=v1,
        work-item-definition=v1,
    },
    text#{text=v1, whole-number=v1, production=v1, code-span=v1},
    #{work-item-id=v1},
}

The fields of the kind `plan` are these required fields, with these
values:

- `work-item`, a string that is a plan id;
- `def`, an integer of 1 or more;
- `name`, a string that is not the empty text;
- `waits`, an array of strings that are each a task id or a plan id, in
  which no two elements are the same text;
- `carries-out`, an array of strings that each match the production
  `slug` or the production `full-name` of Identifiers, in which no two
  elements are the same text.

A ledger entry of the kind `plan` can also have the optional field
`plan`, a string that is a plan id.

A ledger entry of the kind `plan` meets the schema `plan-field` when,
and only when, its object has each required field of the kind `plan`
with a value of the form that this schema gives, and, when its object
has the member `plan`, the value of `plan` is a plan id.

### 4.8 The fields of `done` ledger entries

@schema done-field=v1
@cites {
    ledger#{entry-field=v1},
    data-forms#{json-value=v1, hash-form=v1},
    identifiers#{slug=v1, full-name=v1, label=v1},
    ontology#{ledger-entry=v1, judgment=v1},
    text#{text=v1, production=v1, code-span=v1},
    #{work-item-id=v1},
}

A requirement record is a JSON object that meets all three of these
conditions:

1. It has the member `req`, whose value is a string that matches the
   production `slug` or the production `full-name` of Identifiers.
2. Either it has both the member `label`, whose value is a string that
   is a label, and the member `hash`, whose value is a string that fits
   the hash form; or it has neither `label` nor `hash`.
3. It has no member other than `req`, `label`, and `hash`.

The fields of the kind `done` are these required fields, with these
values:

- `work-item`, a string that is a task id;
- `requirements`, an array of requirement records in which no two
  elements have the same value of `req`.

A ledger entry of the kind `done` can also have the optional field
`note`, a string.

A ledger entry of the kind `done` meets the schema `done-field` when,
and only when, its object has each required field of the kind `done`
with a value of the form that this schema gives, and, when its object
has the member `note`, the value of `note` is a string.

### 4.9 The fields of `abandoned` ledger entries

@schema abandoned-field=v1
@cites {
    ledger#{entry-field=v1},
    data-forms#{json-value=v1},
    ontology#{ledger-entry=v1, judgment=v1},
    text#{code-span=v1},
    #{work-item-id=v1},
}

The fields of the kind `abandoned` are these required fields, with these
values:

- `work-item`, a string that is a task id or a plan id;
- `reason`, a string.

A ledger entry of the kind `abandoned` meets the schema
`abandoned-field` when, and only when, its object has each required
field of the kind `abandoned` with a value of the form that this schema
gives.

### 4.10 The fields of `delivered` ledger entries

@schema delivered-field=v1
@cites {
    rfc/5234,
    ledger#{entry-field=v1},
    data-forms#{json-value=v1, hash-form=v1},
    identifiers#{slug=v1, full-name=v1, label=v1},
    ontology#{ledger-entry=v1, job-record=v1},
    text#{text=v1, hex-digit=v1, production=v1, rule-name=v1, code-span=v1},
    #{
        work-item-id=v1, commit-object-name=v1, task-promise=v1,
        task-hash=v1,
    },
}

A short task hash is a text that matches the production
`short-task-hash`:

```abnf
short-task-hash  = 6hex-digit
```

A promise observation is a JSON object that meets all four of these
conditions:

1. It has the member `kind`, whose value is the string `satisfies` or
   the string `verifies`, and the member `req`, whose value is a string
   that matches the production `slug` or the production `full-name` of
   Identifiers.
2. It has the member `outcome`: when `kind` is `satisfies`, the value of
   `outcome` is one of the strings `kept` and `not-kept`; when `kind` is
   `verifies`, the value of `outcome` is one of the strings `kept`,
   `not-kept`, and `no-result`.
3. Either it has both the member `label`, whose value is a string that
   is a label, and the member `hash`, whose value is a string that fits
   the hash form; or it has neither `label` nor `hash`.
4. It has no member other than `kind`, `req`, `outcome`, `label`, and
   `hash`.

A definition observation for a short task hash s is a JSON object that
has the member `task-hash`, has the member `promises`, and has no other
member, where:

- `task-hash` is a string that fits the hash form and whose first six
  characters are s;
- `promises` is an array of promise observations in which no two
  elements have both the same value of `kind` and the same value of
  `req`.

The fields of the kind `delivered` are these required fields, with these
values:

- `work-item`, a string that is a task id;
- `commit`, a string that is a commit object name;
- `merge`, a string that is a commit object name;
- `head`, a string that is a commit object name;
- `hash`, a string that is a short task hash;
- `definitions`, an array of definition observations for the value of
  `hash` of the ledger entry, in which no two elements have the same
  value of `task-hash`.

A ledger entry of the kind `delivered` meets the schema
`delivered-field` when, and only when, its object has each required
field of the kind `delivered` with a value of the form that this schema
gives.

### 4.11 Cycles of plans and waits

@term work-graph-cycle=v1
@cites {
    ontology#{
        work-item=v1, task=v1, plan=v1, wait=v1,
        work-item-definition=v1, work-item-state=v1, ledger=v1,
    },
    text#{whole-number=v1},
}

For a point P of a ledger, a task or plan w, and a candidate definition
D for w, let W be the set of all work items that exist at P together
with w. The effective definition of w is D, and the effective definition
of each other work item in W is its current definition at P.

A composition edge is a pair (p, x) of a plan p in W and a work item x
in W such that the effective definition of x names p as the plan of x, x
is not abandoned at P, and p was not abandoned before P while x was not
done. A composition cycle is a finite sequence of one or more
composition edges (u1, v1), ..., (uk, vk) in which vi is u(i + 1) for
each whole number i from 1 to k − 1 and vk is u1.

When no composition cycle exists, a work item x in W is under a plan p
in W for these effective definitions when, and only when, (p, x) is a
composition edge, or x is under a work item q in W such that (p, q) is a
composition edge. When no composition cycle exists, the combined work
graph has these directed edges between work items in W:

1. each composition edge (p, x);
2. each pair (x, y) such that the effective definition of x names a wait
   for y;
3. each pair (x, y) such that x is under a plan p in W for these
   effective definitions and the effective definition of p names a wait
   for y.

A work-graph cycle exists for w and D at P when, and only when, either a
composition cycle exists, or no composition cycle exists and the
combined work graph has a finite sequence of one or more directed edges
(u1, v1), ..., (uk, vk) in which vi is u(i + 1) for each whole number i
from 1 to k − 1 and vk is u1.

### 4.12 The acceptance rule of `task` and `plan` ledger entries

@atom definition-acceptance-rule=v1
@refines ledger#accepted-entry=v1
@cites {
    ontology#{
        ledger=v1, ledger-entry=v1, definition-entry=v1, work-item=v1,
        task=v1, plan=v1, work-item-state=v1,
    },
    data-forms#{json-value=v1},
    text#{whole-number=v1, code-span=v1},
    #{
        ledger-index=v1, task-field=v1, plan-field=v1,
        work-graph-cycle=v1,
    },
}

The acceptance rule of the kinds `task` and `plan` reads only the
candidate ledger entry E and the ledger entries before the point P of a
ledger. It holds for E at P when, and only when, each of these six
conditions is true:

1. When E is of the kind `task`, E meets the schema `task-field`. When E
   is of the kind `plan`, E meets the schema `plan-field`.
2. Let w be the value of `work-item` of E. When no accepted definition
   entry before P has w as its `work-item`, the value of `def` of E is
   1. When at least one accepted definition entry before P has w as its
   `work-item`, the value of `def` of E is 1 more than the value of
   `def` of the accepted definition entry with `work-item` w at the
   greatest index before P.
3. When E is of the kind `task` and w exists at P, w is neither done nor
   abandoned at P. When E is of the kind `plan` and w exists at P, w is
   not abandoned at P.
4. Each work item id in the value of `waits` of E names a work item that
   exists at P.
5. When E has the member `plan`, its value names a plan that exists at P
   and is not abandoned at P.
6. No work-graph cycle exists for w and the definition that E records at
   P.

### 4.13 The acceptance rule of `done` and `abandoned` ledger entries

@atom work-judgment-acceptance-rule=v1
@refines ledger#accepted-entry=v1
@cites {
    ontology#{
        ledger=v1, ledger-entry=v1, work-item=v1, task=v1, plan=v1,
        work-item-definition=v1, work-item-state=v1,
    },
    data-forms#{json-value=v1},
    text#{code-span=v1},
    #{work-item-id=v1, done-field=v1, abandoned-field=v1},
}

The acceptance rule of the kinds `done` and `abandoned` reads only the
candidate ledger entry E and the ledger entries before the point P of a
ledger.

For a ledger entry E of the kind `done`, the acceptance rule holds at P
when, and only when, each of these three conditions is true:

1. E meets the schema `done-field`.
2. The value of `work-item` of E names a task that exists at P and is
   unfinished at P.
3. The set of the values of `req` of the elements of `requirements` of E
   is the set of the values of `req` of the promises of the current
   definition of that task at P.

For a ledger entry E of the kind `abandoned`, the acceptance rule holds
at P when, and only when, both of these conditions are true:

1. E meets the schema `abandoned-field`.
2. Let w be the value of `work-item` of E. When w is a task id, w names
   a task that exists at P and is unfinished at P. When w is a plan id,
   w names a plan that exists at P and is open at P.

### 4.14 The acceptance rule of `delivered` ledger entries

@atom delivered-acceptance-rule=v1
@refines ledger#accepted-entry=v1
@cites {
    ontology#{
        ledger=v1, ledger-entry=v1, task=v1, work-item-definition=v1,
        work-item-state=v1,
    },
    data-forms#{json-value=v1},
    text#{code-span=v1},
    #{ledger-index=v1, delivered-field=v1, task-hash=v1},
}

The acceptance rule of the kind `delivered` reads only the candidate
ledger entry E and the ledger entries before the point P of a ledger. It
holds for a ledger entry E of the kind `delivered` at P when, and only
when, each of these four conditions is true:

1. E meets the schema `delivered-field`.
2. The value of `work-item` of E names a task that exists at P.
3. No accepted `delivered` ledger entry at an index before P has the
   same value of `commit`, the same value of `work-item`, and the same
   value of `hash` as E.
4. For each element D of `definitions` of E, there is an accepted `task`
   ledger entry at an index before P whose `work-item` is the
   `work-item` of E and whose definition has the value of `task-hash` of
   D as its task hash, and the set of pairs of `kind` and `req` of the
   elements of `promises` of D is the set of pairs of `kind` and `req`
   of the promises of that definition.

### 4.15 Task completion and requirement accounting

@atom delivered-task-completion=v1
@refines ontology#work-item-state=v1
@cites {
    ontology#{
        ledger=v1, ledger-entry=v1, task=v1, work-item-definition=v1,
        judgment=v1, job-record=v1, requirement-accounted-for=v1,
        declared-item=v1, item-name=v1, item-revision=v1,
        revised-content=v1, tree=v1, parameter=v1,
    },
    identifiers#{external-namespaces=v1},
    documents#{file-readers=v1, extent-hash=v1, unreadable-file=v1},
    data-forms#{json-value=v1},
    text#{text=v1, code-span=v1},
    #{
        done-field=v1, delivered-field=v1, task-hash=v1,
        definition-acceptance-rule=v1, work-judgment-acceptance-rule=v1,
        delivered-acceptance-rule=v1,
    },
}

In the atom `ontology#work-item-state`, an accepted `delivered` ledger
entry E of a task t at its point P records that the job observed that a
delivery line of t named the definition of t that was current at P and
that each promise of that definition was kept when, and only when, all
three of these conditions are true:

1. The task hash H of the definition of t that was current at P has, as
   its first six characters, the value of `hash` of E.
2. The member `definitions` of E holds an element D whose value of
   `task-hash` is H.
3. Every element of `promises` of D has the value `kept` for `outcome`.

In the atom `ontology#requirement-accounted-for`, for a tree T, a valid
binding F of `file-readers`, a binding N of `external-namespaces`, a set
S of stopped files of T, and an item r of the kind requirement of T
under F, N, and S:

- An accepted `done` ledger entry E records both the current revision of
  r in T and the same revised content as the revised content of r in T
  for r when, and only when, `requirements` of E holds an element whose
  `req` is the name of r in T, that element has both `label` and `hash`,
  the value of `label` of that element is the current revision of r in
  T, and the value of `hash` of that element is the extent hash of r in
  T under F, N, and S.
- An accepted `delivered` ledger entry E at its point P records both the
  current revision of r in T and the same revised content as the revised
  content of r in T for a promise of the definition of its task that was
  current at P when, and only when, `definitions` of E holds an element
  D whose `task-hash` is the task hash of that current definition, and
  `promises` of D holds an element whose `req` is the name of r in T,
  that element has both `label` and `hash`, the value of `label` of that
  element is the current revision of r in T, and the value of `hash` of
  that element is the extent hash of r in T under F, N, and S.

### 4.16 The form of delivery lines

@schema delivery-line-form=v1
@cites {
    rfc/5234,
    rfc/7405,
    ontology#{delivery-line=v1},
    text#{
        text=v1, line=v1, hex-digit=v1, production=v1, rule-name=v1,
        code-span=v1,
    },
}

This production gives the form of a delivery line:

```abnf
delivery-line  = %s"Delivers:" SP %s"t-" 12hex-digit SP 6hex-digit
                 *( SP / HTAB / CR )
```

A line meets the schema `delivery-line-form` when, and only when, the
text of that line matches the production `delivery-line`. For a line
that meets `delivery-line-form`, the task id of that delivery line is
the text that `%s"t-" 12hex-digit` matches, and the short task hash of
that delivery line is the text that `6hex-digit` matches.

A line is a malformed delivery line when, and only when, the text of
that line starts with `Delivers: ` and the line does not meet the schema
`delivery-line-form`.

### 4.17 The form of task lines

@schema task-line-form=v1
@cites {
    rfc/5234,
    rfc/7405,
    ontology#{task-line=v1},
    text#{
        text=v1, line=v1, hex-digit=v1, production=v1, rule-name=v1,
        code-span=v1,
    },
}

This production gives the form of a task line:

```abnf
task-line  = %s"Task:" SP %s"t-" 12hex-digit *( SP / HTAB / CR )
```

A line meets the schema `task-line-form` when, and only when, the text
of that line matches the production `task-line`. For a line that meets
`task-line-form`, the task id of that task line is the text that
`%s"t-" 12hex-digit` matches.

### 4.18 Delivery lines that count

@term counting-delivery-line=v1
@cites {
    ontology#{ledger=v1, task=v1, work-item-state=v1},
    text#{text=v1},
    #{delivery-line-form=v1, task-hash=v1},
}

A line that meets `delivery-line-form` counts at a point P of a ledger
when, and only when, the task id of that delivery line names a task that
exists at P and the short task hash of that delivery line is the first
six characters of the task hash of the current definition of that task
at P. This holds whatever the state of that task at P.

## 5. Requirements

### 5.1 New work item ids

@req assign-new-work-item-id=v1
@cites {
    ontology#{
        ledger=v1, definition-entry=v1, work-item=v1, task=v1, plan=v1,
        work-item-state=v1,
    },
    text#{conforming-program=v1, code-span=v1},
    #{work-item-id=v1, task-field=v1, plan-field=v1},
}

When a conforming program appends a `task` ledger entry to create a new
task at a point P of a ledger, the value of `work-item` of that ledger
entry must be a task id that no work item has at P. When a conforming
program appends a `plan` ledger entry to create a new plan at a point P
of a ledger, the value of `work-item` of that ledger entry must be a
plan id that no work item has at P.

### 5.2 Task hashes

@req give-task-hash=v1
@cites {
    files#{path-set=v1, valid-path-set=v1},
    text#{conforming-program=v1},
    #{task-promise=v1, task-hash=v1},
}

For a valid path set P and a finite set Q of promise objects in which no
two promise objects are equal, when a conforming program gives the
task-hash pre-image of P and Q, it must give only the task-hash
pre-image of P and Q, or refuse for limits of its own and give no
result. For such P and Q, when a conforming program gives the task hash
of P and Q, it must give only the task hash of P and Q, or refuse for
limits of its own and give no result.

### 5.3 Delivery lines and task lines of commit messages

@req give-message-work-lines=v1
@cites {
    changes#{commit=v1, message-text=v1},
    text#{conforming-program=v1, line=v1, line-number=v1},
    #{delivery-line-form=v1, task-line-form=v1},
}

When a conforming program gives the delivery lines of a commit whose
message has a text, it must give each line of that text that meets
`delivery-line-form` once, in the order of their line numbers, with its
line number, its task id, and its short task hash, and no other line.
When a conforming program gives the malformed delivery lines of a commit
whose message has a text, it must give each line of that text that is a
malformed delivery line once, in the order of their line numbers, with
its line number, and no other line. When a conforming program gives the
task lines of a commit whose message has a text, it must give each line
of that text that meets `task-line-form` once, in the order of their
line numbers, with its line number and its task id, and no other line.
When the message of a commit has no text, a conforming program must give
no delivery line, no malformed delivery line, and no task line for that
commit.

### 5.4 The acceptance of work ledger entries

@req give-work-entry-acceptance=v1
@cites {
    ledger#{
        accepted-entry=v1, ledger-validity=v1, ledger-object=v1,
        stored-ledger=v1,
    },
    ontology#{ledger=v1, ledger-entry=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{
        definition-acceptance-rule=v1, work-judgment-acceptance-rule=v1,
        delivered-acceptance-rule=v1,
    },
}

When a conforming program gives whether a ledger entry E of one of the
kinds `task`, `plan`, `done`, `abandoned`, and `delivered` is accepted
at a point P of a valid ledger of a git repository that holds its ledger
objects, and no other process changes that git repository while the
program reads it:

- For a ledger entry E of the kind `done`, `abandoned`, or `delivered`,
  the program must give exactly one result, and only "accepted" or "not
  accepted": "accepted" when the acceptance rule of the kind of E holds
  for E at P, and "not accepted" when that acceptance rule does not hold
  for E at P.
- For a ledger entry E of the kind `task` or `plan`, the program must
  give either no result when the check of work-graph cycles exceeds
  limits of the program's own (and then must append nothing at P), or
  exactly one result, and only "accepted" or "not accepted": "accepted"
  when the acceptance rule of the kind of E holds for E at P, and "not
  accepted" when that acceptance rule does not hold for E at P.

### 5.5 The states of tasks

@req give-task-states=v1
@cites {
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    ontology#{ledger=v1, task=v1, work-item-state=v1},
    text#{conforming-program=v1, result=v1},
    #{work-item-id=v1, delivered-task-completion=v1},
}

When a conforming program gives the state of a task id t at a point P of
a valid ledger of a git repository that holds its ledger objects, and no
other process changes that git repository while the program reads it:

- When t names a task that exists at P, the program must give exactly
  one result, and only "open", "delivered", "done", or "abandoned": the
  state that `ontology#work-item-state` and `delivered-task-completion`
  give for t at P.
- When t names no task that exists at P, the program must give none of
  these four results.

### 5.6 The states of plans

@req give-plan-states=v1
@cites {
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    ontology#{ledger=v1, plan=v1, work-item-state=v1},
    text#{conforming-program=v1, result=v1},
    #{work-item-id=v1, delivered-task-completion=v1},
}

When a conforming program gives the state of a plan id p at a point P of
a valid ledger of a git repository that holds its ledger objects, and no
other process changes that git repository while the program reads it:

- When p names a plan that exists at P, the program must give exactly
  one result, and only "open", "done", or "abandoned": the state that
  `ontology#work-item-state` and `delivered-task-completion` give for p
  at P.
- When p names no plan that exists at P, the program must give none of
  these three results.

### 5.7 The readiness of tasks

@req give-task-readiness=v1
@cites {
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    ontology#{
        ledger=v1, task=v1, work-item-state=v1, met-wait=v1,
        ready-task=v1,
    },
    text#{conforming-program=v1, result=v1},
    #{work-item-id=v1, delivered-task-completion=v1},
}

When a conforming program gives whether a task id t is ready at a point
P of a valid ledger of a git repository that holds its ledger objects,
and no other process changes that git repository while the program reads
it:

- When t names a task that exists at P, the program must give exactly
  one result, and only "ready" or "not ready": "ready" when t is ready
  at P by `ontology#ready-task` and `delivered-task-completion`, and
  "not ready" otherwise.
- When t names no task that exists at P, the program must give neither
  result.

### 5.8 Accounted-for requirements

@req give-requirement-accounting=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1, extent-hash=v1, unreadable-file=v1},
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    ontology#{
        ledger=v1, tree=v1, declared-item=v1,
        requirement-accounted-for=v1, parameter=v1,
    },
    text#{conforming-program=v1, result=v1},
    #{delivered-task-completion=v1},
}

This requirement applies under a valid binding F of `file-readers`, a
binding N of `external-namespaces` for which a conforming program of the
design Identifiers gives the result "valid", and a set S of stopped
files of a tree T. When a conforming program gives, under F, N, and S,
whether an item r of the kind requirement of T is accounted for in T at
a point P of a valid ledger of a git repository that holds its ledger
objects, and no other process changes that git repository while the
program reads it, the program must give exactly one result, and only
"accounted for" or "not accounted for": "accounted for" when r is
accounted for in T at P by `ontology#requirement-accounted-for` and
`delivered-task-completion`, and "not accounted for" otherwise.

### 5.9 What a `done` ledger entry records

@req record-done-requirements=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1, extent-hash=v1, unreadable-file=v1},
    ontology#{
        ledger=v1, ledger-entry=v1, person=v1, task=v1, declared-item=v1,
        item-name=v1, item-revision=v1, work-item-definition=v1,
        work-item-state=v1, tree=v1, parameter=v1,
    },
    text#{conforming-program=v1, result=v1, code-point-order=v1, code-span=v1},
    #{work-item-id=v1, done-field=v1},
}

This requirement applies under a valid binding F of `file-readers`, a
binding N of `external-namespaces` for which a conforming program of the
design Identifiers gives the result "valid", and a set S of stopped
files of a tree T. When a conforming program appends a `done` ledger
entry E at a point P of a ledger to record that a person judged the work
of a task t finished in T under F, N, and S, all four of these rules
apply to E:

1. The value of `work-item` of E must be the task id of t.
2. The value of `requirements` of E must hold one requirement record for
   each distinct value of `req` among the promises of the current
   definition of t at P, in code point order of `req`, and no other
   element.
3. For each requirement record in `requirements` of E, when T has, under
   F, N, and S, exactly one declared item of the kind requirement whose
   name in T is the value of `req` of that requirement record, that
   requirement record must hold `label` with the current revision of
   that declared item in T and `hash` with the extent hash of that
   declared item in T under F, N, and S.
4. For each requirement record in `requirements` of E, when T has, under
   F, N, and S, no declared item of the kind requirement whose name in T
   is the value of `req` of that requirement record, or more than one
   such declared item, that requirement record must hold neither `label`
   nor `hash`.

## 6. Conformance

A program, or a part of a program, conforms to this design when it is a
conforming program of this design: when it meets every requirement of
section 5.

The vectors of this design are in the file
[`work.test-vectors.jsonl`](work.test-vectors.jsonl), in the same folder
as this design. The file is a test-vector set, as the specification
[`test-vectors`](sinter:data-forms#test-vectors=v1) of Data forms gives
it. A vector is an input and what a conforming program gives for it.
Each vector follows from the requirements and adds nothing to them. Each
group has a subsection below that gives the forms of that group, as the
term [`group-form-list`](sinter:data-forms#group-form-list=v1) gives
them.

### 6.1 Task hashes

@schema task-hash-vector=v1
@cites {
    rfc/8259,
    text#{conforming-program=v1, text=v1, character=v1, code-span=v1},
    files#{path-set=v1, valid-path-set=v1},
    data-forms#{
        json-value=v1, vector-line=v1, group-form-list=v1,
        vector-meaning=v1, test-vectors=v1,
    },
    #{task-promise=v1, task-hash=v1, give-task-hash=v1},
}

The group `task-hash` holds the vectors of the requirement
`give-task-hash`. Each vector gives a valid path set and a finite set of
distinct promise objects, and gives their task-hash pre-image and task
hash. The group uses no need, so these forms give no need names.

The JSON values, objects, arrays, and strings of this schema are as RFC
8259 defines them. Inside the members `input` and `values`, a text is a
JSON string whose characters are the characters of the text, in order.

- `input`: a JSON object with two members: `paths`, a JSON array of
  strings forming a valid path set, and `promises`, a JSON array of
  distinct promise objects.
- `result`: no vector of the group has this member; these forms name no
  question for `result`.
- `values`: a JSON object with two members: `pre-image`, the task-hash
  pre-image as a text; and `hash`, the task hash as a text.

When a conforming program gives the task-hash pre-image for the input of
a vector, it gives the text of `pre-image`, and no other text. When a
conforming program gives the task hash for the input of a vector, it
gives the text of `hash`, and no other text.

```
{"form":"#task-hash-vector=v1","group":"task-hash","input":{"paths":["src/billing/**"],"promises":[{"kind":"satisfies","req":"billing#limit"}]},"note":"one path and one satisfies promise","values":{"hash":"de291f3f7d292d0bb2d3153cb5c4ae0089b9db46852a8c23a3e2058982c63a13","pre-image":"{\"paths\":[\"src/billing/**\"],\"promises\":[{\"kind\":\"satisfies\",\"req\":\"billing#limit\"}]}"}}
```
