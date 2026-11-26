<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Work
@design work=v1
@cites {
    conformance=v1, text=v1, files=v1, data-forms=v1, identifiers=v1,
    ontology=v1, object-store=v1, packs=v1, changes=v1, findings=v1,
    documents=v1, ledger=v1, evidence=v1, approval=v1,
    rfc/5234, rfc/7405, gitdoc/git, gitdoc/git-commit,
    gitdoc/git-config, gitdoc/gitglossary, gitdoc/git-format-patch,
    gitdoc/git-am,
}
Conforming programs parse task and delivery lines from commit messages,
validate work records, derive task and plan states and work-graph
findings, evaluate task promises against trees and changes, and run the
default-branch delivery job.

Tasks and plans track units of work through canonical statements in
`.sinter/` and through `"delivered"` and `"progress"` observations on
the log branch. Commit messages connect proposed and merged changes to
task scopes, and the delivery job records merged deliveries and kept
declared items on the default branch.

## Definitions

### Work-item IDs

@term work-item-id=v1
@cites {
    ontology#{
        object-kind=v1, content-id=v1, work-item=v1, task=v1, plan=v1,
    },
    text#{text=v1, hex-digit=v1},
}

A **task ID** is a `text` that matches the content-ID form
(`content-id`) for the object kind word `task` (`object-kind`): `task:`
followed by 32 lowercase hex digits (`hex-digit`). A **plan ID** is a
`text` that matches the content-ID form for the object kind word `plan`:
`plan:` followed by 32 lowercase hex digits. The **work-item ID** of a
`task` or a `plan` is the work-item ID defined in `ontology#work-item`
(a task ID for a `task`, and a plan ID for a `plan`).

### Commit object name

@term commit-object-name=v1
@cites {
    gitdoc/gitglossary,
    rfc/5234,
    changes#commit=v1,
    text#{text=v1, hex-digit=v1, production=v1},
}

A **commit object name** is a `text` that matches the `production`
`commit-object-name` (written in ABNF per RFC 5234):

```abnf
commit-object-name  = 40hex-digit / 64hex-digit
```

The **commit object name** of a `commit` is the object name of that
commit object, as `gitglossary` defines object names, written in
lowercase hex digits (`hex-digit`).

### Scope hashes, promise resolution, and canonical latest definitions

@term task-scope=v1
@cites {
    rfc/5234,
    conformance#input=v1,
    ontology#{
        object=v1, object-kind=v1, content-hash=v1, content-id=v1,
        computed-identity=v1, scope-object=v1, work-item=v1,
        promise=v1, work-item-definition=v1, declared-item=v1,
        item-name=v1, encoding=v1, object-withdrawal=v1, topic=v1,
        definition-statement=v1, conflict=v1, work-item-state=v1,
        tree=v1, edge=v1,
    },
    object-store#{valid-object-file=v1, tree-object-store=v1},
    documents#kept-object-set=v1,
    approval#listed-person=v1,
    text#{text=v1, hex-digit=v1, production=v1, code-point-order=v1},
}

A **short scope hash** is a `text` that matches the `production`
`short-scope-hash` (written in ABNF per RFC 5234):

```abnf
short-scope-hash  = 6hex-digit
```

The **short scope hash** of a `"scope"` object `S` (`scope-object`) is
the first six lowercase hex digits (`hex-digit`) of the `content-hash`
of `S`.

For a non-empty ordered sequence of `tree`s `T_1, ..., T_n` (`n >= 1`)
whose object stores are valid (`tree-object-store`), with caller input
`K` (`kept-object-set`), a promise `edge` `e` (`promises-satisfies` or
`promises-verifies`, `promise`) of a `"scope"` object `S` with target
`content-id` `c` **resolves in `T_1, ..., T_n`, then `K`** (for one tree
`T`, **in `T` with `K`**; for two trees `T_1` and `T_2`, **in `T_1`,
then `T_2`, then `K`**) to a **promised requirement name** (`item-name`)
as follows:

- When `c` has object kind word `name` (`object-kind`): when a valid
  input of the run provides the `"name"` `computed-identity` object with
  content ID `c` or provides its key (`tree-object-store`), the promised
  requirement name of `e` is the member `name` of that `"name"` object.
  Otherwise, that `"name"` object is a missing part under
  `conformance#input`, and the promised requirement name of `e` is
  withheld.
- When `c` has object kind word `req` (`object-kind`): search the
  ordered sources `T_1, ..., T_n`, then `K` for a canonical `"req"`
  `object` `O` with content ID `c`, where:
  - each tree `T_i` contributes its declared items in the text
    `encoding` (`declared-item`) and the canonical objects of its valid
    store files (`valid-object-file`) not withdrawn by a counting void
    in `T_i` (`object-withdrawal`, under `listed-person`); and
  - `K` contributes its objects not withdrawn by a counting void in the
    last tree `T_n` (`object-withdrawal`, under `listed-person`).
  When at least one of those sources holds such an object `O` (taking
  the first source in order that holds one), the promised requirement
  name of `e` is the member `name` of `O`. Otherwise, `c` is a missing
  part under `conformance#input`, and the promised requirement name of
  `e` is withheld.

Each **resolved promise** of `S` in `T_1, ..., T_n`, then `K` (for one
tree `T`, **in `T` with `K`**; for two trees `T_1` and `T_2`, **in
`T_1`, then `T_2`, then `K`**) is a pair `(kind, req-name)`, where
`kind` is `satisfies` (for `promises-satisfies`) or `verifies` (for
`promises-verifies`) and `req-name` is the resolved promised requirement
name of that edge, deduplicated as a set of `(kind, req-name)` pairs.

A `"scope"` object `S` is a **withdrawn scope** in a `tree` `T` when a
counting void in `T` (`object-withdrawal`, under `listed-person`)
withdraws `S`.

When a `work-item` has a current definition in a `tree` `T`
(`work-item-definition`, `work-item-state`), its **canonical latest
definition** in `T` is the agreeing (`conflict`) latest counting
`definition-statement` (`"task-def"` or `"plan-def"`, `topic`) of that
work item in `T` whose `content-id` is smallest in `code-point-order`.

## Message lines

@spec message-lines=v1

Commit messages carry `Delivers:` and `Task:` lines that link commits to
tasks and task scopes.

### Definitions

#### Delivery line form

@schema delivery-line-form=v1
@cites {
    rfc/5234,
    rfc/7405,
    ontology#delivery-line=v1,
    text#{character=v1, text=v1, line=v1, hex-digit=v1, production=v1},
    #{work-item-id=v1, task-scope=v1},
}

This `production` (written in ABNF per RFC 5234 with the case-sensitive
strings of RFC 7405) defines the form of a `delivery-line`:

```abnf
delivery-line  = *SP %s"Delivers:" SP %s"task:" 32hex-digit SP
                 6hex-digit *( SP / HTAB / CR )
```

A `line` meets the schema `delivery-line-form` when, and only when, the
`text` of that line matches the production `delivery-line`. For a line
that meets `delivery-line-form`, the **task ID** (`work-item-id`) of
that delivery line is the text that `%s"task:" 32hex-digit` matches, and
the **short scope hash** (`task-scope`) of that delivery line is the
text that `6hex-digit` matches.

A `line` is a **malformed delivery line** when, and only when, the
`text` of that line starts with zero or more space (`U+0020`) or tab
(`U+0009`) `character`s followed by `Delivers:` (case-sensitive) and the
line does not meet the schema `delivery-line-form`.

@example Leading spaces match `*SP`, whereas a leading tab starts a
malformed delivery line, and a line with lowercase `delivers:` or with
`Delivers:` after other text is neither a delivery line nor a malformed
delivery line ([line](sinter:text#line=v1),
[work-item-id](sinter:#work-item-id=v1),
[task-scope](sinter:#task-scope=v1)):

- `    Delivers: task:d3e073f4bae981aa8a042274c335422f 220c2c` meets
  `delivery-line-form` (four leading spaces, as in a squashed commit).
- A leading tab (`U+0009`) before
  `Delivers: task:d3e073f4bae981aa8a042274c335422f 220c2c`, or
  `Delivers: task:d3e073f4bae981aa8a042274c335422f ABCDEF` (uppercase
  hex hash), is a malformed delivery line.
- `delivers: task:d3e073f4bae981aa8a042274c335422f 220c2c` and
  `Note: Delivers: bad` are neither valid nor malformed delivery lines.

#### Task line form

@schema task-line-form=v1
@cites {
    rfc/5234,
    rfc/7405,
    ontology#task-line=v1,
    text#{text=v1, line=v1, hex-digit=v1, production=v1},
    #work-item-id=v1,
}

This `production` (written in ABNF per RFC 5234 with the case-sensitive
strings of RFC 7405) defines the form of a `task-line`:

```abnf
task-line  = *SP %s"Task:" SP %s"task:" 32hex-digit *( SP / HTAB / CR )
```

A `line` meets the schema `task-line-form` when, and only when, the
`text` of that line matches the production `task-line`. For a line that
meets `task-line-form`, the **task ID** (`work-item-id`) of that task
line is the text that `%s"task:" 32hex-digit` matches.

### Returning commit message lines

@req parse-message-lines=v1
@cites {
    conformance#conforming-program=v1,
    changes#{commit=v1, message-text=v1},
    text#line=v1,
    #{delivery-line-form=v1, task-line-form=v1},
}

When a `conforming-program` returns the delivery lines, the malformed
delivery lines, or the task lines of a `commit`:

- When the commit's message has a `message-text`, each of those lists
  that the program returns must hold, each once and in line-number order
  (`line`), with no other line:
  - for **delivery lines**, every `line` of that text that meets
    `delivery-line-form`, with its 1-based line number, its task ID, and
    its short scope hash;
  - for **malformed delivery lines**, every `line` of that text that is
    a malformed delivery line (`delivery-line-form`), with its 1-based
    line number; and
  - for **task lines**, every `line` of that text that meets
    `task-line-form`, with its 1-based line number and its task ID.
- When the commit's message has no text (`message-text`), each of those
  lists that the program returns must hold no line for that commit.

### Test vectors

@schema message-lines-vector=v1
@cites {
    conformance#conforming-program=v1,
    changes#{commit=v1, message-text=v1},
    data-forms#{
        vector-line=v1, test-vector-set=v1, group-schema=v1,
        vector-meaning=v1,
    },
    text#{text=v1, line=v1},
    #{
        work-item-id=v1, task-scope=v1, delivery-line-form=v1,
        task-line-form=v1, parse-message-lines=v1,
    },
}

`message-lines-vector` is a `group-schema` for group `message-lines` in
[work.test-vectors.jsonl](work.test-vectors.jsonl) and tests
`parse-message-lines`. That file is a `test-vector-set` of `vector-line`
values whose meaning follows `vector-meaning`. Group `message-lines`
uses no `needs` and omits `result`.

| field | type | meaning |
|---|---|---|
| `input.text` | string (optional) | `message-text` (`text`) of the `commit`; when absent (`input` is `{}`), the commit's message has no text |
| `values.delivery-lines` | array of objects | lines meeting `delivery-line-form`, in line-number order (`line`) |
| `values.delivery-lines[].line` | integer (`>= 1`) | 1-based line number (`line`) of the delivery line |
| `values.delivery-lines[].task` | string | task ID (`work-item-id`) of the delivery line (`delivery-line-form`) |
| `values.delivery-lines[].hash` | string | short scope hash (`task-scope`) of the delivery line (`delivery-line-form`) |
| `values.malformed-delivery-lines` | array of integers (`>= 1`) | 1-based line numbers (`line`) of all malformed delivery lines (`delivery-line-form`), in line-number order |
| `values.task-lines` | array of objects | lines meeting `task-line-form`, in line-number order (`line`) |
| `values.task-lines[].line` | integer (`>= 1`) | 1-based line number (`line`) of the task line |
| `values.task-lines[].task` | string | task ID (`work-item-id`) of the task line (`task-line-form`) |

`input` holds no member other than `text`. `values` holds only
`delivery-lines`, `malformed-delivery-lines`, and `task-lines` (all
three required). Each object in `values.delivery-lines` holds only
`line`, `task`, and `hash` (all three required). Each object in
`values.task-lines` holds only `line` and `task` (both required).

When a `conforming-program` returns the delivery lines, the malformed
delivery lines, or the task lines of the vector's `commit` under
`parse-message-lines`, each list that the program returns holds the
lines listed for it in `values`, each once and in order, and no other
line.

@example Sample lines testing
[parse-message-lines](sinter:#parse-message-lines=v1) on mixed
[delivery lines](sinter:#delivery-line-form=v1), malformed delivery
lines, and [task lines](sinter:#task-line-form=v1) without a trailing
line feed, and on a commit message with no
[message-text](sinter:changes#message-text=v1)
([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#message-lines-vector=v1","group":"message-lines","input":{"text":"Summary\n\nTask: task:d3e073f4bae981aa8a042274c335422f\nDelivers: task:e1ade641a6990b8e16f8142d2cd54b01 56bf71\nDelivers: bad\nDelivers: task:d3e073f4bae981aa8a042274c335422f 220c2c"},"note":"mixed delivery lines, task lines, and malformed delivery lines in line-number order without final LF","values":{"delivery-lines":[{"hash":"56bf71","line":4,"task":"task:e1ade641a6990b8e16f8142d2cd54b01"},{"hash":"220c2c","line":6,"task":"task:d3e073f4bae981aa8a042274c335422f"}],"malformed-delivery-lines":[5],"task-lines":[{"line":3,"task":"task:d3e073f4bae981aa8a042274c335422f"}]}}
{"form":"#message-lines-vector=v1","group":"message-lines","input":{},"note":"commit message with no valid UTF-8 text gives no lines","values":{"delivery-lines":[],"malformed-delivery-lines":[],"task-lines":[]}}
```

## Work records

@spec records=v1

Task and plan definitions and their `"done"` and `"abandoned"` judgments
are statements in `.sinter/`. `"delivered"` and `"progress"`
observations stand on the log branch. Each work record kind has an
acceptance rule that determines whether a candidate record is accepted.

### Definitions

#### Definition acceptance rule

@atom definition-acceptance-rule=v1
@refines ledger#accepted-record=v1
@cites {
    ontology#{
        object=v1, object-kind=v1, content-id=v1, statement=v1,
        definition-statement=v1, work-item=v1, task=v1, plan=v1,
        scope-object=v1, void-statement=v1, object-withdrawal=v1,
        edge=v1, tree=v1, parameter=v1,
    },
    object-store#tree-object-store=v1,
    approval#{persons=v1, listed-person=v1},
    text#text=v1,
}

For a `tree` `T` whose `tree-object-store` is valid, a candidate
`definition-statement` (`statement`) `E` of kind `"task-def"` or
`"plan-def"`, and the optional `parameter` `approval#persons` (unbound
or bound), `definition-acceptance-rule` holds for `E` in `T` when, and
only when, each of these five conditions holds:

1. `E` meets its row of `ontology#object-kind`.
2. When `E` has `kind` equal to `"plan-def"`, the value of `name` of
   `E` is not the empty `text`. When `E` has `kind` equal to
   `"task-def"` and `E` holds no `tracks` `edge`, the value of `name`
   of `E` is not the empty `text`.
3. Let `w` be the `content-id` that the `about` `edge` of `E` names.
   `T` holds a canonical `"task"` `object` (`task`, when `E` has `kind`
   equal to `"task-def"`) or `"plan"` `object` (`plan`, when `E` has
   `kind` equal to `"plan-def"`) with content ID `w`.
4. When `E` has `kind` equal to `"task-def"`, let `s` be the
   `content-id` that the `scoped-by` `edge` of `E` names. At least one
   of these conditions holds in `T`:
   - `T` holds a canonical `"scope"` `object` (`scope-object`) with
     content ID `s` that meets its row of `ontology#object-kind` and
     whose `about` edge names `w`; or
   - `T` holds a counting void (`object-withdrawal`, under
     `approval#listed-person`) whose `withdraws` edge names `s`, whose
     member `withdrawn-kind` is `"scope"`, and that holds an `about`
     edge naming `w`.
5. For each `revises` `edge` of `E`, naming a `content-id` `r`, at
   least one of these conditions holds in `T`:
   - `T` holds a canonical `object` of the same `kind` as `E` with
     content ID `r` that meets its row of `ontology#object-kind` and
     whose `about` edge names `w`; or
   - `T` holds a counting void (`object-withdrawal`, under
     `approval#listed-person`) whose `withdraws` edge names `r`, whose
     member `withdrawn-kind` equals the `kind` of `E`, and that holds
     an `about` edge naming `w`.

Whether `definition-acceptance-rule` holds for `E` in `T` is withheld
when all three of these conditions hold:

- `E` meets conditions 1 to 3;
- no edge fails condition 4 or 5 outright (when `E` has `kind` equal to
  `"task-def"`, its `scoped-by` edge satisfies condition 4 or targets a
  content ID covered by the next bullet, and every `revises` edge of
  `E` satisfies condition 5 or targets a content ID covered by the next
  bullet); and
- for at least one target content ID `c` in condition 4 (`s`) or
  condition 5 (`r`), `T` holds no canonical object satisfying the first
  bullet of that condition for `c`, and `T` holds a `"void"` statement
  (`void-statement`) whose `withdraws` edge names `c`, whose member
  `withdrawn-kind` is `"scope"` (for condition 4) or equals the `kind`
  of `E` (for condition 5), whose `about` edge names `w`, and whose
  counting is withheld under an invalid binding of `approval#persons`
  (`approval#listed-person`).

Whether `definition-acceptance-rule` holds for `E` in `T` does not
depend on whether `T` holds any object named by a `part-of`,
`waits-for`, `tracks`, or `carries-out` edge of `E`, nor on whether a
`work-item` is abandoned or whether the `part-of` and `waits-for` edges
of definitions form a cycle.

#### Work-judgment acceptance rule

@atom work-judgment-acceptance-rule=v1
@refines ledger#accepted-record=v1
@cites {
    ontology#{
        object=v1, object-kind=v1, content-id=v1, statement=v1,
        definition-statement=v1, judgment=v1, task=v1, plan=v1,
        void-statement=v1, object-withdrawal=v1, topic=v1, edge=v1,
        tree=v1, parameter=v1,
    },
    object-store#tree-object-store=v1,
    approval#{persons=v1, listed-person=v1},
}

For a `tree` `T` whose `tree-object-store` is valid, a candidate
`judgment` (`statement`) `E` of kind `"done"` or `"abandoned"`, and the
optional `parameter` `approval#persons` (unbound or bound),
`work-judgment-acceptance-rule` holds for `E` in `T` when, and only
when, each of these four conditions holds:

1. `E` meets its row of `ontology#object-kind`.
2. Let `w` be the `content-id` that the `about` `edge` of `E` names,
   and let `k` be the object kind word of `w` (`"task"` for `"done"`;
   `"task"` or `"plan"` for `"abandoned"`). `T` holds a canonical
   `object` of kind `k` (`task` or `plan`) with content ID `w`.
3. Let `d` be the `content-id` that the `judges` `edge` of `E` names,
   and let `dk` be `"task-def"` when `k` is `"task"` and `"plan-def"`
   when `k` is `"plan"`. At least one of these conditions holds in `T`:
   - `T` holds a canonical `object` of kind `dk`
     (`definition-statement`) with content ID `d` that meets its row of
     `ontology#object-kind` and whose `about` edge names `w`; or
   - `T` holds a counting void (`object-withdrawal`, under
     `approval#listed-person`) whose `withdraws` edge names `d`, whose
     member `withdrawn-kind` is `dk`, and that holds an `about` edge
     naming `w`.
4. For each `revises` `edge` of `E`, naming a `content-id` `r`, at
   least one of these conditions holds in `T`:
   - `T` holds a canonical `object` of kind `"done"` or `"abandoned"`
     with content ID `r` that meets its row of `ontology#object-kind`
     and whose `about` edge names `w`; or
   - `T` holds a counting void (`object-withdrawal`, under
     `approval#listed-person`) whose `withdraws` edge names `r`, whose
     member `withdrawn-kind` is `"done"` or `"abandoned"`, and that
     holds an `about` edge naming `w`.

Whether `work-judgment-acceptance-rule` holds for `E` in `T` is
withheld when all three of these conditions hold:

- `E` meets conditions 1 and 2;
- no edge fails condition 3 or 4 outright (the `judges` edge of `E`
  satisfies condition 3 or targets a content ID covered by the next
  bullet, and every `revises` edge of `E` satisfies condition 4 or
  targets a content ID covered by the next bullet); and
- for at least one target content ID `c` in condition 3 (`d`) or
  condition 4 (`r`), `T` holds no canonical object satisfying the first
  bullet of that condition for `c`, and `T` holds a `"void"` statement
  (`void-statement`) whose `withdraws` edge names `c`, whose member
  `withdrawn-kind` is `dk` (for condition 3) or `"done"` or
  `"abandoned"` (for condition 4), whose `about` edge names `w`, and
  whose counting is withheld under an invalid binding of
  `approval#persons` (`approval#listed-person`).

Whether `work-judgment-acceptance-rule` holds for a `"done"` statement
`E` in `T` does not depend on whether `T` holds any `"req"` object
named by a `records` edge of `E`. Whether an accepted `"done"` or
`"abandoned"` statement counts in `T` follows `ontology#topic` and
`approval#listed-person`.

#### Delivered acceptance rule

@atom delivered-acceptance-rule=v1
@refines ledger#accepted-record=v1
@cites {
    ontology#{
        object-kind=v1, observation=v1, log-branch=v1, edge=v1,
        tree=v1,
    },
    #commit-object-name=v1,
}

For a candidate `"delivered"` `observation` `E` on the `log-branch`,
`delivered-acceptance-rule` reads only `E` and holds for `E` when, and
only when, all three of these conditions hold:

1. `E` meets its row of `ontology#object-kind`.
2. Each of the members `commit`, `merge`, and `head` of `E` is a
   `commit-object-name`.
3. When `E` holds no `observes` `edge`, `E` holds no `kept-satisfies`
   edge and no `kept-verifies` edge.

Sharing `commit`, `about`, and `hash` with another `"delivered"`
observation on the log branch does not prevent
`delivered-acceptance-rule` from holding for `E`. Whether an accepted
`"delivered"` observation decides a state in a `tree` follows
`ontology#observation`.

#### Progress acceptance rule

@atom progress-acceptance-rule=v1
@refines ledger#accepted-record=v1
@cites {
    ontology#{object-kind=v1, observation=v1, log-branch=v1},
    #commit-object-name=v1,
}

For a candidate `"progress"` `observation` `E` on the `log-branch`,
`progress-acceptance-rule` reads only `E` and holds for `E` when, and
only when, both of these conditions hold:

1. `E` meets its row of `ontology#object-kind`.
2. The member `head` of `E` is a `commit-object-name`.

### Returning work-record acceptance

@req give-work-record-acceptance=v1
@cites {
    conformance#conforming-program=v1,
    ontology#{
        record=v1, statement=v1, observation=v1, log-branch=v1,
        tree=v1, parameter=v1,
    },
    object-store#tree-object-store=v1,
    ledger#accepted-record=v1,
    approval#persons=v1,
    #{
        definition-acceptance-rule=v1,
        work-judgment-acceptance-rule=v1,
        delivered-acceptance-rule=v1,
        progress-acceptance-rule=v1,
    },
}

For a `tree` `T` whose `tree-object-store` is valid, the `parameter`
`approval#persons` (unbound or bound), and a candidate `record` `E`
that is a `statement` of kind `"task-def"`, `"plan-def"`, `"done"`, or
`"abandoned"`, when a conforming program returns whether `E` is
accepted in `T` (`accepted-record`), using `definition-acceptance-rule`
for `"task-def"` and `"plan-def"` and `work-judgment-acceptance-rule`
for `"done"` and `"abandoned"`:

- When the acceptance rule of the kind of `E` holds for `E` in `T` (and
  is not withheld under an invalid binding of `approval#persons`), the
  program must return `"accepted"` and no other acceptance result for
  `E`.
- When that acceptance rule does not hold for `E` in `T` (and is not
  withheld under an invalid binding of `approval#persons`), the program
  must return `"not accepted"` and no other acceptance result for `E`.
- When whether that acceptance rule holds for `E` in `T` is withheld
  under an invalid binding of `approval#persons`, the program must
  return neither `"accepted"` nor `"not accepted"` for `E`.

For a candidate `record` `E` that is an `observation` of kind
`"delivered"` or `"progress"` on the `log-branch`, when a conforming
program returns whether `E` is accepted (`accepted-record`), using
`delivered-acceptance-rule` for `"delivered"` and
`progress-acceptance-rule` for `"progress"`, the program must return
`"accepted"` and no other acceptance result when the acceptance rule of
the kind of `E` holds for `E`, and must return `"not accepted"` and no
other acceptance result otherwise.

### Test vectors

@schema acceptance-vector=v1
@cites {
    conformance#conforming-program=v1,
    text#text=v1,
    data-forms#{
        canonical-byte-sequence=v1, group-schema=v1, line-object=v1,
        test-vector-set=v1, vector-line=v1, vector-meaning=v1,
    },
    ontology#{
        content-id=v1, log-branch=v1, object=v1, object-kind=v1,
        observation=v1, parameter=v1, record=v1, statement=v1, tree=v1,
    },
    object-store#tree-object-store=v1,
    approval#persons=v1,
    #{
        definition-acceptance-rule=v1,
        work-judgment-acceptance-rule=v1,
        delivered-acceptance-rule=v1,
        progress-acceptance-rule=v1,
        give-work-record-acceptance=v1,
    },
}

`acceptance-vector` is a `group-schema` for group `acceptance` in
[work.test-vectors.jsonl](work.test-vectors.jsonl) and tests
`give-work-record-acceptance`. That file is a `test-vector-set` of
`vector-line` entries whose meaning follows `vector-meaning`. Group
`acceptance` uses no `needs` and omits `result`. Each vector represents
a `tree` `T` whose valid `tree-object-store` holds `input.objects`,
together with optional `log-branch` observations (`input.log`), the
optional `parameter` `approval#persons` (`input.persons`), and a
sequence of candidate work `record`s (`input.candidates`).

| field | type | meaning |
|---|---|---|
| `input.objects` | array of objects | canonical `object`s (`line-object` with no `id` member, meeting their rows of `ontology#object-kind`; each object's `content-id` derives from its `canonical-byte-sequence`) in the valid `tree-object-store` of `T` |
| `input.candidates` | array of objects | candidate work `record` objects (`line-object` with no `id` member and `kind` equal to `"task-def"`, `"plan-def"`, `"done"`, `"abandoned"`, `"delivered"`, or `"progress"`) |
| `input.log` | array of objects (optional) | canonical `observation` objects (`line-object` with no `id` member, meeting their rows of `ontology#object-kind`) on the `log-branch`; absent when the log branch holds no observations |
| `input.persons` | array of strings or string (optional) | array of `text` strings forming a valid binding of `approval#persons`, or the string `"invalid"` representing an invalid binding of `approval#persons`; absent when `approval#persons` is unbound |
| `values.accepted` | array of strings | one string per element of `input.candidates` in the same order: `"accepted"` when the applicable acceptance rule (`definition-acceptance-rule`, `work-judgment-acceptance-rule`, `delivered-acceptance-rule`, or `progress-acceptance-rule`) holds, `"not-accepted"` when that rule does not hold, or `"withheld"` when whether that rule holds is withheld under an invalid binding of `approval#persons` |

The objects `input` and `values` hold only the members listed in this
table. When a `conforming-program` returns whether a `statement` or
`observation` candidate in `input.candidates` is accepted under
`give-work-record-acceptance`, the program returns `"accepted"` for
`"accepted"`, `"not accepted"` for `"not-accepted"`, and neither
`"accepted"` nor `"not accepted"` for `"withheld"`.

@example Sample lines testing
[give-work-record-acceptance](sinter:#give-work-record-acceptance=v1)
for a [definition statement](sinter:ontology#definition-statement=v1)
whose deleted [scope object](sinter:ontology#scope-object=v1) depends
on a [void statement](sinter:ontology#void-statement=v1) under an
invalid binding of [persons](sinter:approval#persons=v1)
([definition-acceptance-rule](sinter:#definition-acceptance-rule=v1))
and for `"delivered"` and `"progress"`
[observations](sinter:ontology#observation=v1)
([delivered-acceptance-rule](sinter:#delivered-acceptance-rule=v1),
[progress-acceptance-rule](sinter:#progress-acceptance-rule=v1),
[commit-object-name](sinter:#commit-object-name=v1),
[vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#acceptance-vector=v1","group":"acceptance","input":{"candidates":[{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"scoped-by","to":"scope:220c2c3804849c2931b1a19666cedd6c"}],"kind":"task-def","name":"Enforce billing limit","v":1}],"objects":[{"kind":"task","nonce":"00000000000000000000000000000001","v":1},{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"withdraws","to":"scope:220c2c3804849c2931b1a19666cedd6c"}],"kind":"void","reason":"Scope contained a secret","v":1,"withdrawn-kind":"scope"}],"persons":"invalid"},"note":"task-def acceptance is withheld when its deleted scope relies on a void whose counting depends on invalid persons","values":{"accepted":["withheld"]}}
{"form":"#acceptance-vector=v1","group":"acceptance","input":{"candidates":[{"by":"Ada Lovelace <ada@example.com>","commit":"1111111111111111111111111111111111111111","edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"kept-satisfies","to":"req:e8db5e696c34e0701a9c0725effe7c1e"},{"kind":"observes","to":"task-def:3534f53b5f704a01e6efe76b0cbdb53d"}],"hash":"220c2c","head":"1111111111111111111111111111111111111111","kind":"delivered","merge":"1111111111111111111111111111111111111111","seq":1,"v":1},{"by":"Ada Lovelace <ada@example.com>","commit":"1111111111111111111111111111111111111111","edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"}],"hash":"220c2c","head":"1111111111111111111111111111111111111111","kind":"delivered","merge":"1111111111111111111111111111111111111111","seq":2,"v":1},{"by":"Ada Lovelace <ada@example.com>","commit":"1111111111111111111111111111111111111111","edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"kept-satisfies","to":"req:e8db5e696c34e0701a9c0725effe7c1e"}],"hash":"220c2c","head":"1111111111111111111111111111111111111111","kind":"delivered","merge":"1111111111111111111111111111111111111111","seq":3,"v":1},{"by":"Ada Lovelace <ada@example.com>","commit":"not-a-commit","edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"}],"hash":"220c2c","head":"1111111111111111111111111111111111111111","kind":"delivered","merge":"1111111111111111111111111111111111111111","seq":4,"v":1},{"by":"Ada Lovelace <ada@example.com>","commit":"1111111111111111111111111111111111111111","edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"observes","to":"task-def:3534f53b5f704a01e6efe76b0cbdb53d"}],"hash":"220c2c","head":"1111111111111111111111111111111111111111","kind":"delivered","merge":"1111111111111111111111111111111111111111","seq":5,"v":1},{"by":"Ada Lovelace <ada@example.com>","head":"1111111111111111111111111111111111111111","kind":"progress","seq":6,"v":1},{"by":"Ada Lovelace <ada@example.com>","head":"1234","kind":"progress","seq":7,"v":1}],"log":[{"by":"Ada Lovelace <ada@example.com>","commit":"1111111111111111111111111111111111111111","edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"kept-satisfies","to":"req:e8db5e696c34e0701a9c0725effe7c1e"},{"kind":"observes","to":"task-def:3534f53b5f704a01e6efe76b0cbdb53d"}],"hash":"220c2c","head":"1111111111111111111111111111111111111111","kind":"delivered","merge":"1111111111111111111111111111111111111111","seq":1,"v":1}],"objects":[]},"note":"delivered and progress acceptance: no kept-* without observes, commit-object-name check, duplicate delivered allowed","values":{"accepted":["accepted","accepted","not-accepted","not-accepted","accepted","accepted","not-accepted"]}}
```

## States and work graph

@spec states=v1

Accepted work definitions, work judgments, and log-branch observations
determine task states, plan states, task readiness, and requirement
accounting, while integrity checks flag withdrawn scopes, judgments of
replaced definitions, missing work-graph targets, cycles, and conflicts.
A program writes a `"done"` statement in `.sinter/` to record that a
person judged the work of a task finished.

### Definitions

#### Work statement and conflict checks

@atom work-statement-check=v1
@refines ledger#{
    unaccepted-statement-finding=v1, statement-conflict-finding=v1,
}
@cites {
    ontology#{
        statement=v1, definition-statement=v1, judgment=v1,
        observation=v1, conflict=v1, work-item-definition=v1,
        content-id=v1, tree=v1,
    },
    object-store#tree-object-store=v1,
    approval#{persons=v1, listed-person=v1},
    #{
        work-item-id=v1, definition-acceptance-rule=v1,
        work-judgment-acceptance-rule=v1, delivered-acceptance-rule=v1,
    },
}

For `ledger#unaccepted-statement-finding`, in a `tree` `T` whose
`tree-object-store` is valid, a `statement` `S` of kind `"task-def"` or
`"plan-def"` in the object store of `T` is unaccepted when
`definition-acceptance-rule` does not hold for `S` in `T`, and a
`statement` `S` of kind `"done"` or `"abandoned"` in the object store
of `T` is unaccepted when `work-judgment-acceptance-rule` does not hold
for `S` in `T`. When whether the acceptance rule holds for `S` is
withheld under an invalid binding of `approval#persons`, whether `T`
has an `unaccepted-statement` finding for `S` is withheld.

For `ledger#statement-conflict-finding`, a `tree` `T` whose
`tree-object-store` is valid has a `statement-conflict` finding for
each `conflict` of work `definition-statement`s (`"task-def"` or
`"plan-def"`, with the work-item ID (`work-item-id`) as subject), each
conflict of latest counting `"done"` and `"abandoned"` `judgment`s of
one task definition `D` (`work-item-definition`), and each conflict of a
completing `"delivered"` `observation` of `D` that decides a state in
`T` (`delivered-acceptance-rule`) with one or more latest counting
`"abandoned"` judgments of `D` (with the `content-id` of `D` as subject,
as `ledger#statement-conflict-finding` defines). When whether such a
conflict exists is withheld under `ontology#conflict`,
`ontology#observation`, or `approval#listed-person`, whether `T` has
that finding is withheld.

#### Findings of the class `withdrawn-scope`

@atom withdrawn-scope-finding=v1
@cites {
    conformance#own-store=v1,
    files#path=v1,
    ontology#{
        tree=v1, task=v1, scope-object=v1, work-item-state=v1,
        object-withdrawal=v1, edge=v1,
    },
    object-store#{tree-object-store=v1, valid-object-file=v1},
    approval#{persons=v1, listed-person=v1},
    documents#tree-finding=v1,
    findings#location=v1,
    #{work-item-id=v1, task-scope=v1},
}

For a `tree` `T` whose `tree-object-store` is valid (under
`approval#persons`), `T` has one `tree-finding` of the class
`withdrawn-scope` for each `task` `t` that exists in `T`, has a current
definition in `T` (`work-item-state`), and whose current definition
names with `scoped-by` (`edge`) a `scope-object` `S` that a counting
void in `T` withdraws (`object-withdrawal`, under
`approval#listed-person`). When whether `t` has a current definition or
whether a void withdrawing `S` counts is withheld under an invalid
binding of `approval#persons`, whether `T` has that finding is
withheld.

Its subject is the task ID (`work-item-id`) of `t`. Let `D` be the
canonical latest definition of `t` in `T` (`task-scope`). When `D`
stands in a `valid-object-file` of `.sinter/` of `T`, its `location` is
the valid `path` of that valid object file alone, with no span; when
`D` comes from a valid `own-store` with no file of `T`, that finding
has no location.

#### Findings of the class `replaced-definition-judgment`

@atom replaced-definition-judgment-finding=v1
@cites {
    conformance#own-store=v1,
    files#path=v1,
    ontology#{
        tree=v1, work-item=v1, judgment=v1, definition-statement=v1,
        work-item-definition=v1, topic=v1, content-id=v1, edge=v1,
    },
    object-store#{tree-object-store=v1, valid-object-file=v1},
    approval#{persons=v1, listed-person=v1},
    documents#tree-finding=v1,
    findings#location=v1,
}

For a `tree` `T` whose `tree-object-store` is valid (under
`approval#persons`), `T` has one `tree-finding` of the class
`replaced-definition-judgment` for each latest counting `"done"` or
`"abandoned"` `judgment` `J` in `T` (`ontology#topic`, under
`approval#listed-person`) whose `judges` `edge` names a definition
(`work-item-definition`) that is not a latest counting
`definition-statement` of `J`'s `work-item` (`about`) in `T`. When
whether `J` is a latest counting judgment or whether its judged
definition is a latest counting definition statement is withheld under
an invalid binding of `approval#persons`, whether `T` has that finding
is withheld.

Its subject is the `content-id` of `J`. When `J` stands in a
`valid-object-file` of `.sinter/` of `T`, its `location` is the valid
`path` of that valid object file alone, with no span; when `J` comes
from a valid `own-store` with no file of `T`, that finding has no
location.

#### Findings of the class `missing-wait`

@atom missing-wait-finding=v1
@cites {
    conformance#own-store=v1,
    files#path=v1,
    text#{character=v1, text=v1},
    ontology#{
        tree=v1, work-item=v1, wait=v1, work-item-state=v1,
        content-id=v1, edge=v1,
    },
    object-store#{tree-object-store=v1, valid-object-file=v1},
    approval#{persons=v1, listed-person=v1},
    documents#tree-finding=v1,
    findings#location=v1,
    #{work-item-id=v1, task-scope=v1},
}

For a `tree` `T` whose `tree-object-store` is valid (under
`approval#persons`), `T` has one `tree-finding` of the class
`missing-wait` for each pair `(w, y)` where `w` is a `work-item` with a
current definition `D` in `T` (`work-item-state`), `D` holds a
`waits-for` `edge` (`wait`) naming `content-id` `y`, and no task or
plan with work-item ID `y` exists in `T`. When whether `w` has a
current definition is withheld under an invalid binding of
`approval#persons` (`listed-person`), whether `T` has that finding is
withheld.

Its subject is the `text` formed by the work-item ID (`work-item-id`)
of `w`, then a space (U+0020, `character`), then `y`. Let `D0` be the
canonical latest definition of `w` in `T` (`task-scope`). When `D0`
stands in a `valid-object-file` of `.sinter/` of `T`, its `location` is
the valid `path` of that valid object file alone, with no span; when
`D0` comes from a valid `own-store` with no file of `T`, that finding
has no location.

#### Findings of the class `missing-plan`

@atom missing-plan-finding=v1
@cites {
    conformance#own-store=v1,
    files#path=v1,
    text#{character=v1, text=v1},
    ontology#{
        tree=v1, work-item=v1, plan=v1, work-item-state=v1,
        content-id=v1, edge=v1,
    },
    object-store#{tree-object-store=v1, valid-object-file=v1},
    approval#{persons=v1, listed-person=v1},
    documents#tree-finding=v1,
    findings#location=v1,
    #{work-item-id=v1, task-scope=v1},
}

For a `tree` `T` whose `tree-object-store` is valid (under
`approval#persons`), `T` has one `tree-finding` of the class
`missing-plan` for each pair `(w, p)` where `w` is a `work-item` with a
current definition `D` in `T` (`work-item-state`), `D` holds a
`part-of` `edge` naming `content-id` `p`, and no `plan` with plan ID
`p` exists in `T`. When whether `w` has a current definition is
withheld under an invalid binding of `approval#persons`
(`listed-person`), whether `T` has that finding is withheld.

Its subject is the `text` formed by the work-item ID (`work-item-id`)
of `w`, then a space (U+0020, `character`), then `p`. Let `D0` be the
canonical latest definition of `w` in `T` (`task-scope`). When `D0`
stands in a `valid-object-file` of `.sinter/` of `T`, its `location` is
the valid `path` of that valid object file alone, with no span; when
`D0` comes from a valid `own-store` with no file of `T`, that finding
has no location.

#### Findings of the class `work-under-abandoned-plan`

@atom work-under-abandoned-plan-finding=v1
@cites {
    conformance#own-store=v1,
    files#path=v1,
    ontology#{
        tree=v1, work-item=v1, task=v1, plan=v1, work-item-state=v1,
        observation=v1, log-branch=v1,
    },
    object-store#{tree-object-store=v1, valid-object-file=v1},
    approval#{persons=v1, listed-person=v1},
    documents#tree-finding=v1,
    findings#location=v1,
    #{work-item-id=v1, task-scope=v1},
}

For a `tree` `T` whose `tree-object-store` is valid (with `observation`s
on the `log-branch` that decide states in `T`, under
`approval#persons`), `T` has one `tree-finding` of the class
`work-under-abandoned-plan` for each `work-item` `w` with a current
definition in `T` that is an unfinished `task` (`"open"` or
`"delivered"`) or an `"open"` `plan` in `T` and lies under at least one
`plan` whose state in `T` is `"abandoned"` (`work-item-state`, under
`approval#listed-person`). When the state of `w`, whether `w` lies under
such a plan, or that plan's state is withheld in `T`, whether `T` has
that finding is withheld.

Its subject is the work-item ID (`work-item-id`) of `w`. Let `D0` be
the canonical latest definition of `w` in `T` (`task-scope`). When `D0`
stands in a `valid-object-file` of `.sinter/` of `T`, its `location` is
the valid `path` of that valid object file alone, with no span; when
`D0` comes from a valid `own-store` with no file of `T`, that finding
has no location.

#### Findings of the class `work-graph-cycle`

@atom work-graph-cycle-finding=v1
@cites {
    ontology#{
        tree=v1, work-item=v1, plan=v1, wait=v1,
        work-item-definition=v1, work-item-state=v1, observation=v1,
        log-branch=v1, edge=v1,
    },
    object-store#tree-object-store=v1,
    approval#{persons=v1, listed-person=v1},
    documents#tree-finding=v1,
    #work-item-id=v1,
}

For a `tree` `T` whose `tree-object-store` is valid (with `observation`s
on the `log-branch` that decide states in `T`, under `approval#persons`
and `approval#listed-person`), let `W` be the set of all `work-item`s
that exist in `T` and have a current definition (`work-item-definition`)
in `T` (`work-item-state`).

A **composition edge** of `T` is a pair `(p, x)` of a `plan` `p` in `W`
and a `work-item` `x` in `W` such that `x` is a part of `p` in `T`
(`work-item-state`: the current definition of `x` names `p` with
`part-of` (`edge`) and `x` is not abandoned in `T`; a work item stays a
part of `p` when `p` is abandoned).

The **combined work graph** of `T` holds these directed edges between
work items in `W`:

1. each composition edge `(p, x)` of `T`;
2. each pair `(x, y)` of work items in `W` such that the current
   definition of `x` names `y` with `waits-for` (`wait`);
3. each pair `(x, y)` of work items in `W` such that `x` is under a
   plan `p` in `W` (`work-item-state`) and the current definition of
   `p` names `y` with `waits-for`.

A work item `w` in `W` **lies on a work-graph cycle** in `T` when, and
only when, the combined work graph of `T` holds a finite sequence of
one or more directed edges `(u1, v1), ..., (uk, vk)` with `u1 = w`,
`vi = u(i + 1)` for each integer `i` from `1` to `k - 1`, and `vk = w`
(which includes every cycle of plans). When whether a work item `x` is
a part of a plan `p` is withheld in `T` (`work-item-state`), or whether
a work item has a current definition or is abandoned in `T` is withheld
under an invalid binding of `approval#persons` (`listed-person`),
whether any work item whose cycle membership depends on that fact lies
on a work-graph cycle in `T` is withheld.

`T` has one `tree-finding` of the class `work-graph-cycle` for each
work item `w` in `W` that lies on a work-graph cycle in `T`. When
whether `w` lies on a work-graph cycle in `T` is withheld, whether `T`
has that finding is withheld. Its subject is the work-item ID
(`work-item-id`) of `w`, and that finding has no location.

@example Suppose the current
[work-item definition](sinter:ontology#work-item-definition=v1) of a
[plan](sinter:ontology#plan=v1) `p` holds a `waits-for`
[edge](sinter:ontology#edge=v1) naming a [task](sinter:ontology#task=v1)
`t`, and the current definition of `t` holds a `part-of` edge naming
`p` while `t` is not abandoned
([work-item-state](sinter:ontology#work-item-state=v1)). The combined
work graph holds the composition edge `(p, t)`, the direct wait edge
`(p, t)`, and the inherited wait edge `(t, t)` (rule 3), with no edge
from `t` back to `p`. Therefore `t` lies on a work-graph cycle and
receives a `work-graph-cycle` finding, while `p` does not.

#### Findings of the class `missing-observed-definition`

@atom missing-observed-definition-finding=v1
@cites {
    ontology#{
        tree=v1, observation=v1, log-branch=v1, object-kind=v1,
        object-withdrawal=v1, content-id=v1, edge=v1,
    },
    object-store#tree-object-store=v1,
    ledger#{ledger-validity=v1, stored-ledger=v1},
    approval#{persons=v1, listed-person=v1},
    documents#tree-finding=v1,
    #delivered-acceptance-rule=v1,
}

For a `tree` `T` whose `tree-object-store` is valid and a valid
`log-branch` (`ledger-validity`, `stored-ledger`, under
`approval#persons`), `T` has one `tree-finding` of the class
`missing-observed-definition` for each accepted `"delivered"`
`observation` `E` on the log branch (`delivered-acceptance-rule`) such
that all three of these conditions hold:

- no counting void in `T` withdraws `E` (`object-withdrawal`, under
  `approval#listed-person`);
- `E` holds an `observes` `edge` naming `content-id` `d`; and
- `T` holds neither a valid canonical `"task-def"` object
  (`object-kind`) with content ID `d` nor a counting void in `T` whose
  `withdraws` edge names `d`.

When whether a void withdrawing `E` or `d` counts is withheld under an
invalid binding of `approval#persons`, whether `T` has that finding is
withheld. Its subject is the `content-id` of `E`, and that finding has
no location.

#### Findings of the class `missing-work-item-definition`

@atom missing-work-item-definition-finding=v1
@cites {
    conformance#own-store=v1,
    files#path=v1,
    ontology#{
        tree=v1, work-item=v1, task=v1, plan=v1,
        definition-statement=v1, work-item-state=v1, topic=v1,
    },
    object-store#{tree-object-store=v1, valid-object-file=v1},
    approval#{persons=v1, listed-person=v1},
    documents#tree-finding=v1,
    findings#location=v1,
    #work-item-id=v1,
}

For a `tree` `T` whose `tree-object-store` is valid (under
`approval#persons`), `T` has one `tree-finding` of the class
`missing-work-item-definition` for each `work-item` `w` (`task` or
`plan`) that exists in `T` (`work-item-state`) and has zero latest
counting `definition-statement`s in `T` (`ontology#topic`, under
`approval#listed-person`). A work item with two or more conflicting
latest definition statements receives `statement-conflict` rather than
`missing-work-item-definition`. When whether `w` has zero latest
counting definition statements is withheld under an invalid binding of
`approval#persons`, whether `T` has that finding is withheld.

Its subject is the work-item ID (`work-item-id`) of `w`. When the
`"task"` or `"plan"` nonce object of `w` stands in a `valid-object-file`
of `.sinter/` of `T`, its `location` is the valid `path` of that valid
object file alone, with no span; when that nonce object comes from a
valid `own-store` with no file of `T`, that finding has no location.

### Returning task and plan states

@req give-work-item-states=v1
@cites {
    conformance#{conforming-program=v1, dependence=v1},
    changes#{repository-read=v1, undisturbed-read=v1},
    object-store#tree-object-store=v1,
    ledger#{
        ledger-validity=v1, ledger-object=v1, stored-ledger=v1,
        intact-history=v1,
    },
    approval#{persons=v1, listed-person=v1},
    ontology#{
        task=v1, plan=v1, work-item-state=v1, tree=v1, parameter=v1,
    },
    #work-item-id=v1,
}

For a `tree` `T` whose `tree-object-store` is valid, a git repository
holding its ledger objects and history objects (`ledger-object`) with a
valid, intact log branch (`ledger-validity`, `intact-history`,
`stored-ledger`) read in an undisturbed `repository-read`
(`undisturbed-read`), the optional `parameter` `approval#persons`
(unbound or bound), and a work-item ID `w` (`work-item-id`, naming a
`task` or a `plan`), when a conforming program returns the state of `w`
in `T`:

- When `w` names a `task` or `plan` that exists in `T` and
  `ontology#work-item-state` (under `approval#listed-person`) assigns
  one state to `w` in `T`—and when `approval#persons` is bound to an
  invalid value, every valid binding and unbound `approval#persons`
  assign that same state (`dependence`)—the program must return exactly
  one result: `"open"`, `"delivered"`, `"done"`, or `"abandoned"` for a
  task, and `"open"`, `"done"`, or `"abandoned"` for a plan.
- When `w` names no task or plan that exists in `T`, when
  `ontology#work-item-state` assigns `w` no state in `T`, or when the
  state of `w` depends on an invalid binding of `approval#persons`, the
  program must return none of those results.

### Returning task readiness

@req give-task-readiness=v1
@cites {
    conformance#{conforming-program=v1, dependence=v1},
    changes#{repository-read=v1, undisturbed-read=v1},
    object-store#tree-object-store=v1,
    ledger#{
        ledger-validity=v1, ledger-object=v1, stored-ledger=v1,
        intact-history=v1,
    },
    approval#{persons=v1, listed-person=v1},
    ontology#{
        task=v1, work-item-state=v1, met-wait=v1, ready-task=v1,
        tree=v1, parameter=v1,
    },
    #work-item-id=v1,
}

For a `tree` `T` whose `tree-object-store` is valid, a git repository
holding its ledger objects and history objects (`ledger-object`) with a
valid, intact log branch (`ledger-validity`, `intact-history`,
`stored-ledger`) read in an undisturbed `repository-read`
(`undisturbed-read`), the optional `parameter` `approval#persons`
(unbound or bound), and a task ID `t` (`work-item-id`), when a
conforming program returns whether `t` is ready in `T`:

- When `t` names a `task` that exists in `T` and `ontology#ready-task`
  (under `work-item-state`, `met-wait`, and `approval#listed-person`)
  determines whether `t` is ready in `T`—and when `approval#persons` is
  bound to an invalid value, every valid binding and unbound
  `approval#persons` determine that same result (`dependence`)—the
  program must return exactly one result: `"ready"` when `t` is ready
  in `T`, and `"not ready"` when `t` is not ready in `T`.
- When `t` names no task that exists in `T`, when `ontology#ready-task`
  returns no result for `t` in `T`, or when the readiness of `t`
  depends on an invalid binding of `approval#persons`, the program must
  return neither result.

### Returning requirement accounting

@req give-requirement-accounting=v1
@cites {
    conformance#{conforming-program=v1, dependence=v1},
    changes#{repository-read=v1, undisturbed-read=v1},
    identifiers#external-namespaces=v1,
    documents#{
        file-readers=v1, kept-object-set=v1, tree-containment=v1,
    },
    object-store#tree-object-store=v1,
    ledger#{
        ledger-validity=v1, ledger-object=v1, stored-ledger=v1,
        intact-history=v1,
    },
    approval#{persons=v1, listed-person=v1},
    ontology#{
        tree=v1, declared-item=v1, containment=v1,
        requirement-accounted-for=v1, encoding=v1, parameter=v1,
    },
    #task-scope=v1,
}

For a `tree` `T` whose `tree-object-store` is valid, valid bindings of
the `parameter`s `file-readers` and `external-namespaces`, a valid
`kept-object-set` `K`, a git repository holding its ledger objects and
history objects (`ledger-object`) with a valid, intact log branch
(`ledger-validity`, `intact-history`, `stored-ledger`) read in an
undisturbed `repository-read` (`undisturbed-read`), optional
`approval#persons` (unbound or bound), and a `declared-item` `r` of the
kind requirement of `T` (in either `encoding`, with `containment` under
`tree-containment`), when a conforming program returns whether `r` is
accounted for in `T`:

- When `ontology#requirement-accounted-for` (under
  `approval#listed-person`, resolving `"scope"` promises in `T` with
  `K` per `task-scope` and `carries-out` targets through `T` and `K`)
  determines whether `r` is accounted for in `T`—and when
  `approval#persons` is bound to an invalid value, every valid binding
  and unbound `approval#persons` determine that same result
  (`dependence`)—the program must return exactly one result:
  `"accounted for"` when `r` is accounted for in `T`, and
  `"not accounted for"` when `r` is not accounted for in `T`.
- When `ontology#requirement-accounted-for` returns no result for `r`
  in `T` or when the result depends on an invalid binding of
  `approval#persons`, the program must return neither result.

### Writing `done` statements in `.sinter/`

@req write-done-statements=v1
@cites {
    conformance#conforming-program=v1,
    identifiers#external-namespaces=v1,
    documents#{file-readers=v1, kept-object-set=v1},
    object-store#{tree-object-store=v1, write-object-files=v1},
    approval#{persons=v1, listed-person=v1},
    ontology#{
        object-kind=v1, content-id=v1, statement=v1, judgment=v1,
        person=v1, agent=v1, task=v1, declared-item=v1, item-name=v1,
        scope-object=v1, work-item-state=v1, topic=v1, tree=v1,
        edge=v1, encoding=v1, parameter=v1,
        write-judgments-only-for-persons=v1,
    },
    #{
        work-item-id=v1, task-scope=v1,
        work-judgment-acceptance-rule=v1,
    },
}

For a working `tree` `T` whose `tree-object-store` is valid, valid
bindings of the `parameter`s `file-readers` and `external-namespaces`,
a valid `kept-object-set` `K`, optional `approval#persons` unbound or
bound to a valid binding, and a `task` `t` with a current definition in
`T` (`work-item-state`) whose `scope-object` `S` is not withdrawn in
`T` (`task-scope`) and whose promise edges all resolve in `T` with `K`,
when a conforming program writes in `.sinter/` of `T` a `statement` `E`
of the kind `"done"` to record that a `person` judged the work of `t`
finished in `T`, all five of these rules apply:

1. The program must write `E` only to record a decision that the
   `person` confirmed under `write-judgments-only-for-persons`. `E`
   must meet its row of `ontology#object-kind`, carry no member `agent`
   (`ontology#agent`), and satisfy `work-judgment-acceptance-rule` in
   `T` under `approval#persons`.
2. The one `about` `edge` of `E` must name the task ID (`work-item-id`)
   of `t`, and the one `judges` `edge` of `E` must name the `content-id`
   of the canonical latest definition of `t` in `T` (`task-scope`).
3. Each `revises` `edge` of `E` must name a latest counting `"done"` or
   `"abandoned"` `judgment` of `t` in `T` (`ontology#topic`, under
   `approval#listed-person`, never a withdrawn judgment). Before the
   `person` confirms the decision, the program must show that person
   each exact judgment that a `revises` edge of `E` names.
4. For each distinct requirement name `req-name` among the resolved
   promises of `S` in `T` with `K` (`task-scope`):
   - when `T` holds (across both encodings, `ontology#encoding`)
     exactly one `declared-item` `O` of the kind requirement whose
     `item-name` in `T` is `req-name`, `E` must hold a `records` edge
     naming the `content-id` of `O`;
   - when `T` holds zero or two or more declared items of the kind
     requirement whose `item-name` in `T` is `req-name`, `E` must hold
     no `records` edge for `req-name`.
   `E` must hold no other `records` edge.
5. The program must write `E` as a store object file in `.sinter/` of
   `T` under `object-store#write-object-files`.

### Returning work statement and graph findings

@req give-work-statement-findings=v1
@cites {
    conformance#conforming-program=v1,
    changes#{repository-read=v1, undisturbed-read=v1},
    object-store#tree-object-store=v1,
    ledger#{
        ledger-validity=v1, ledger-object=v1, stored-ledger=v1,
        intact-history=v1, unaccepted-statement-finding=v1,
        statement-conflict-finding=v1,
    },
    approval#persons=v1,
    documents#tree-finding=v1,
    ontology#{finding-class=v1, tree=v1, parameter=v1},
    #{
        work-statement-check=v1, withdrawn-scope-finding=v1,
        replaced-definition-judgment-finding=v1,
        missing-wait-finding=v1, missing-plan-finding=v1,
        work-under-abandoned-plan-finding=v1,
        work-graph-cycle-finding=v1,
        missing-observed-definition-finding=v1,
        missing-work-item-definition-finding=v1,
    },
}

For a `tree` `T` whose `tree-object-store` is valid, a git repository
holding its ledger objects and history objects (`ledger-object`) with a
valid, intact log branch (`ledger-validity`, `intact-history`,
`stored-ledger`) read in an undisturbed `repository-read`
(`undisturbed-read`), and the optional `parameter` `approval#persons`
(unbound or bound), when a conforming program returns the findings of
`T` of one of these ten `finding-class`es—`unaccepted-statement` (for
`"task-def"`, `"plan-def"`, `"done"`, and `"abandoned"`),
`statement-conflict` (for work definitions, work judgments, and
completing `"delivered"` observations with `"abandoned"` judgments),
`withdrawn-scope`, `replaced-definition-judgment`, `missing-wait`,
`missing-plan`, `work-under-abandoned-plan`, `work-graph-cycle`,
`missing-observed-definition`, and `missing-work-item-definition`—the
program must return once each finding (`tree-finding`,
`unaccepted-statement-finding`, or `statement-conflict-finding`) of
that class that `T` has, must return no finding whose condition is
withheld, and must return no other finding of that class (for
`unaccepted-statement` and `statement-conflict`, no other finding of
that class covered by `work-statement-check`).

### Test vectors

@schema states-vector=v1
@cites {
    conformance#conforming-program=v1,
    changes#{repository-read=v1, undisturbed-read=v1},
    text#{text=v1, code-point-order=v1},
    data-forms#{
        canonical-byte-sequence=v1, group-schema=v1, json-value=v1,
        line-object=v1, test-vector-set=v1, vector-line=v1,
        vector-meaning=v1,
    },
    identifiers#external-namespaces=v1,
    documents#{file-readers=v1, kept-object-set=v1},
    object-store#tree-object-store=v1,
    ledger#{
        ledger-validity=v1, ledger-object=v1, stored-ledger=v1,
        intact-history=v1, statement-conflict-finding=v1,
    },
    approval#persons=v1,
    findings#finding-subject=v1,
    ontology#{
        tree=v1, object=v1, task=v1, plan=v1, observation=v1,
        declared-item=v1, item-name=v1, content-id=v1, containment=v1,
        encoding=v1, parameter=v1,
    },
    #{
        work-item-id=v1, withdrawn-scope-finding=v1,
        replaced-definition-judgment-finding=v1,
        missing-wait-finding=v1, missing-plan-finding=v1,
        work-under-abandoned-plan-finding=v1,
        work-graph-cycle-finding=v1,
        missing-observed-definition-finding=v1,
        missing-work-item-definition-finding=v1,
        give-work-item-states=v1, give-task-readiness=v1,
        give-requirement-accounting=v1,
        give-work-statement-findings=v1,
    },
}

`states-vector` is a `group-schema` for group `states` in
[work.test-vectors.jsonl](work.test-vectors.jsonl) and tests
`give-work-item-states`, `give-task-readiness`,
`give-requirement-accounting`, and `give-work-statement-findings` (for
the nine finding classes listed in `values.findings`, excluding
`unaccepted-statement`). That file is a `test-vector-set` of
`vector-line` entries whose meaning follows `vector-meaning`.

Each vector stands for a `tree` `T` whose `tree-object-store` is valid,
a git repository holding its ledger objects and history objects
(`ledger-object`) with a valid, intact log branch (`ledger-validity`,
`intact-history`, `stored-ledger`) read in an undisturbed
`repository-read` (`undisturbed-read`), and valid bindings of the
`parameter`s `file-readers` and `external-namespaces`.

| field | type | meaning |
|---|---|---|
| `input.objects` | array of objects | canonical store `object`s (`line-object`s with no `id` member; each object's `content-id` derives from its `canonical-byte-sequence`) of `T` |
| `input.log` | array of objects | canonical `observation` objects (`line-object`s with no `id` member) of the valid, intact log branch |
| `input.kept` | array of objects (optional) | canonical kept `object`s (`kept-object-set`, `line-object`s with no `id` member); absent when empty |
| `input.persons` | array of strings or `"invalid"` (optional) | distinct `text` strings forming a valid binding of `approval#persons`, or `"invalid"` for an invalid binding; absent when `approval#persons` is unbound |
| `input.tasks` | array of strings | distinct queried task IDs (`work-item-id`) |
| `input.plans` | array of strings | distinct queried plan IDs (`work-item-id`) |
| `input.requirements` | array of objects | one object per `declared-item` of the kind requirement of `T` (in either `encoding`) |
| `input.requirements[].id` | string | `content-id` of that requirement's current declared-item object |
| `input.requirements[].name` | string | `item-name` of that requirement |
| `input.requirements[].spec` | string (optional) | `item-name` of the specification holding that requirement (`containment`), when one holds it |
| `input.requirements[].design` | string (optional) | `item-name` of the design holding that requirement (`containment`), when one holds it |
| `values.task-states` | object | map from each queried `task` ID in `input.tasks` that exists in `T` to `"open"`, `"delivered"`, `"done"`, `"abandoned"`, or `"withheld"` (the program returns no state); non-existent task IDs are absent |
| `values.plan-states` | object | map from each queried `plan` ID in `input.plans` that exists in `T` to `"open"`, `"done"`, `"abandoned"`, or `"withheld"` (the program returns no state); non-existent plan IDs are absent |
| `values.ready` | object | map from each queried `task` ID in `input.tasks` that exists in `T` to `true` (`"ready"`), `false` (`"not ready"`), or `"withheld"` (the program returns neither result); non-existent task IDs are absent |
| `values.accounted-for` | object | map from the `name` of each element of `input.requirements` to `true` (`"accounted for"`), `false` (`"not accounted for"`), or `"withheld"` (the program returns neither result) |
| `values.findings` | object | map from each of the nine finding-class slugs (`missing-observed-definition`, `missing-plan`, `missing-wait`, `missing-work-item-definition`, `replaced-definition-judgment`, `statement-conflict`, `withdrawn-scope`, `work-graph-cycle`, and `work-under-abandoned-plan`) to an array of `finding-subject` strings for all findings of that class that `T` has (`missing-observed-definition-finding`, `missing-plan-finding`, `missing-wait-finding`, `missing-work-item-definition-finding`, `replaced-definition-judgment-finding`, `statement-conflict-finding`, `withdrawn-scope-finding`, `work-graph-cycle-finding`, and `work-under-abandoned-plan-finding`), each once, in `code-point-order` |

The `json-value` objects `input`, `values`, each element of
`input.requirements`, and `values.findings` hold only the members
listed in this table. For each queried task ID, plan ID, requirement,
or listed finding class, a `conforming-program` returns the result that
`values` encodes, and returns no state, readiness, or accounting result
for a queried ID or requirement absent from `values` or mapped to
`"withheld"`.

@example Sample lines testing
[give-work-item-states](sinter:#give-work-item-states=v1),
[give-task-readiness](sinter:#give-task-readiness=v1),
[give-requirement-accounting](sinter:#give-requirement-accounting=v1),
and
[give-work-statement-findings](sinter:#give-work-statement-findings=v1)
for a completing `"delivered"`
[observation](sinter:ontology#observation=v1) and for an inherited wait
cycle under
[work-graph-cycle-finding](sinter:#work-graph-cycle-finding=v1)
([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#states-vector=v1","group":"states","input":{"log":[{"by":"Ada Lovelace <ada@example.com>","commit":"1111111111111111111111111111111111111111","edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"kept-satisfies","to":"req:e8db5e696c34e0701a9c0725effe7c1e"},{"kind":"observes","to":"task-def:55097fdd9b2845f5bb399e1253adf096"}],"hash":"220c2c","head":"1111111111111111111111111111111111111111","kind":"delivered","merge":"1111111111111111111111111111111111111111","seq":1,"v":1}],"objects":[{"kind":"task","nonce":"00000000000000000000000000000001","v":1},{"kind":"name","name":"billing#limit","v":1},{"edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"promises-satisfies","to":"name:2f5499ffd40584baddb649053699467a"}],"kind":"scope","paths":["src/billing/**"],"v":1},{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"scoped-by","to":"scope:220c2c3804849c2931b1a19666cedd6c"}],"kind":"task-def","name":"Enforce billing limit","v":1},{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"revises","to":"task-def:3534f53b5f704a01e6efe76b0cbdb53d"},{"kind":"scoped-by","to":"scope:220c2c3804849c2931b1a19666cedd6c"}],"kind":"task-def","name":"Enforce monthly billing limit","v":1}],"plans":["plan:e0aa2d11fc9b5cadac67a215e7eca7cf"],"requirements":[{"design":"billing","id":"req:e8db5e696c34e0701a9c0725effe7c1e","name":"billing#limit","spec":"billing#rules"},{"design":"auth","id":"req:f81dda3e02535fbba5eecb134ad19fff","name":"auth#login"}],"tasks":["task:d3e073f4bae981aa8a042274c335422f","task:e1ade641a6990b8e16f8142d2cd54b01"]},"note":"task becomes done via completing delivered matching current definition and accounts for requirement","values":{"accounted-for":{"auth#login":false,"billing#limit":true},"findings":{"missing-observed-definition":[],"missing-plan":[],"missing-wait":[],"missing-work-item-definition":[],"replaced-definition-judgment":[],"statement-conflict":[],"withdrawn-scope":[],"work-graph-cycle":[],"work-under-abandoned-plan":[]},"plan-states":{},"ready":{"task:d3e073f4bae981aa8a042274c335422f":false},"task-states":{"task:d3e073f4bae981aa8a042274c335422f":"done"}}}
{"form":"#states-vector=v1","group":"states","input":{"log":[],"objects":[{"kind":"plan","nonce":"00000000000000000000000000000101","v":1},{"kind":"task","nonce":"00000000000000000000000000000001","v":1},{"edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"}],"kind":"scope","paths":[],"v":1},{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"plan:e0aa2d11fc9b5cadac67a215e7eca7cf"},{"kind":"waits-for","to":"task:d3e073f4bae981aa8a042274c335422f"}],"kind":"plan-def","name":"Plan waiting for part","v":1},{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"part-of","to":"plan:e0aa2d11fc9b5cadac67a215e7eca7cf"},{"kind":"scoped-by","to":"scope:3b0eb5360b0fe31f896eb1597c618443"}],"kind":"task-def","name":"Task in p1","v":1}],"plans":["plan:e0aa2d11fc9b5cadac67a215e7eca7cf"],"requirements":[],"tasks":["task:d3e073f4bae981aa8a042274c335422f"]},"note":"inherited wait cycle: plan waiting for its own task puts the task on a work-graph-cycle","values":{"accounted-for":{},"findings":{"missing-observed-definition":[],"missing-plan":[],"missing-wait":[],"missing-work-item-definition":[],"replaced-definition-judgment":[],"statement-conflict":[],"withdrawn-scope":[],"work-graph-cycle":["task:d3e073f4bae981aa8a042274c335422f"],"work-under-abandoned-plan":[]},"plan-states":{"plan:e0aa2d11fc9b5cadac67a215e7eca7cf":"open"},"ready":{"task:d3e073f4bae981aa8a042274c335422f":false},"task-states":{"task:d3e073f4bae981aa8a042274c335422f":"open"}}}
```

## Promise evaluation

@spec promises=v1

Promise evaluation checks whether the citation edges and test evidence
of a tree keep the `satisfies` and `verifies` promises of each task's
scope. From those promise outcomes and the task's scope paths, a
program derives tree findings for unmet promises and for edges that
keep a promise outside the task's paths.

### Definitions

#### Finding promise outcome

@term finding-promise-outcome=v1
@cites {
    conformance#own-store=v1,
    data-forms#group-schema=v1,
    documents#{
        file-readers=v1, kept-object-set=v1, tree-edge=v1,
        vector-files=v1,
    },
    evidence#{
        give-promise-sources=v1, import=v1, report-file=v1,
        report-read-result=v1, tree-evidence=v1, tree-outcome=v1,
    },
    files#{path=v1, path-set-membership=v1},
    identifiers#external-namespaces=v1,
    object-store#tree-object-store=v1,
    ontology#{
        conformance-vector=v1, conformance-vector-group=v1,
        declared-item=v1, edge=v1, encoding=v1, item-name=v1,
        parameter=v1, promise=v1, satisfies-edge=v1, scope-object=v1,
        suspect-edge=v1, test=v1, tree=v1, vector-set=v1,
        verifies-edge=v1,
    },
    packs#{runner-settings=v1, test-runner=v1},
    #task-scope=v1,
}

This term applies for a `tree` `T` whose `tree-object-store` is valid,
valid bindings of the `parameter`s `file-readers`, `vector-files`, and
`external-namespaces`, a valid caller input `K` (`kept-object-set`),
the `tree-evidence` `V` for `T`, and, when `T` has evidence, valid
bindings of `runner-settings` for the `test-runner`s of the
`report-file`s of the `import`s of `V`.

An edge `e` of `T` (`tree-edge`, in either `encoding` or from a valid
`own-store`) is a **qualifying `satisfies` edge** in `T` for a resolved
`satisfies` promise `q = (satisfies, req-name)` (`task-scope`) when all
three of these conditions hold:

1. The edge `e` is of the kind `satisfies` and fits its kind
   (`ontology#edge`, `satisfies-edge`).
2. The cited item of `e` is the `declared-item` of the kind `req` in
   `T` whose `item-name` is `req-name`.
3. The edge `e` is not suspect in `T` (`suspect-edge`).

An edge `e` of `T` (`tree-edge`) is a **qualifying `verifies` edge** in
`T` for a resolved `verifies` promise `q = (verifies, req-name)`
(`task-scope`) when all three of these conditions hold:

1. The edge `e` comes from a citation in a text file of `T`, is of the
   kind `verifies`, and fits its kind (`ontology#edge`,
   `verifies-edge`).
2. The cited item of `e` is either the `declared-item` of the kind
   `req` in `T` whose `item-name` is `req-name`, or a
   `conformance-vector-group` or a `vector-set` (under `vector-files`)
   that holds a `conformance-vector` that states a vector and whose
   group has that item of the kind `req` among its requirements for
   that vector set's test-vector scope (`group-schema`).
3. The edge `e` is not suspect in `T` (`suspect-edge`).

For a `scope` object `S` (`scope-object`, not a withdrawn scope in `T`)
and a resolved promise `q = (kind, req-name)` of `S` in `T` with `K`
(`task-scope`), the **finding promise outcome** of `q` for `S` in `T`
under these bindings and inputs is `"known kept"`, `"known not kept"`,
`"not known"`, or no outcome:

- When `kind` is `satisfies`:
  - `"known kept"` when `T` holds at least one qualifying `satisfies`
    edge for `q` that comes from a citation in a text file of `T` whose
    valid `path` is in `paths` of `S` (`path-set-membership`,
    `ontology#promise`);
  - `"known not kept"` otherwise.
- When `kind` is `verifies` and `T` has evidence `V`:
  - `"known kept"` when at least one qualifying `verifies` edge for `q`
    whose text file has a valid `path` in `paths` of `S` has a `test`
    source with `tree-outcome` `"passed"` in `V`;
  - no outcome (never `"known not kept"`) when no such edge has
    `tree-outcome` `"passed"` in `V` and at least one qualifying
    `verifies` edge for `q` whose text file has a valid `path` in
    `paths` of `S` has a `test` source with no `tree-outcome` in `V`
    (for example, when an `import` has an invalid narrowing or a
    `report-file` lacks a `report-read-result`);
  - `"known not kept"` otherwise.
- When `kind` is `verifies` and `T` has no evidence:
  - `"not known"` when `T` holds at least one qualifying `verifies`
    edge for `q` whose text file has a valid `path` in `paths` of `S`;
  - `"known not kept"` otherwise.

When a promise edge's target cannot be resolved in `T` with `K`
(`task-scope`), or when a `verifies` edge's cited item is withheld as a
missing part (`tree-edge`), that promise has no finding promise
outcome. A finding promise outcome is not a result for whether a
`verifies` promise is kept in `T` in the sense of
`give-promise-sources`.

#### Findings of the class `promise-outside-paths`

@atom promise-outside-paths-finding=v1
@cites {
    approval#{listed-person=v1, persons=v1},
    conformance#own-store=v1,
    documents#{
        canonical-target=v1, kept-object-set=v1, origin=v1,
        origin-position=v1, position-order=v1, slice-location=v1,
        tree-edge=v1, tree-finding=v1,
    },
    evidence#{tree-evidence=v1, tree-outcome=v1},
    files#{path=v1, path-set-membership=v1},
    findings#{finding-subject=v1, location=v1},
    identifiers#citation-entry=v1,
    object-store#{tree-object-store=v1, valid-object-file=v1},
    ontology#{
        content-id=v1, declared-item=v1, edge=v1, encoding=v1,
        log-branch=v1, observation=v1, promise=v1, scope-object=v1,
        task=v1, test=v1, tree=v1, work-item-state=v1,
    },
    text#{character=v1, code-point-order=v1},
    #{
        definition-acceptance-rule=v1, delivered-acceptance-rule=v1,
        finding-promise-outcome=v1, task-scope=v1,
        work-item-id=v1, work-judgment-acceptance-rule=v1,
    },
}

This atom applies for a `tree` `T` whose `tree-object-store` is valid
(with `observation`s on the `log-branch` that decide states in `T`, and
`persons` unbound or bound under `listed-person`), under the bindings
and inputs of `finding-promise-outcome` (with valid `kept-object-set`
`K`).

For an unwithdrawn `scope` object `S` (`scope-object`) and a resolved
`promise` `q = (kind, req-name)` of `S` in `T` with `K` (`task-scope`),
an `edge` `e` of `T` (`tree-edge`, in either `encoding` or from a valid
`own-store`) is **known to keep `q` outside the paths of `S` in `T`**
when one of these two conditions holds:

- `kind` is `satisfies`, `e` is a qualifying `satisfies` edge in `T`
  for `q` (`finding-promise-outcome`), and either `e` comes from a
  citation in a text file of `T` whose valid `path` is not in `paths`
  of `S` (`path-set-membership`), or `e` is an edge of a
  `declared-item` in a `valid-object-file` of `.sinter/` of `T` or in a
  valid `own-store`.
- `kind` is `verifies`, `T` has evidence `V` (`tree-evidence`), `e` is
  a qualifying `verifies` edge in `T` for `q`
  (`finding-promise-outcome`) whose text file has a valid `path` not in
  `paths` of `S`, and the `test` source of `e` has `tree-outcome`
  `"passed"` in `V`.

In **outside-edge order**, an edge `e1` of `T` comes before another
edge `e2` of `T` when one of these three conditions holds:

1. `e1` stands in a file of `T` (a text file or a `valid-object-file`
   of `.sinter/`) and `e2` stands in no file of `T` (comes from a valid
   `own-store`).
2. Both `e1` and `e2` stand in files of `T`, and one of these four
   conditions holds:
   - the valid `path` of the file of `e1` comes before the valid `path`
     of the file of `e2` in `code-point-order`;
   - both files have the same valid `path`, `e1` is an edge of a
     `valid-object-file` of `.sinter/` (no span), and `e2` is a
     text-file edge;
   - both are text-file edges in the same file, and the
     `origin-position` of the slice of the `citation-entry` of `e1`
     comes before that of `e2` in `position-order`; or
   - both have the same file and origin position (or both are edges of
     the same `valid-object-file` of `.sinter/`), and the
     `canonical-target` (`content-id`) of `e1` comes before that of
     `e2` in `code-point-order`.
3. Neither `e1` nor `e2` stands in a file of `T`, and either the source
   `content-id` of `e1` comes before that of `e2` in
   `code-point-order`, or their source content IDs are equal and the
   `canonical-target` (`content-id`) of `e1` comes before that of `e2`
   in `code-point-order`.

`T` has one `tree-finding` of the class `promise-outside-paths` for
each pair of a `task` `t` that is unfinished in `T` (`work-item-state`,
under `definition-acceptance-rule`, `work-judgment-acceptance-rule`,
and `delivered-acceptance-rule`) whose current definition has an
unwithdrawn `scope-object` `S` and a resolved promise
`q = (kind, req-name)` of `S` in `T` with `K` that meets both of these
conditions:

1. The `finding-promise-outcome` of `q` for `S` in `T` is
   `"known not kept"`.
2. At least one edge of `T` is known to keep `q` outside the paths of
   `S` in `T`.

When `t` has no state in `T`, no current definition in `T`, or a
withdrawn scope in `T`, or when `q` cannot be resolved in `T` with `K`
(`task-scope`) or has no `finding-promise-outcome` in `T`, that finding
is withheld.

The `finding-subject` of that finding is the task ID of `t`
(`work-item-id`), then a space (U+0020, `character`), then `kind`
(`satisfies` or `verifies`), then a space (U+0020), then `req-name`.
Let `e0` be the first edge of `T` in outside-edge order that is known
to keep `q` outside the paths of `S` in `T`. The `location` of that
finding is:

- when `e0` comes from a `citation-entry` in a text file of `T`: the
  `slice-location` of the slice of that `citation-entry` in the text of
  that file (`origin`);
- when `e0` is an edge of a `declared-item` in a `valid-object-file` of
  `.sinter/` of `T`: the valid `path` of that valid object file alone,
  with no span (`location`);
- when `e0` comes from a valid `own-store`: no location.

#### Findings of the class `unmet-promise`

@atom unmet-promise-finding=v1
@cites {
    approval#{listed-person=v1, persons=v1},
    documents#{kept-object-set=v1, tree-finding=v1},
    findings#finding-subject=v1,
    object-store#tree-object-store=v1,
    ontology#{
        log-branch=v1, observation=v1, promise=v1, scope-object=v1,
        task=v1, tree=v1, work-item-state=v1,
    },
    text#character=v1,
    #{
        definition-acceptance-rule=v1, delivered-acceptance-rule=v1,
        finding-promise-outcome=v1, task-scope=v1,
        work-item-id=v1, work-judgment-acceptance-rule=v1,
    },
}

This atom applies for a `tree` `T` whose `tree-object-store` is valid
(with `observation`s on the `log-branch` that decide states in `T`, and
`persons` unbound or bound under `listed-person`), under the bindings
and inputs of `finding-promise-outcome` (with valid `kept-object-set`
`K`).

`T` has one `tree-finding` of the class `unmet-promise` for each pair
of a `task` `t` that is unfinished in `T` (`work-item-state`, under
`definition-acceptance-rule`, `work-judgment-acceptance-rule`, and
`delivered-acceptance-rule`) whose current definition has an
unwithdrawn `scope-object` `S` and a resolved `promise`
`q = (kind, req-name)` of `S` in `T` with `K` (`task-scope`) whose
`finding-promise-outcome` for `S` in `T` is `"known not kept"`.

When `t` has no state in `T`, no current definition in `T`, or a
withdrawn scope in `T`, or when `q` cannot be resolved in `T` with `K`
(`task-scope`) or has no `finding-promise-outcome` in `T`, that finding
is withheld. The `finding-subject` of that finding is the task ID of `t`
(`work-item-id`), then a space (U+0020, `character`), then `kind`
(`satisfies` or `verifies`), then a space (U+0020), then `req-name`.
That finding has no location.

### Returning promise findings

@req give-promise-findings=v1
@cites {
    approval#{listed-person=v1, persons=v1},
    changes#{repository-read=v1, undisturbed-read=v1},
    conformance#{
        conforming-program=v1, dependence=v1, reject-invalid-inputs=v1,
    },
    documents#tree-finding=v1,
    evidence#give-promise-sources=v1,
    ledger#{
        intact-history=v1, ledger-object=v1, ledger-validity=v1,
        stored-ledger=v1,
    },
    ontology#{finding-class=v1, promise=v1, tree=v1},
    #{
        finding-promise-outcome=v1, promise-outside-paths-finding=v1,
        unmet-promise-finding=v1,
    },
}

For a `tree` `T` under the bindings and inputs of
`finding-promise-outcome`, a git repository holding its ledger objects
and history objects (`ledger-object`) whose log branch is valid
(`ledger-validity`) and intact (`intact-history`) in an undisturbed
`repository-read` (`undisturbed-read`, `stored-ledger`), and `persons`
unbound or bound:

- When `persons` is unbound or bound to a valid binding, and a
  conforming program returns the findings of `T` of one of the
  `finding-class`es `promise-outside-paths` or `unmet-promise`, the
  program must return each `tree-finding` of that class that `T` has
  (`promise-outside-paths-finding`, `unmet-promise-finding`) once, must
  return no withheld finding, and must return no other finding of that
  class.
- When `persons` is bound to an invalid binding, and a conforming
  program returns the findings of `T` of one of those two classes, the
  program must return once each finding of that class that holds with
  no `dependence` on `persons` (`listed-person`), and must return no
  finding that depends on `persons` (`reject-invalid-inputs`).

A finding of either class is not a result for whether a `verifies`
`promise` is kept in `T` in the sense of `give-promise-sources`.

### Test vectors

@schema promise-findings-vector=v1
@cites {
    approval#persons=v1,
    conformance#{conforming-program=v1, own-store=v1},
    data-forms#{
        canonical-byte-sequence=v1, group-schema=v1, json-value=v1,
        line-object=v1, test-vector-set=v1, vector-line=v1,
        vector-meaning=v1,
    },
    documents#{
        canonical-target=v1, kept-object-set=v1, slice-location=v1,
        tree-edge=v1, tree-finding=v1,
    },
    evidence#{tree-evidence=v1, tree-outcome=v1},
    files#path=v1,
    findings#{finding-subject=v1, location=v1},
    identifiers#citation-entry=v1,
    object-store#{tree-object-store=v1, valid-object-file=v1},
    ontology#{
        conformance-vector-group=v1, content-id=v1, declared-item=v1,
        edge=v1, item-name=v1, object=v1, object-kind=v1,
        observation=v1, suspect-edge=v1, tree=v1, vector-set=v1,
    },
    text#{code-point-order=v1, position=v1, text=v1},
    #{
        finding-promise-outcome=v1, give-promise-findings=v1,
        promise-outside-paths-finding=v1, unmet-promise-finding=v1,
    },
}

`promise-findings-vector` is a `group-schema` for group
`promise-findings` in
[`work.test-vectors.jsonl`](work.test-vectors.jsonl) and tests
`give-promise-findings`. That file is a `test-vector-set` of
`vector-line` entries whose meaning follows `vector-meaning`. Group
`promise-findings` uses no `needs` and omits `result`.

Each vector stands for the inputs of `give-promise-findings` (under
`finding-promise-outcome`), where `input.objects` holds the valid
`tree-object-store` of `T`, `input.kept` holds the valid
`kept-object-set`, `input.log` holds the observations of the valid,
intact log branch, `input.tree` summarizes `T` and its `tree-evidence`,
and `input.persons` gives `persons`. JSON values follow `json-value`.

| field | type | meaning |
|---|---|---|
| `input.objects` | array of objects | canonical store `object`s (`line-object`s meeting `object-kind`, with no `id` member) of the valid `tree-object-store` of `T`; each object's `content-id` comes from its `canonical-byte-sequence` |
| `input.tree` | object | tree summary of `T` |
| `input.tree.has-evidence` | boolean | `true` when `T` has evidence (`tree-evidence`); `false` when `T` has no evidence |
| `input.tree.edges` | array of objects | `tree-edge` summaries of `T` |
| `input.tree.edges[].kind` | string | edge kind: `"satisfies"` or `"verifies"` |
| `input.tree.edges[].req` | string | requirement name (`item-name`) targeted directly or through a `vector-set` or `conformance-vector-group` |
| `input.tree.edges[].fits` | boolean | `true` when the edge fits its kind (`ontology#edge`) and is not suspect in `T` (`suspect-edge`); `false` otherwise |
| `input.tree.edges[].source` | string | edge origin: `"text"` for a citation in a text file of `T`, `"store"` for a `declared-item` in a `valid-object-file` of `.sinter/` of `T`, or `"own-store"` for a valid `own-store` |
| `input.tree.edges[].target-id` | string | `canonical-target` (`content-id`) of the edge |
| `input.tree.edges[].path` | string (optional) | valid `files#path` of the file of the edge; present when `source` is `"text"` or `"store"`, absent when `source` is `"own-store"` |
| `input.tree.edges[].line` | integer (`>= 1`, optional) | 1-based line number of the start `position` (`findings#location`) of the `slice-location` of that `citation-entry`; present when `source` is `"text"`, absent otherwise |
| `input.tree.edges[].column` | integer (`>= 1`, optional) | 1-based column of that start `position`; present when `source` is `"text"`, absent otherwise |
| `input.tree.edges[].end-line` | integer (`>= 1`, optional) | 1-based line number of the `position` after that `slice-location` (`findings#location`); present when `source` is `"text"`, absent otherwise |
| `input.tree.edges[].end-column` | integer (`>= 1`, optional) | 1-based column of that `position` after that `slice-location`; present when `source` is `"text"`, absent otherwise |
| `input.tree.edges[].source-id` | string (optional) | `content-id` of the `declared-item` object that is the source of the edge; present when `source` is `"own-store"`, absent otherwise |
| `input.tree.edges[].test-outcome` | string (optional) | for a `"verifies"` edge when `input.tree.has-evidence` is `true`: `"passed"`, `"failed"`, `"not run"`, or `"no-outcome"` (no `tree-outcome` in the evidence); when absent for a `"verifies"` edge while `has-evidence` is `true`, the test has neither `"passed"` nor `"no-outcome"` |
| `input.log` | array of objects (optional) | canonical `observation` objects (`line-object`s meeting `object-kind`, with no `id` member) of the log branch; absent when that log branch holds no observation |
| `input.kept` | array of objects (optional) | canonical objects (`line-object`s meeting `object-kind`, with no `id` member) of `kept-object-set`; absent when that set is empty |
| `input.persons` | array of strings or `"invalid"` (optional) | distinct `text` strings in `code-point-order` forming a valid binding of `persons`, or `"invalid"` for an invalid binding of `persons`; absent when `persons` is unbound |
| `values.findings.promise-outside-paths` | array of objects | `promise-outside-paths-finding` outputs of `T`, in `code-point-order` of `subject` |
| `values.findings.promise-outside-paths[].subject` | string | `finding-subject` of that finding |
| `values.findings.promise-outside-paths[].location` | object (optional) | `findings#location` of that finding; absent when the finding has no location (`own-store`) |
| `values.findings.promise-outside-paths[].location.path` | string | valid `files#path` of that `location` |
| `values.findings.promise-outside-paths[].location.start-line` | integer (`>= 1`, optional) | 1-based line number of the start `position` of that `slice-location`; present for a text edge, absent for a `.sinter/` store edge |
| `values.findings.promise-outside-paths[].location.start-column` | integer (`>= 1`, optional) | 1-based column of that start `position`; present for a text edge, absent for a `.sinter/` store edge |
| `values.findings.promise-outside-paths[].location.end-line` | integer (`>= 1`, optional) | 1-based line number of the `position` after that `slice-location`; present for a text edge, absent for a `.sinter/` store edge |
| `values.findings.promise-outside-paths[].location.end-column` | integer (`>= 1`, optional) | 1-based column of that `position` after that `slice-location`; present for a text edge, absent for a `.sinter/` store edge |
| `values.findings.unmet-promise` | array of strings | `finding-subject` values of all `unmet-promise-finding` outputs of `T`, each once, in `code-point-order` |

The objects `input`, `input.tree`, each element of `input.tree.edges`,
`values`, `values.findings`, each element of
`values.findings.promise-outside-paths`, and each `location` object
hold only the members listed for them in this table; canonical objects
in `input.objects`, `input.log`, and `input.kept` hold their own
canonical members under `object-kind`.

When a `conforming-program` returns the findings of `T` of either class
named in `values.findings` under `give-promise-findings`, the program
returns one `tree-finding` for each element of that member—with that
`location` when present and no location when absent for
`promise-outside-paths`, and no location for `unmet-promise`—and no
other finding of that class.

@example Sample lines testing
[give-promise-findings](sinter:#give-promise-findings=v1) for
outside-edge ordering in
[promise-outside-paths](sinter:#promise-outside-paths-finding=v1)
and for a `verifies` edge outside task paths with no evidence under
[finding-promise-outcome](sinter:#finding-promise-outcome=v1) and
[unmet-promise](sinter:#unmet-promise-finding=v1)
([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#promise-findings-vector=v1","group":"promise-findings","input":{"objects":[{"kind":"task","nonce":"00000000000000000000000000000001","v":1},{"kind":"name","name":"billing#limit","v":1},{"edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"promises-satisfies","to":"name:2f5499ffd40584baddb649053699467a"}],"kind":"scope","paths":["src/billing/**"],"v":1},{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"scoped-by","to":"scope:220c2c3804849c2931b1a19666cedd6c"}],"kind":"task-def","name":"Enforce billing limit","v":1}],"tree":{"edges":[{"fits":true,"kind":"satisfies","req":"billing#limit","source":"own-store","source-id":"design:bb59ef75ae532d2bbf2d5390cb86ad8d","target-id":"name:2f5499ffd40584baddb649053699467a"},{"column":3,"end-column":25,"end-line":4,"fits":true,"kind":"satisfies","line":4,"path":"src/other/b.ml","req":"billing#limit","source":"text","target-id":"name:2f5499ffd40584baddb649053699467a"},{"column":1,"end-column":20,"end-line":2,"fits":true,"kind":"satisfies","line":2,"path":"src/other/a.ml","req":"billing#limit","source":"text","target-id":"name:2f5499ffd40584baddb649053699467a"}],"has-evidence":true}},"note":"outside-edge order picks earliest pathed edge before other paths and own-store edges","values":{"findings":{"promise-outside-paths":[{"location":{"end-column":20,"end-line":2,"path":"src/other/a.ml","start-column":1,"start-line":2},"subject":"task:d3e073f4bae981aa8a042274c335422f satisfies billing#limit"}],"unmet-promise":["task:d3e073f4bae981aa8a042274c335422f satisfies billing#limit"]}}}
{"form":"#promise-findings-vector=v1","group":"promise-findings","input":{"objects":[{"kind":"task","nonce":"00000000000000000000000000000002","v":1},{"kind":"name","name":"billing#limit","v":1},{"edges":[{"kind":"about","to":"task:e1ade641a6990b8e16f8142d2cd54b01"},{"kind":"promises-verifies","to":"name:2f5499ffd40584baddb649053699467a"}],"kind":"scope","paths":["test/billing/**"],"v":1},{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"task:e1ade641a6990b8e16f8142d2cd54b01"},{"kind":"scoped-by","to":"scope:56bf71390007ccb491b7eedf7fc754e9"}],"kind":"task-def","name":"Verify billing limit","v":1}],"tree":{"edges":[{"column":1,"end-column":22,"end-line":3,"fits":true,"kind":"verifies","line":3,"path":"test/other/x_test.ml","req":"billing#limit","source":"text","target-id":"name:2f5499ffd40584baddb649053699467a"}],"has-evidence":false}},"note":"verifies edge outside paths with no evidence gives unmet-promise and no promise-outside-paths","values":{"findings":{"promise-outside-paths":[],"unmet-promise":["task:e1ade641a6990b8e16f8142d2cd54b01 verifies billing#limit"]}}}
```

## Change checks

@spec change-checks=v1

Change checks compare a proposed or merged change with the delivery
lines and task lines in its commit messages and with the scopes of its
tasks. Commit-level checks need only the commits and the head tree.
Base-dependent checks also need a base tree.

### Parameters

#### Exempt paths

@schema exempt-paths=v1
@cites {
    files#path-set=v1,
    ontology#parameter=v1,
}

A binding of the `parameter` `exempt-paths` is a `path-set`. A binding
meets the schema `exempt-paths` when, and only when, that path set is
valid.

### Definitions

#### Change inputs, host adapters, and local adapters

@term change-input=v1
@cites {
    gitdoc/git-format-patch,
    gitdoc/git-am,
    ontology#{
        tree=v1, default-branch=v1, parameter=v1, delivery-line=v1,
        task-line=v1, log-branch=v1,
    },
    changes#{
        commit=v1, shallow-commit=v1, working-tree=v1, commit-file=v1,
        message-text=v1, commit-change=v1, change-base=v1, reach=v1,
        default-branch-name=v1,
    },
    ledger#base-comparison=v1,
}

A **change input** consists of three parts, kept apart:

1. the checked head `tree` `H`;
2. an optional base `tree` `B` (present when the change has a base, and
   absent when the change has no base); and
3. the sequence or set of `commit`s of the change, whose commit messages
   (`message-text`) carry delivery lines (`ontology#delivery-line`) and
   task lines (`ontology#task-line`) (kept apart from `H`, so `H` can be
   a `working-tree`, a branch tip tree, or a received merge result
   commit's tree).

Two kinds of change-input source — a **host adapter** and a **local
adapter** — supply change inputs:

- **GitHub host adapter:** a host adapter for GitHub pull requests. It
  takes the pull request's commits, its base commit (supplying `B`), and
  the merge result commit received from the host (supplying `H`).
- **Local adapter:** a local adapter for local work that takes either a
  local branch (or `working-tree`) or a patch series in the format that
  `git-format-patch` produces and `git-am` applies. A local adapter
  input is valid when, and only when, it names a branch or the working
  tree of the git repository, or it is a patch series that `git-am`
  applies, in order and with no conflict, to the base commit that the
  input names.

For a `commit` `h` on a branch under a valid binding `D` of the
`parameter` `default-branch-name`, `H` is the tree of `h`
(`commit-file`) or the checked `working-tree` or merge-result tree, `B`
comes from `ledger#base-comparison` (the tree of the caller-named base
commit, or otherwise the tree of `changes#change-base`), and the commits
of the change are `changes#commit-change` under `D` (or the commits of
the patch series). For a merged `commit` `h` on the `default-branch`,
`H` is the tree of `h` (`commit-file`), `B` comes from
`ledger#base-comparison` (which never reads the `log-branch`, and which
leaves `B` absent when the caller names no base commit and `h` is a
`shallow-commit`), and the commits of the change are the commits that
`h` reaches (`changes#reach`) and the base commit does not reach (or
`{h}` when `h` has no parent or the change has no base).

#### Counting delivery lines

@term counting-delivery-line=v1
@cites {
    ontology#{
        tree=v1, task=v1, scope-object=v1, work-item-state=v1,
        object-withdrawal=v1,
    },
    object-store#tree-object-store=v1,
    approval#{persons=v1, listed-person=v1},
    #{work-item-id=v1, delivery-line-form=v1, task-scope=v1},
}

For a `tree` `T` whose `tree-object-store` is valid (under
`approval#persons`), a line that meets `delivery-line-form` **counts in
`T`** when, and only when, all three of these conditions hold:

1. The task ID (`work-item-id`) of that delivery line names a `task`
   that exists in `T` and has a current definition `D` in `T`
   (`work-item-state`).
2. No counting void in `T` (`object-withdrawal`, under `listed-person`)
   withdraws the `scope` object (`scope-object`) `S` that `D` names with
   `scoped-by`.
3. The short scope hash of that delivery line equals the short scope
   hash of `S` (`task-scope`).

When the task ID names a task that exists in `T` and either that task
has no current definition in `T` (missing definition, conflict, or
withheld under an invalid binding of `approval#persons`) or a counting
void in `T` withdraws `S` (or whether a void withdrawing `S` counts is
withheld under an invalid binding of `approval#persons`), whether that
delivery line counts in `T` is withheld. When the task ID names no task
that exists in `T`, that delivery line does not count in `T`.

#### Files that only re-pin

@term repin-only-file=v1
@cites {
    ontology#{tree=v1, item-revision=v1, parameter=v1},
    files#path=v1,
    changes#line-text=v1,
    identifiers#{
        citation=v1, citation-line=v1, citation-entry=v1, link=v1,
        destination=v1, inline-citation=v1, inline-destination=v1,
        match=v1, label=v1, revision=v1, external-namespaces=v1,
    },
    documents#{
        file-readers=v1, read-file=v1, unreadable-file=v1,
        accepted-input=v1, example-block=v1, origin=v1, tree-edge=v1,
    },
    text#{text=v1, line=v1, slice=v1, valid-utf-8=v1},
}

This term applies to a valid `path` `f`, a base `tree` `B`, a `tree`
`T`, and valid bindings `F` of the `parameter` `file-readers` and `N` of
`external-namespaces`.

In a `tree` `A` under `F` and `N`, a **citation pin** of `f` in `A` is
either a tag-line citation pin or an inline citation pin:

- **Tag-line citation pin:** the `slice` matched by `label` in the
  `match` by `citation-line` of a `citation-entry` of an
  `accepted-input` of `A` that is a `citation`, whose file is the file
  of `A` at `f`, and that does not lie on any file line of an
  `example-block` — namely, the `label` of `name "=" label`, of
  `name "=" revision` when `revision` uses `label`, or of
  `part-name "=" label` or `part-name "=" revision` when `revision` uses
  `label`. By `origin`, its characters come from contiguous 1-based
  character indices (`text`) on one `line` `k` of the file at `f`; that
  `slice` of `line-text` `k` of `f` in `A` is its **pin slice**, and the
  `tree-edge` of `A` produced by that `citation-entry` is its **edge**.
- **Inline citation pin:** an inline citation pin comes from an
  `accepted-input` of `A` whose file is the file of `A` at `f` and that
  meets all three of these conditions:

  1. It is an `inline-citation` written as an inline link or an
     autolink (`link`). An inline citation inside an `example-block`
     counts.
  2. Its `destination` matches `inline-destination` with a `revision`
     that uses `label`.
  3. In the file, the characters of the link destination end with the
     characters of that `label`, with no backslash escape or character
     reference among them.

  By `origin`, those `label` characters come from contiguous 1-based
  character indices (`text`) on one `line` `k` of the file at `f`. That
  `slice` of `line-text` `k` is the **pin slice** of the inline citation
  pin. The `cites` `tree-edge` of that inline citation is its **edge**.

For each 1-based line number `k` of `f` in `A`, the citation pins of `f`
in `A` on line `k` have disjoint pin slices. Ordering them by the start
boundaries (`slice`) of their pin slices on `line-text` `k` produces `m`
citation pins (`m >= 0`) whose pin slices divide `line-text` `k` into
`m + 1` **frame texts**: the text before the first pin slice, the text
between each two successive pin slices, and the text after the last pin
slice (or the whole `line-text` `k` when `m = 0`).

The valid `path` `f` **only re-pins** between `B` and `T` under `F` and
`N` when, and only when, all three of these conditions hold:

1. Both `B` and `T` hold a file at `f`, and that file is a readable
   `read-file` of `B` and a readable `read-file` of `T` under `F`
   (`unreadable-file`, so each file's content is `valid-utf-8`).
2. The count of `line-text`s of `f` in `B` equals the count of
   `line-text`s of `f` in `T`.
3. For each integer `k` from 1 to that count such that `line-text` `k`
   of `f` in `B` is not equal (`text`) to `line-text` `k` of `f` in `T`:
   - The count `m` of citation pins of `f` in `B` on line `k` equals the
     count of citation pins of `f` in `T` on line `k`.
   - For each integer `i` from 0 to `m`, the `i`-th frame text of line
     `k` of `f` in `B` is equal (`text`) to the `i`-th frame text of
     line `k` of `f` in `T`.
   - For each integer `j` from 1 to `m` such that the text of the `j`-th
     pin slice of line `k` in `B` is not equal to the text of the `j`-th
     pin slice of line `k` in `T`, the edge of the `j`-th citation pin
     of line `k` in `T` has a cited item in `T` under `F` and `N`, and
     the text of that pin slice in `T` is the current revision
     (`item-revision`) of that cited item in `T`.

@example Suppose `docs/designs/billing.md` has one changed line inside a
trailing [example block](sinter:documents#example-block=v1), updating an
[inline citation](sinter:identifiers#inline-citation=v1) from
`@example See [limit](sinter:billing#limit=v1).` in `B` to
`@example See [limit](sinter:billing#limit=v2).` in `H`, where
`billing#limit` has current revision `v2` in `H`
([item-revision](sinter:ontology#item-revision=v1)). Both lines share
the two frame texts `@example See [limit](sinter:billing#limit=` and
`).`, and the sole pin slice changes from `v1` to `v2`, matching the
current revision of the cited item of its
[tree edge](sinter:documents#tree-edge=v1) in `H`. Therefore,
`docs/designs/billing.md` only re-pins between `B` and `H`.

#### Findings of the class `malformed-delivery`

@atom malformed-delivery-finding=v1
@cites {
    ontology#{finding-class=v1, tree=v1},
    changes#{commit=v1, message-text=v1},
    documents#tree-finding=v1,
    findings#finding-subject=v1,
    text#{line=v1, decimal-numeral=v1},
    #{commit-object-name=v1, delivery-line-form=v1, change-input=v1},
}

For a `change-input` with checked head `tree` `H`, `H` has one
`tree-finding` of the `finding-class` `malformed-delivery` for each pair
of a `commit` `c` of the change whose message has a text
(`message-text`) and a `line` `l` (with 1-based line number `k`) of that
text such that `l` is a malformed delivery line (`delivery-line-form`).

The `finding-subject` of that finding is the `commit-object-name` of
`c`, then `@L`, then the `decimal-numeral` of `k`. That finding has no
location.

#### Findings of the class `stale-delivery`

@atom stale-delivery-finding=v1
@cites {
    ontology#{finding-class=v1, tree=v1, scope-object=v1},
    object-store#tree-object-store=v1,
    approval#{persons=v1, listed-person=v1},
    changes#{commit=v1, message-text=v1},
    documents#tree-finding=v1,
    findings#finding-subject=v1,
    text#{line=v1, decimal-numeral=v1},
    #{
        commit-object-name=v1, delivery-line-form=v1, change-input=v1,
        counting-delivery-line=v1,
    },
}

For a `change-input` with checked head `tree` `H` whose
`tree-object-store` is valid (under `approval#persons`), `H` has one
`tree-finding` of the `finding-class` `stale-delivery` for each pair of
a `commit` `c` of the change whose message has a text (`message-text`)
and a `line` `l` (with 1-based line number `k`) of that text such that
`l` meets `delivery-line-form` and does not count in `H`
(`counting-delivery-line`).

When whether `l` counts in `H` is withheld (including when its task has
no current definition or a withdrawn `scope-object`, or under an invalid
binding of `approval#persons` per `listed-person`), whether `H` has that
finding is withheld. The `finding-subject` of that finding is the
`commit-object-name` of `c`, then `@L`, then the `decimal-numeral` of
`k`. That finding has no location.

#### Findings of the class `delivery-on-unmet-task`

@atom delivery-on-unmet-task-finding=v1
@cites {
    ontology#{
        tree=v1, task=v1, scope-object=v1, work-item-state=v1,
        promise=v1, finding-class=v1,
    },
    approval#{persons=v1, listed-person=v1},
    changes#{commit=v1, message-text=v1},
    documents#{kept-object-set=v1, tree-finding=v1},
    evidence#give-promise-sources=v1,
    findings#finding-subject=v1,
    text#line=v1,
    #{
        work-item-id=v1, delivery-line-form=v1, task-scope=v1,
        finding-promise-outcome=v1, change-input=v1,
        counting-delivery-line=v1,
    },
}

For a `change-input` with checked head `tree` `H` under the bindings and
inputs of `finding-promise-outcome` (with valid `kept-object-set` `K`)
and `approval#persons` (unbound or bound), `H` has one `tree-finding` of
the `finding-class` `delivery-on-unmet-task` for each `task` `t` that
exists in `H` (`work-item-state`) and meets both of these conditions:

1. At least one `line` of the `message-text` of a `commit` of the change
   meets `delivery-line-form`, has the task ID (`work-item-id`) of `t`
   as its task ID, and counts in `H` (`counting-delivery-line`).
2. At least one resolved `promise` of the `scope-object` of the current
   definition of `t` in `H` with `K` (`task-scope`) has the finding
   promise outcome (`finding-promise-outcome`) `"known not kept"` in `H`
   under those bindings and inputs.

When whether a delivery line for `t` counts in `H` is withheld (for
example, because `t` has no current definition or a withdrawn
`scope-object`, or under an invalid binding of `approval#persons` per
`listed-person`), or when a delivery line counts and no resolved promise
is `"known not kept"` while some promise of `t` cannot be resolved in
`H` with `K` or has no finding promise outcome, whether `H` has that
finding for `t` is withheld.

The `finding-subject` of that finding is the task ID (`work-item-id`) of
`t`. That finding has no location, and is not a result for whether a
`verifies` promise is kept in a tree in the sense of
`evidence#give-promise-sources`.

#### Findings of the class `missing-delivery`

@atom missing-delivery-finding=v1
@cites {
    ontology#{
        tree=v1, task=v1, scope-object=v1, work-item-state=v1,
        promise=v1, observation=v1, log-branch=v1, finding-class=v1,
    },
    ledger#{
        ledger-validity=v1, ledger-object=v1, stored-ledger=v1,
        intact-history=v1,
    },
    approval#{persons=v1, listed-person=v1},
    changes#{commit=v1, message-text=v1},
    documents#{kept-object-set=v1, tree-finding=v1},
    evidence#give-promise-sources=v1,
    findings#finding-subject=v1,
    text#line=v1,
    #{
        work-item-id=v1, delivery-line-form=v1, task-scope=v1,
        finding-promise-outcome=v1, change-input=v1,
        counting-delivery-line=v1,
    },
}

For a `change-input` with checked head `tree` `H` and base `tree` `B`
(each under the bindings and inputs of `finding-promise-outcome`, with
valid `kept-object-set` `K`), a git repository holding its
`ledger-object`s and history objects with a valid (`ledger-validity`)
and intact (`intact-history`) `stored-ledger` on the `log-branch`
(supplying `observation`s that decide states in `H`), and
`approval#persons` (unbound or bound), `H` has one `tree-finding` of the
`finding-class` `missing-delivery` for each `task` `t` that exists in
`H` and meets all six of these conditions:

1. Task `t` is unfinished in `H` (`work-item-state`).
2. The `scope-object` `S` of the current definition of `t` in `H` is not
   withdrawn in `H`, holds at least one promise edge, and every promise
   edge of `S` resolves in `H` with `K` (`task-scope`).
3. No `line` of the `message-text` of a `commit` of the change meets
   `delivery-line-form`, has the task ID (`work-item-id`) of `t` as its
   task ID, and counts in `H` (`counting-delivery-line`).
4. Every resolved `promise` of `S` has the finding promise outcome
   (`finding-promise-outcome`) `"known kept"` in `H` under those
   bindings and inputs.
5. At least one resolved `promise` of `S` has the finding promise
   outcome `"known not kept"` in `B` under those bindings and inputs,
   and every resolved promise of `S` has a finding promise outcome in
   `B`.
6. No delivery line of `t` in the change has withheld counting status in
   `H` (`counting-delivery-line`).

In conditions 2, 4, and 5, the promise edges of `S` resolve in `H` with
`K` (`task-scope`), and condition 5 evaluates, in `B`, the finding
promise outcome of each resolved promise obtained from `H`.

When `t` has no state in `H`, no current definition, a withdrawn
`scope-object`, an unresolved promise edge, a delivery line with
withheld counting status in `H` (including under an invalid binding of
`approval#persons` per `listed-person`), or a resolved promise with no
finding promise outcome in `H` or `B`, whether `H` has a
`missing-delivery` finding for `t` is withheld. The `finding-subject` of
that finding is the task ID (`work-item-id`) of `t`. That finding has
no location, and is not a result for whether a `verifies` promise is
kept in a tree in the sense of `evidence#give-promise-sources`.

#### Findings of the class `delivery-without-change`

@atom delivery-without-change-finding=v1
@cites {
    ontology#{
        tree=v1, task=v1, scope-object=v1, work-item-state=v1,
        finding-class=v1,
    },
    object-store#tree-object-store=v1,
    approval#{persons=v1, listed-person=v1},
    files#{path=v1, path-set-membership=v1},
    changes#{commit=v1, message-text=v1, hunk=v1, change-diff=v1},
    documents#tree-finding=v1,
    findings#finding-subject=v1,
    text#line=v1,
    #{
        work-item-id=v1, delivery-line-form=v1, change-input=v1,
        counting-delivery-line=v1,
    },
}

For a `change-input` with checked head `tree` `H` (whose
`tree-object-store` is valid) and base `tree` `B`, under
`approval#persons` (unbound or bound), `H` has one `tree-finding` of the
`finding-class` `delivery-without-change` for each `task` `t` that
exists in `H` (`work-item-state`) and meets both of these conditions:

1. At least one `line` of the `message-text` of a `commit` of the change
   meets `delivery-line-form`, has the task ID (`work-item-id`) of `t`
   as its task ID, and counts in `H` (`counting-delivery-line`).
2. No valid `path` `f` that has at least one `hunk` in a diff between
   `B` and `H` (`change-diff`) is in the set (`path-set-membership`) of
   the `paths` of the `scope-object` of the current definition of `t` in
   `H`.

When whether a delivery line for `t` counts in `H` is withheld (for
example, because `t` has no current definition or a withdrawn
`scope-object`, or under an invalid binding of `approval#persons` per
`listed-person`), whether `H` has that finding for `t` is withheld. The
`finding-subject` of that finding is the task ID (`work-item-id`) of
`t`. That finding has no location.

#### Findings of the class `unplanned-change`

@atom unplanned-change-finding=v1
@cites {
    ontology#{
        tree=v1, task=v1, scope-object=v1, work-item-state=v1,
        finding-class=v1, parameter=v1,
    },
    object-store#tree-object-store=v1,
    approval#{persons=v1, listed-person=v1},
    files#{path=v1, path-set-membership=v1},
    changes#{commit=v1, message-text=v1, hunk=v1, change-diff=v1},
    identifiers#external-namespaces=v1,
    documents#{file-readers=v1, tree-finding=v1},
    findings#{
        finding-subject=v1, path-finding-subject=v1, location=v1,
    },
    text#line=v1,
    #{
        work-item-id=v1, delivery-line-form=v1, task-line-form=v1,
        exempt-paths=v1, change-input=v1, repin-only-file=v1,
    },
}

For a `change-input` with checked head `tree` `H` whose
`tree-object-store` is valid, the **tasks of the change in `H`** are
each `task` `t` that exists in `H` (`work-item-state`) and whose task ID
(`work-item-id`) is the task ID of a `line` that meets
`delivery-line-form` or `task-line-form` in the `message-text` of a
`commit` of the change.

For a `change-input` with checked head `tree` `H` (whose
`tree-object-store` is valid) and base `tree` `B`, valid bindings `X` of
the `parameter` `exempt-paths`, `F` of `file-readers`, and `N` of
`external-namespaces`, and `approval#persons` (unbound or bound), `H`
has one `tree-finding` of the `finding-class` `unplanned-change` for
each valid `path` `f` that meets all five of these conditions:

1. The valid `path` `f` has at least one `hunk` in a diff between `B`
   and `H` (`change-diff`).
2. The valid `path` `f` has one path segment (`files#path`), or its path
   segment 1 is not `.sinter`.
3. Every task `t` of the tasks of the change in `H` has a current
   definition in `H` whose `scope-object` is not withdrawn in `H`, and
   for every such task `t`, `f` is not in the set
   (`path-set-membership`) of the `paths` of that `scope-object`.
4. The valid `path` `f` is not in the set (`path-set-membership`) of
   `X`.
5. The valid `path` `f` does not only re-pin between `B` and `H` under
   `F` and `N` (`repin-only-file`).

When `f` meets conditions 1, 2, 4, and 5, is not in the set of the
`paths` of any task of the change in `H` whose current definition and
unwithdrawn `scope-object` are known, and at least one task of the
change in `H` has no current definition or a withdrawn `scope-object` in
`H` (or withheld under an invalid binding of `approval#persons` per
`listed-person`), whether `H` has an `unplanned-change` finding for `f`
is withheld.

The `finding-subject` of that finding is the `path-finding-subject` of
`f`. When `H` holds a file at `f`, the `location` of that finding is `f`
alone, with no span. When `H` holds no file at `f`, that finding has no
location.

### Returning commit-level work findings

@req give-work-commit-findings=v1
@cites {
    conformance#{conforming-program=v1, reject-invalid-inputs=v1},
    documents#tree-finding=v1,
    changes#{repository-read=v1, undisturbed-read=v1},
    approval#{persons=v1, listed-person=v1},
    ontology#{tree=v1, finding-class=v1},
    #{
        change-input=v1, malformed-delivery-finding=v1,
        stale-delivery-finding=v1, delivery-on-unmet-task-finding=v1,
    },
}

This requirement applies to a `change-input` with checked head `tree`
`H` (with or without a base tree), when each `repository-read` is
undisturbed (`undisturbed-read`):

- **Class `malformed-delivery`:** When returning the findings of the
  `finding-class` `malformed-delivery` of `H`, a conforming program must
  return each `malformed-delivery-finding` (`tree-finding`) that `H` has
  once, and must return no other finding of that class.
- **Class `stale-delivery`:** Under the inputs of
  `stale-delivery-finding`, when returning the findings of the
  `finding-class` `stale-delivery` of `H`, a conforming program must
  return each `stale-delivery-finding` (`tree-finding`) that `H` has
  once, must return no withheld finding, and must return no other
  finding of that class.
- **Class `delivery-on-unmet-task`:** Under the bindings and inputs of
  `delivery-on-unmet-task-finding`, when returning the findings of the
  `finding-class` `delivery-on-unmet-task` of `H`, a conforming program
  must return each `delivery-on-unmet-task-finding` (`tree-finding`)
  that `H` has once, must return no withheld finding, and must return no
  other finding of that class.

Invalid bindings and invalid object stores follow
`reject-invalid-inputs`, with partial withholding under an invalid
binding of `approval#persons` governed by `listed-person`.

### Returning change-level work findings

@req give-work-change-findings=v1
@cites {
    conformance#{conforming-program=v1, reject-invalid-inputs=v1},
    documents#tree-finding=v1,
    changes#{repository-read=v1, undisturbed-read=v1},
    ledger#stored-ledger=v1,
    approval#{persons=v1, listed-person=v1},
    ontology#{tree=v1, finding-class=v1},
    #{
        exempt-paths=v1, change-input=v1, missing-delivery-finding=v1,
        delivery-without-change-finding=v1,
        unplanned-change-finding=v1,
    },
}

This requirement applies to a `change-input` with checked head `tree`
`H`, when each `repository-read` from which a conforming program reads
whether the change has a base tree (and, when it has one, reads `B`,
`H`, and the repository history) is undisturbed (`undisturbed-read`):

- **When the change input has a base tree `B`:**
  - When returning the findings of one of the `finding-class`es
    `missing-delivery`, `delivery-without-change`, and
    `unplanned-change` for the change, a conforming program must not
    return that the change has no base (`"no base"`).
  - **Class `delivery-without-change`:** Under the inputs of
    `delivery-without-change-finding`, when returning the findings of
    the `finding-class` `delivery-without-change` of `H`, a conforming
    program must return each `delivery-without-change-finding`
    (`tree-finding`) that `H` has once, must return no withheld finding,
    and must return no other finding of that class.
  - **Class `unplanned-change`:** Under the bindings and inputs of
    `unplanned-change-finding`, when returning the findings of the
    `finding-class` `unplanned-change` of `H`, a conforming program must
    return each `unplanned-change-finding` (`tree-finding`) that `H` has
    once, must return no withheld finding, and must return no other
    finding of that class. Under an invalid binding of `exempt-paths`, a
    conforming program must return no finding of the class
    `unplanned-change` (`reject-invalid-inputs`).
  - **Class `missing-delivery`:** Under the bindings and inputs of
    `missing-delivery-finding` (including its valid, intact
    `stored-ledger`), when returning the findings of the `finding-class`
    `missing-delivery` of `H`, a conforming program must return each
    `missing-delivery-finding` (`tree-finding`) that `H` has once, must
    return no withheld finding, and must return no other finding of that
    class.
- **When the change input has no base tree:** When returning the
  findings of one of the `finding-class`es `missing-delivery`,
  `delivery-without-change`, and `unplanned-change` for the change, a
  conforming program must return that the change has no base
  (`"no base"`), and must return no finding of that class.

Other invalid bindings and invalid object stores or ledgers follow
`reject-invalid-inputs`, with partial withholding under an invalid
binding of `approval#persons` governed by `listed-person`.

### Test vectors

Test vectors for `change-checks` live in
[work.test-vectors.jsonl](work.test-vectors.jsonl) as a test-vector set
under [test-vectors](sinter:data-forms#test-vectors=v1). Neither group
uses `needs`, and neither group uses `result`.

#### Change promise-finding vectors

@schema change-promise-findings-vector=v1
@cites {
    conformance#{conforming-program=v1, own-store=v1},
    text#{text=v1, position=v1, code-point-order=v1},
    files#path=v1,
    data-forms#{
        json-value=v1, line-object=v1, vector-line=v1, group-schema=v1,
        vector-meaning=v1,
    },
    identifiers#citation-entry=v1,
    documents#{
        canonical-target=v1, kept-object-set=v1, tree-edge=v1,
        slice-location=v1, tree-finding=v1,
    },
    evidence#{tree-evidence=v1, tree-outcome=v1},
    findings#{finding-subject=v1, location=v1},
    approval#persons=v1,
    ontology#{
        tree=v1, object=v1, object-kind=v1, edge=v1, suspect-edge=v1,
        declared-item=v1, content-id=v1, vector-set=v1,
        conformance-vector-group=v1, log-branch=v1, finding-class=v1,
    },
    #{
        finding-promise-outcome=v1, promise-outside-paths-finding=v1,
        unmet-promise-finding=v1, give-promise-findings=v1,
        delivery-on-unmet-task-finding=v1, missing-delivery-finding=v1,
        give-work-commit-findings=v1, give-work-change-findings=v1,
    },
}

`change-promise-findings-vector` is a `group-schema` for group
`change-promise-findings` and tests `give-work-commit-findings` (for
`delivery-on-unmet-task`), `give-work-change-findings` (for
`missing-delivery`), and `give-promise-findings` (for `unmet-promise`
and `promise-outside-paths`). Each line is a `vector-line` whose meaning
follows `vector-meaning`. Each vector represents a change input with
head `tree` `H` (and optional base `tree` `B` holding the same canonical
store objects as `H`) under the bindings and inputs of
`finding-promise-outcome` and undisturbed repository reads.

| field | type | meaning |
|---|---|---|
| `input.objects` | array of `line-object` | canonical store `object`s of `H` (no `id` member) |
| `input.tree.has-evidence` | boolean | `true` when `H` has `tree-evidence`, `false` otherwise |
| `input.tree.edges[]` | array of objects | `tree-edge` summaries of `H` for `finding-promise-outcome` |
| `input.tree.edges[].kind` | string | `"satisfies"` or `"verifies"` |
| `input.tree.edges[].req` | string | requirement name targeted directly or through a `vector-set` or `conformance-vector-group` |
| `input.tree.edges[].fits` | boolean | `true` when the edge fits its kind (`ontology#edge`) and is not suspect in the tree (`suspect-edge`); `false` otherwise |
| `input.tree.edges[].source` | string | `"text"` (text-file citation), `"store"` (declared item in `.sinter/`), or `"own-store"` (`own-store`) |
| `input.tree.edges[].target-id` | string | `canonical-target` (`content-id`) |
| `input.tree.edges[].path` | string (optional) | valid `files#path`; present for `"text"` and `"store"` |
| `input.tree.edges[].line`, `column`, `end-line`, `end-column` | integer (`>= 1`, optional) | 1-based line numbers and 1-based columns (`position`, `findings#location`) of the start position and the position after the `slice-location` of the `citation-entry`; present for `"text"` |
| `input.tree.edges[].source-id` | string (optional) | `content-id` of the source `declared-item`; present for `"own-store"` |
| `input.tree.edges[].test-outcome` | string (optional) | for a `"verifies"` edge when `has-evidence` is `true`: `"passed"`, `"failed"`, `"not run"`, or `"no-outcome"` (no `tree-outcome` in the evidence); when absent for a `"verifies"` edge while `has-evidence` is `true`, the test has neither `"passed"` nor `"no-outcome"` |
| `input.commits` | array of strings | commit message `text`s of the change, one per commit whose message has a text (`[]` when none) |
| `input.base` | object (optional) | tree summary of `B` in the same form as `input.tree` |
| `input.log` | array of `line-object` (optional) | canonical observation `object`s on a valid and intact `log-branch`; defaults to empty when absent |
| `input.kept` | array of `line-object` (optional) | canonical `object`s of `kept-object-set`; defaults to empty when absent |
| `input.persons` | array of strings or `"invalid"` (optional) | distinct `text` strings in `code-point-order` forming a valid binding of `approval#persons`, or `"invalid"` for an invalid binding; absent when unbound |
| `values.findings.unmet-promise` | array of strings | `finding-subject` values of all `unmet-promise-finding` findings of `H`, in `code-point-order` |
| `values.findings.promise-outside-paths[]` | array of objects | `promise-outside-paths-finding` findings of `H`, in `code-point-order` of `subject` |
| `values.findings.promise-outside-paths[].subject` | string | `finding-subject` text |
| `values.findings.promise-outside-paths[].location` | object (optional) | `findings#location`: `{path, start-line, start-column, end-line, end-column}` for a text edge (`slice-location`), `{path}` for a `.sinter/` store edge, or absent when the edge comes from an `own-store` and has no location |
| `values.findings.delivery-on-unmet-task` | array of strings | task-ID `finding-subject` values of all `delivery-on-unmet-task-finding` findings of `H`, in `code-point-order` |
| `values.findings.missing-delivery` | array of strings (optional) | present when, and only when, `input.base` is present: task-ID `finding-subject` values of all `missing-delivery-finding` findings of `H`, in `code-point-order` |

The `json-value` objects `input`, `input.tree`, each element of
`input.tree.edges`, `input.base` (when present), each element of
`input.base.edges`, `values`, `values.findings`, each element of
`values.findings.promise-outside-paths`, and each `location` hold only
the members listed in this table, while each canonical object inside
`input.objects`, `input.log`, and `input.kept` holds the members defined
by `ontology#object-kind`. When a conforming program returns findings of
any `finding-class` named in `values.findings`, it returns one
`tree-finding` for each element of that member (with that `location` for
`promise-outside-paths`, and no location for the other three classes)
and no other finding of that class.

@example Sample lines testing
[give-work-commit-findings](sinter:#give-work-commit-findings=v1)
([delivery-on-unmet-task](sinter:#delivery-on-unmet-task-finding=v1))
and [give-work-change-findings](sinter:#give-work-change-findings=v1)
([missing-delivery](sinter:#missing-delivery-finding=v1))
([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#change-promise-findings-vector=v1","group":"change-promise-findings","input":{"commits":["Delivers: task:e1ade641a6990b8e16f8142d2cd54b01 56bf71\n"],"objects":[{"kind":"task","nonce":"00000000000000000000000000000002","v":1},{"kind":"name","name":"billing#limit","v":1},{"edges":[{"kind":"about","to":"task:e1ade641a6990b8e16f8142d2cd54b01"},{"kind":"promises-verifies","to":"name:2f5499ffd40584baddb649053699467a"}],"kind":"scope","paths":["test/billing/**"],"v":1},{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"task:e1ade641a6990b8e16f8142d2cd54b01"},{"kind":"scoped-by","to":"scope:56bf71390007ccb491b7eedf7fc754e9"}],"kind":"task-def","name":"Verify billing limit","v":1}],"tree":{"edges":[{"column":1,"end-column":25,"end-line":5,"fits":true,"kind":"verifies","line":5,"path":"test/billing/a_test.ml","req":"billing#limit","source":"text","target-id":"name:2f5499ffd40584baddb649053699467a","test-outcome":"failed"}],"has-evidence":true}},"note":"failed verifies test inside paths reports unmet-promise and delivery-on-unmet-task","values":{"findings":{"delivery-on-unmet-task":["task:e1ade641a6990b8e16f8142d2cd54b01"],"promise-outside-paths":[],"unmet-promise":["task:e1ade641a6990b8e16f8142d2cd54b01 verifies billing#limit"]}}}
{"form":"#change-promise-findings-vector=v1","group":"change-promise-findings","input":{"base":{"edges":[],"has-evidence":true},"commits":["Task: task:d3e073f4bae981aa8a042274c335422f\n"],"objects":[{"kind":"task","nonce":"00000000000000000000000000000001","v":1},{"kind":"name","name":"billing#limit","v":1},{"edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"promises-satisfies","to":"name:2f5499ffd40584baddb649053699467a"}],"kind":"scope","paths":["src/billing/**"],"v":1},{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"scoped-by","to":"scope:220c2c3804849c2931b1a19666cedd6c"}],"kind":"task-def","name":"Enforce billing limit","v":1}],"tree":{"edges":[{"column":1,"end-column":20,"end-line":1,"fits":true,"kind":"satisfies","line":1,"path":"src/billing/a.ml","req":"billing#limit","source":"text","target-id":"name:2f5499ffd40584baddb649053699467a"}],"has-evidence":true}},"note":"unfinished task whose promise becomes kept without a counting delivery line reports missing-delivery","values":{"findings":{"delivery-on-unmet-task":[],"missing-delivery":["task:d3e073f4bae981aa8a042274c335422f"],"promise-outside-paths":[],"unmet-promise":[]}}}
```

#### Change finding vectors

@schema change-findings-vector=v1
@cites {
    conformance#conforming-program=v1,
    text#{text=v1, slice=v1, code-point-order=v1},
    files#{path=v1, path-set=v1},
    data-forms#{
        json-value=v1, line-object=v1, vector-line=v1, group-schema=v1,
        vector-meaning=v1,
    },
    identifiers#external-namespaces=v1,
    documents#{
        file-readers=v1, read-file=v1, unreadable-file=v1,
        kept-object-set=v1, tree-finding=v1,
    },
    object-store#tree-object-store=v1,
    changes#{
        commit=v1, message-text=v1, line-text=v1, hunk=v1,
        change-diff=v1,
    },
    findings#{
        finding-subject=v1, path-finding-subject=v1, location=v1,
    },
    approval#persons=v1,
    ontology#{
        tree=v1, object=v1, object-kind=v1, item-revision=v1,
        log-branch=v1, finding-class=v1, parameter=v1,
    },
    #{
        commit-object-name=v1, exempt-paths=v1, change-input=v1,
        repin-only-file=v1, malformed-delivery-finding=v1,
        stale-delivery-finding=v1, delivery-without-change-finding=v1,
        unplanned-change-finding=v1, give-work-commit-findings=v1,
        give-work-change-findings=v1,
    },
}

`change-findings-vector` is a `group-schema` for group `change-findings`
and tests `give-work-commit-findings` (for `malformed-delivery` and
`stale-delivery`) and `give-work-change-findings` (for
`delivery-without-change`, `unplanned-change`, and missing-base
results). Each line is a `vector-line` whose meaning follows
`vector-meaning`. Each vector represents a `change-input` with head
`tree` `H`, valid `tree-object-store`, valid bindings of the
`parameter`s `exempt-paths`, `file-readers`, and `external-namespaces`,
and undisturbed repository reads.

| field | type | meaning |
|---|---|---|
| `input.objects` | array of `line-object` | canonical store `object`s of `H` (no `id` member) |
| `input.exempt-paths` | array of strings | valid `path-set` binding of `exempt-paths` |
| `input.log` | array of `line-object` (optional) | canonical observation `object`s on a valid and intact `log-branch`; defaults to empty when absent |
| `input.kept` | array of `line-object` (optional) | canonical `object`s of `kept-object-set`; defaults to empty when absent |
| `input.persons` | array of strings or `"invalid"` (optional) | distinct `text` strings in `code-point-order` forming a valid binding of `approval#persons`, or `"invalid"` for an invalid binding; absent when unbound |
| `input.commits[]` | array of objects (optional) | `commit`s of the change (`{id, text?}`); `[]` or absent when the change has no commits |
| `input.commits[].id` | string | `commit-object-name` of the commit |
| `input.commits[].text` | string (optional) | `message-text` of the commit; absent when the commit message has no valid UTF-8 text |
| `input.changed-files[]` | array of objects (optional) | present when, and only when, the change has a base tree `B`: one object per valid `files#path` with at least one `hunk` in a diff between `B` and `H` (`change-diff`) |
| `input.changed-files[].path` | string | valid `files#path` of the changed file |
| `input.changed-files[].base` | object (optional) | file summary of the file at `path` in `B`; absent when `B` holds no file at `path` |
| `input.changed-files[].head` | object (optional) | file summary of the file at `path` in `H`; absent when `H` holds no file at `path` |
| `base.readable`, `head.readable` | boolean | `true` when the file is a readable `read-file` under `file-readers` (`unreadable-file`), `false` otherwise |
| `base.lines[]`, `head.lines[]` | array of objects | one object per `line-text` of the file in 1-based line-number order (`[]` when unreadable or empty): `{text, pins}` |
| `lines[].text` | string | `line-text` string |
| `lines[].pins[]` | array of objects | citation pins (`repin-only-file`) on that line in start-boundary order of their pin slices: `{start, end}` (and `matches-current` in `head` only), where `start` and `end` are non-negative integer boundaries (`slice`) of the pin slice in `text`, and `matches-current` is `true` when the edge of that citation pin has a cited item in `H` whose current revision (`item-revision`) equals the text of that pin slice, and `false` otherwise |
| `values.findings.malformed-delivery` | array of strings | `finding-subject` values of all `malformed-delivery-finding` findings of `H`, in `code-point-order` |
| `values.findings.stale-delivery` | array of strings | `finding-subject` values of all `stale-delivery-finding` findings of `H`, in `code-point-order` |
| `values.findings.delivery-without-change` | array of strings (optional) | present when, and only when, `input.commits` and `input.changed-files` are both present: task-ID `finding-subject` values of all `delivery-without-change-finding` findings of `H`, in `code-point-order` |
| `values.findings.unplanned-change[]` | array of objects (optional) | present when, and only when, `input.commits` and `input.changed-files` are both present: `unplanned-change-finding` findings of `H`, in `code-point-order` of `subject` |
| `values.findings.unplanned-change[].subject` | string | `path-finding-subject` text |
| `values.findings.unplanned-change[].has-location` | boolean | `true` when the finding has the `location` `path` alone with no span, `false` when it has no location |
| `values.no-base` | boolean | `true` when `input.changed-files` is absent, `false` otherwise |

The `json-value` objects `input`, each element of `input.commits`, each
element of `input.changed-files`, each `base` and `head` file summary,
each element of `lines`, each element of `pins`, `values`,
`values.findings`, and each element of
`values.findings.unplanned-change` hold only the members listed in this
table, while each canonical object inside `input.objects`, `input.log`,
and `input.kept` holds the members defined by `ontology#object-kind`.
When a conforming program returns findings of any `finding-class` named
in `values.findings`, it returns one `tree-finding` for each element of
that member and no other finding of that class, and for base-dependent
classes it returns that the change has no base (`"no base"`) when, and
only when, `values.no-base` is `true`.

@example Sample lines testing
[give-work-commit-findings](sinter:#give-work-commit-findings=v1) and
[give-work-change-findings](sinter:#give-work-change-findings=v1) on a
missing base and on an inline citation re-pin inside a trailing
[example block](sinter:documents#example-block=v1)
([repin-only-file](sinter:#repin-only-file=v1),
[vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#change-findings-vector=v1","group":"change-findings","input":{"commits":[{"id":"1111111111111111111111111111111111111111","text":"Delivers: bad\n"}],"exempt-paths":[],"objects":[{"kind":"task","nonce":"00000000000000000000000000000001","v":1},{"kind":"name","name":"billing#limit","v":1},{"edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"promises-satisfies","to":"name:2f5499ffd40584baddb649053699467a"}],"kind":"scope","paths":["src/billing/**"],"v":1},{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"scoped-by","to":"scope:220c2c3804849c2931b1a19666cedd6c"}],"kind":"task-def","name":"Enforce billing limit","v":1}]},"note":"change with no base reports no-base true and still gives malformed-delivery","values":{"findings":{"malformed-delivery":["1111111111111111111111111111111111111111@L1"],"stale-delivery":[]},"no-base":true}}
{"form":"#change-findings-vector=v1","group":"change-findings","input":{"changed-files":[{"base":{"lines":[{"pins":[{"end":44,"start":42}],"text":"@example See [limit](sinter:billing#limit=v1)."}],"readable":true},"head":{"lines":[{"pins":[{"end":44,"matches-current":true,"start":42}],"text":"@example See [limit](sinter:billing#limit=v2)."}],"readable":true},"path":"docs/designs/billing.md"}],"commits":[],"exempt-paths":[],"objects":[]},"note":"file whose only change repins an inline citation inside an example block to the current revision gives no unplanned-change finding","values":{"findings":{"delivery-without-change":[],"malformed-delivery":[],"stale-delivery":[],"unplanned-change":[]},"no-base":false}}
```

## Delivery job

@spec delivery-job=v1

On the default branch, the delivery job walks unrecorded commits in
parents-first order, evaluates each delivered task's promises at the
head tree, and appends `"delivered"` observations, one `"progress"`
observation, and kept copies of the head tree's declared items and the
computed identity objects that those items need to the log branch.

### Definitions

#### Promise outcomes in the job

@atom job-promise-outcome=v1
@cites {
    conformance#{conforming-program=v1, own-store=v1},
    documents#{
        file-readers=v1, kept-object-set=v1, tree-edge=v1,
        vector-files=v1,
    },
    evidence#{
        import=v1, report-file=v1, tree-evidence=v1, tree-outcome=v1,
    },
    files#path-set-membership=v1,
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    object-store#tree-object-store=v1,
    ontology#{
        declared-item=v1, edge=v1, encoding=v1, item-name=v1,
        parameter=v1, promise=v1, satisfies-edge=v1, scope-object=v1,
        suspect-edge=v1, test=v1, tree=v1, verifies-edge=v1,
    },
    packs#{runner-settings=v1, test-runner=v1},
    #task-scope=v1,
}

This atom applies for a `tree` `T` whose `tree-object-store` is valid,
valid bindings of the `parameter`s `file-readers` and `vector-files`, a
binding of `external-namespaces` for which `validate-bindings` of a
`conforming-program` of Identifiers returns `"valid"`, a valid
`kept-object-set` `K`, the `tree-evidence` `V` for `T`, and (when `T`
has evidence) valid bindings of `runner-settings` for the
`test-runner`s of the `report-file`s of the `import`s of `V`.

For a `scope-object` `S` that is not a withdrawn scope in `T`
(`task-scope`) and a resolved promise `q = (kind, req-name)` of `S` in
`T` with `K` (`task-scope`), the **job promise outcome** of `q` for `S`
in `T` is `"kept"`, `"not-kept"`, or no outcome:

- When `T` holds (across both `encoding`s: text declared items and
  valid unwithdrawn `.sinter/` objects) zero `declared-item`s of the
  kind `req` whose `item-name` is `req-name`, or two or more such
  declared items, the job promise outcome is `"not-kept"`.
- When `T` holds exactly one such declared item and `kind` is
  `satisfies`, the job promise outcome is `"kept"` when `T` holds a
  promised `satisfies` `tree-edge` (`promise`, `satisfies-edge`) for
  `q` that fits its kind (`ontology#edge`) and is not suspect in `T`
  (`suspect-edge`), from a citation in a text file whose valid path is
  in `paths` of `S` (`path-set-membership`), and `"not-kept"`
  otherwise. An edge of a declared item in `.sinter/` or in a program's
  `own-store` never keeps a promise.
- When `T` holds exactly one such declared item and `kind` is
  `verifies`:
  - When `T` has no evidence (`tree-evidence`), the job promise outcome
    is `"not-kept"`.
  - When `T` has evidence `V` and at least one promised `verifies`
    `tree-edge` (`promise`, `verifies-edge`) for `q` that fits its kind
    (`ontology#edge`) and is not suspect in `T` (`suspect-edge`), from
    a citation in a text file whose valid path is in `paths` of `S`
    (`path-set-membership`), has a `test` source whose `tree-outcome`
    in `V` is `"passed"`, the job promise outcome is `"kept"`.
  - Otherwise, when `T` has evidence `V` and at least one such promised
    `verifies` `tree-edge` for `q` has a `test` source that has no
    `tree-outcome` in `V`, `q` has no job promise outcome (and never
    `"not-kept"`).
  - Otherwise, the job promise outcome is `"not-kept"`.

#### Job range

@term job-range=v1
@cites {
    gitdoc/gitglossary,
    approval#{listed-person=v1, persons=v1},
    changes#{
        ancestry=v1, commit=v1, commit-file=v1, commit-range=v1,
        default-branch-commit=v1, default-branch-name=v1,
        first-parent-line=v1, landing-commit=v1, reach=v1,
        remote-transfer=v1, repository-read=v1, shallow-commit=v1,
    },
    ledger#{
        accepted-record=v1, intact-history=v1, ledger-object=v1,
        ledger-validity=v1, log-branch-ref=v1, stored-ledger=v1,
    },
    object-store#tree-object-store=v1,
    ontology#{
        job=v1, log-branch=v1, object-withdrawal=v1, observation=v1,
        parameter=v1,
    },
    #{commit-object-name=v1, progress-acceptance-rule=v1},
}

For a run of the `job` on a git repository `R`, the **read repository**
`R′` of the run is `R` as the `repository-read`s of the run find it,
after each fetch (`remote-transfer`) that the program makes into `R` in
the run before or during those repository reads, or `R` itself when the
program makes no fetch. A git repository **holds the tree objects** of
a `commit` `c` of that git repository when, and only when, it holds the
git tree object of `c` and every git tree object and blob that the git
tree object of `c` reaches through its entries (`commit-file`), at any
depth. A git repository **holds its log-branch objects** when, and only
when, its `log-branch` is missing (`log-branch-ref`), or it holds its
ledger objects and its history objects (`ledger-object`).

The rest of this term applies for a git repository `R′` that holds its
log-branch objects, whose log branch is valid (`ledger-validity`) and
intact (`intact-history`) — or missing, holding zero stored
observations (`stored-ledger`) — for the commit `H` of the default
branch of `R′` (`default-branch-commit`) under a valid binding of the
`parameter` `default-branch-name`, where `R′` holds the tree objects of
`H` and the tree of `H` has a valid `tree-object-store`, and with
`approval#persons` unbound or bound to a valid binding.

The **unwithdrawn progress commits** of the run are the distinct
`commit-object-name`s `head` of all accepted `"progress"`
`observation`s on the log branch of `R′` (`accepted-record`,
`progress-acceptance-rule`) that no counting void in the tree of `H`
withdraws (`object-withdrawal`, `listed-person`).

A `commit` `c` of `R′` **has a missing parent** when, and only when,
`c` is not a `shallow-commit` of `R′` and the commit object of `c`
names, as a parent, a git object (`gitglossary`) that is not a commit
of `R′`. For a commit `c` of `R′`, `A(c)` is the smallest set of
commits of `R′` that holds `c` and that, for each commit `x` in `A(c)`
that is not a shallow commit of `R′`, holds each commit of `R′` that
the commit object of `x` names as a parent (`ancestry`). `R′` **holds
the ancestry** of `c` when, and only when, no commit in `A(c)` has a
missing parent. A set of commits of `R′` is **complete** in `R′` when,
and only when, no commit in that set is a shallow commit of `R′` and no
commit in that set has a missing parent.

Let `S` be the set of unwithdrawn progress commits of the run. The
**run status** for `R′` and `H` is one of **already recorded**,
**ready to record** (with a `commit-range`), and **cut**:

1. When `S` is empty: if `R′` does not hold the ancestry of `H`, the
   run status is **cut**. Otherwise, let `C` be the `commit-range` from
   no commit to `H`; when `C` is complete in `R′`, the run status is
   **ready to record** with range `C`, and otherwise **cut**.
2. When `S` is not empty and some `s` in `S` is not a commit of `R′`
   while `R′` holds at least one shallow commit: the run status is
   **cut**.
3. When `S` is not empty and any commit `J` of `R′` whose commit object
   name is in `S` is a shallow commit of `R′` or `R′` does not hold the
   ancestry of `J`: the run status is **cut**.
4. When cases 1 to 3 do not apply and some `s` in `S` is not a commit
   of `R′` (so `R′` holds no shallow commit): the run status follows
   case 1.
5. When cases 1 to 4 do not apply (every `s` in `S` is a commit of `R′`
   that is not shallow and whose ancestry `R′` holds):
   - When a unique commit `J` in `S` reaches (`reach`) every commit in
     `S` (the ancestry-maximal commit of `S`):
     - When `J` is `H` or `J` reaches `H`: the run status is **already
       recorded**.
     - Otherwise, when `R′` does not hold the ancestry of `H`: the run
       status is **cut**.
     - Otherwise, when `H` reaches `J`: let `C` be the `commit-range`
       from `J` to `H`. When `C` is complete in `R′`, the run status is
       **ready to record** with range `C`, and otherwise **cut**.
     - Otherwise: when `A(J)` is not complete in `R′`, the run status
       is **cut**. When `A(J)` is complete in `R′`, the run status
       follows case 1.
   - When no commit in `S` reaches every commit in `S`: when `A(s)` is
     complete in `R′` for every `s` in `S`, `R′` holds the ancestry of
     `H`, and the `commit-range` `C` from no commit to `H` is complete
     in `R′`, the run status is **ready to record** with range `C`;
     otherwise **cut**.

When the run status is ready to record with range `C`, `R′` **holds the
landing trees** of `C` for `H` when `R′` holds the tree objects of
every `landing-commit` `M` of a commit in `C` on the
`first-parent-line` of `H`.

#### Git identity

@term git-identity=v1
@cites {
    gitdoc/git,
    gitdoc/git-commit,
    gitdoc/git-config,
    changes#git-configuration=v1,
    text#{character=v1, text=v1},
}

For a git repository `R` and the environment of an execution, the
**configured committer name** and **configured committer email** are
the committer name and committer email that `git`, `git-commit`, and
`git-config` specify from the environment variables
(`GIT_COMMITTER_NAME`, `GIT_COMMITTER_EMAIL`, and `EMAIL`) and the
settings of the `git-configuration` of `R` (`committer.name`,
`user.name`, `committer.email`, and `user.email`), with `<`, `>`, and
line feed (`character` U+000A) stripped as `git-commit` defines, and
excluding any default that git guesses from the system user name or
host name (as when `user.useConfigOnly` is true in `git-config`).

Git **has an identity** for `R` in that environment when, and only
when, those sources supply both a non-empty configured committer name
and a non-empty configured committer email. When git has an identity,
the **git identity** is that configured committer name, followed by a
space (`character` U+0020), `<`, that configured committer email, and
`>`, as a `text`. Otherwise, git has no identity for `R` in that
environment.

### Evaluating `verifies` promises in the job

@req give-job-promise-outcomes=v1
@cites {
    conformance#conforming-program=v1,
    documents#kept-object-set=v1,
    evidence#{give-promise-sources=v1, tree-evidence=v1},
    ledger#job-marker=v1,
    ontology#{
        job=v1, observation=v1, promise=v1, scope-object=v1, task=v1,
        tree=v1,
    },
    #{job-promise-outcome=v1, task-scope=v1},
}

When a `conforming-program` runs the `job` in a job execution
(`job-marker`) and evaluates a resolved `verifies` `promise` `q` of an
unwithdrawn `scope-object` `S` in a `tree` `T` with `kept-object-set`
`K` (`task-scope`) for which `job-promise-outcome` applies:

- When `job-promise-outcome` is `"kept"` or `"not-kept"` for `q` in
  `T`, the program must return, apart from any appended `"delivered"`
  `observation`, exactly one result for whether `q` is kept in `T` for
  `S`: that job promise outcome (`"kept"` or `"not-kept"`), and no
  other outcome. When `T` has `tree-evidence`, the program must also
  return, apart from any appended `"delivered"` observation and
  alongside that result, the test outcomes and sources that
  `give-promise-sources` requires for `q` in `T`, taking `paths` of
  `S` as the paths of the `task` in `ontology#promise`.
- When `q` has no `job-promise-outcome` in `T`, the program must return
  neither `"kept"` nor `"not-kept"` for `q`.

### Appending delivered observations and kept objects

@req append-delivered-observations=v1
@cites {
    approval#{listed-person=v1, persons=v1},
    changes#{
        commit=v1, default-branch-commit=v1, default-branch-name=v1,
        first-parent-line=v1, landing-commit=v1, message-text=v1,
        parents-first-order=v1, repository-read=v1,
        undisturbed-read=v1,
    },
    conformance#{conforming-program=v1, report=v1},
    documents#{file-readers=v1, kept-object-set=v1, vector-files=v1},
    evidence#{import=v1, report-file=v1, tree-evidence=v1},
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ledger#{
        accepted-record=v1, agent-marker=v1, agent-markers=v1,
        append-to-log-branch=v1, intact-history=v1, job-marker=v1,
        job-markers=v1, ledger-remote=v1, ledger-validity=v1,
        log-branch-name=v1, needed-log-identity=v1, stored-ledger=v1,
    },
    object-store#tree-object-store=v1,
    ontology#{
        computed-identity=v1, content-id=v1, declared-item=v1, edge=v1,
        encoding=v1, item-name=v1, job=v1, log-branch=v1,
        object-kind=v1, object-withdrawal=v1, observation=v1,
        parameter=v1, scope-object=v1, task=v1, work-item-state=v1,
    },
    packs#{runner-settings=v1, test-runner=v1},
    text#{code-point-order=v1, line=v1},
    #{
        commit-object-name=v1, delivered-acceptance-rule=v1,
        delivery-line-form=v1, git-identity=v1, job-promise-outcome=v1,
        job-range=v1, progress-acceptance-rule=v1, task-scope=v1,
        work-item-id=v1,
    },
}

This requirement applies in a run with no read error when a
`conforming-program` runs the `job` on a git repository `R` in a job
execution (`job-marker`) that is not an agent execution
(`agent-marker`), with undisturbed `repository-read`s
(`undisturbed-read`), under valid bindings of the `parameter`s
`file-readers`, `vector-files`, `default-branch-name`, `ledger-remote`,
`log-branch-name`, `agent-markers`, `job-markers`, and (when bound)
`approval#persons`, and a binding of `external-namespaces` for which
`validate-bindings` returns `"valid"`, where:

- the read repository `R′` (`job-range`) holds its log-branch objects
  and its `log-branch` is valid (`ledger-validity`) and intact
  (`intact-history`), or missing, with `kept-object-set` `K` (the
  kept objects of that log branch under `stored-ledger`, or the empty
  set when missing);
- the default branch of `R′` has a commit `H` (`default-branch-commit`),
  `R′` holds the tree objects of `H`, and the tree of `H` has a valid
  `tree-object-store`; and
- git has an identity (`git-identity`) for `R` in the execution's
  environment.

The **kept objects of `H`** are, deduplicated by `content-id` against
lines already on the log branch (`append-to-log-branch`), the canonical
object of each `declared-item` of the tree of `H` in either `encoding`
(in `.sinter/`, an object that is neither withdrawn nor replaced;
`"example"` objects are not declared items and are never stored on the
log branch under `object-kind`) and each `computed-identity` object
that any of those kept objects needs (`needed-log-identity`).

The **named job results** are `"already recorded"`,
`"cannot see range"`, `"invalid bindings"`, `"invalid ledger"`,
`"invalid object store"`, `"missing ledger objects"`,
`"no default branch commit"`, `"no git identity"`, and
`"agent execution"`.

When the run status (`job-range`) for `R′` and `H` is **already
recorded**:

- When the program finishes without stopping after refused pushes
  (`append-to-log-branch`), the program must append to the log branch
  and push under `append-to-log-branch`: no `"delivered"` `observation`,
  one `"progress"` observation (`v`: `1`, `kind`: `"progress"`, `by`:
  the git identity for `R`, `seq`: the next sequence integer, `head`:
  the `commit-object-name` of `H`, and no `edges`), and the kept
  objects of `H`. The program must return exactly one result,
  `"already recorded"`, and must end without an error.
- When the program stops after refused pushes (`append-to-log-branch`),
  the program must not return `"already recorded"` and must end with an
  error.

When the run status (`job-range`) for `R′` and `H` is **ready to
record** with range `C`, `R′` holds the landing trees of `C` for `H`
(`job-range`), and (when the tree of `H` has `tree-evidence` `V`) the
binding of `runner-settings` for the `test-runner` of each
`report-file` of each `import` of `V` is valid:

1. Taking each `commit` `c` of `C` in `parents-first-order` whose
   `landing-commit` `M` on the `first-parent-line` of `H` has a valid
   `tree-object-store` and, when `c` has a `message-text`, each `line`
   `l` of that message text in line order: for each line `l` matching
   `delivery-line-form` whose task ID `t` (`work-item-id`) names a
   `task` that exists in the tree of `M`, when neither an accepted
   `"delivered"` observation on the log branch (`accepted-record`,
   `delivered-acceptance-rule`, not withdrawn by a counting void in the
   tree of `H` under `object-withdrawal` and `listed-person`) nor a
   `"delivered"` observation queued earlier in the run has the commit
   object name of `c` as `commit`, `t` as its `about` edge, and the
   short scope hash of `l` as `hash`, define one candidate `"delivered"`
   observation with `v`: `1`, `kind`: `"delivered"`, `by`: the git
   identity for `R`, `seq`: the next sequence integer
   (`append-to-log-branch`), `commit`: the commit object name of `c`,
   `merge`: the commit object name of `M`, `head`: the commit object
   name of `H`, `hash`: the short scope hash of `l`, and `edges`
   holding `about` naming `t` together with:
   - when `t` has a current definition in the tree of `M`
     (`work-item-state`) whose `scope-object` `S` is withdrawn by
     neither a counting void in the tree of `M` nor a counting void in
     the tree of `H`: an `observes` `edge` naming the content ID of the
     canonical latest definition `D` of `t` in the tree of `M`
     (`task-scope`), plus, for each resolved promise
     `(kind, req-name)` of `S` in the tree of `M`, then the tree of `H`,
     then `K` (`task-scope`) whose `job-promise-outcome` in the tree of
     `H` is `"kept"` (so the tree of `H` holds a unique declared item
     `O` of the kind `req` whose `item-name` is `req-name`), a
     `kept-satisfies` edge (for `satisfies`) or `kept-verifies` edge
     (for `verifies`) naming the content ID of `O`, deduplicated and
     sorted in canonical edge order (`code-point-order`);
   - when `t` has a current definition in the tree of `M` whose
     `scope-object` `S` is not withdrawn by a counting void in the tree
     of `M` and is withdrawn by a counting void in the tree of `H`: an
     `observes` edge naming the content ID of the canonical latest
     definition `D` of `t` in the tree of `M`, and no `kept-satisfies`
     or `kept-verifies` edge;
   - when `t` has no current definition in the tree of `M`, or a
     counting void in the tree of `M` withdraws `S`: no `observes` edge
     and no `kept-satisfies` or `kept-verifies` edge.
2. Check every promise edge of the `scope-object` `S` of each candidate
   `"delivered"` observation from rule 1 whose `observes` edge names a
   definition `D` and whose `scope-object` `S` is not withdrawn by a
   counting void in the tree of `H`. If any such promise edge fails to
   resolve in the tree of `M`, then the tree of `H`, then `K`
   (`task-scope`), or has no `job-promise-outcome` in the tree of `H`,
   the program must append nothing to the log branch, must return none
   of the named job results, must return one `conformance#report`
   naming each such promise edge, and must end with an error.
3. Otherwise (every checked promise edge resolves and has a
   `job-promise-outcome` in the tree of `H`), when the program finishes
   without stopping after refused pushes (`append-to-log-branch`), the
   program must return none of the named job results and must append to
   the log branch and push under `append-to-log-branch`:
   - each candidate `"delivered"` observation from rule 1 in order;
   - after all `"delivered"` observations of the run, one `"progress"`
     observation (`progress-acceptance-rule`) with `v`: `1`, `kind`:
     `"progress"`, `by`: the git identity for `R`, `seq`: the next
     sequence integer, `head`: the commit object name of `H`, and no
     `edges`; and
   - the kept objects of `H`.
   When every landing commit `M` of a commit in `C` on the
   `first-parent-line` of `H` has a valid `tree-object-store`, the
   program must end without an error. When at least one such landing
   commit `M` has an invalid `tree-object-store`, the program must
   return one `conformance#report` naming each such landing commit `M`
   and must end with an error.
4. When the program stops after refused pushes (`append-to-log-branch`),
   the program must end with an error.

@example Two subtle cases when appending delivered observations:

- Suppose a commit carrying a valid
  [delivery line](sinter:#delivery-line-form=v1) lands at a
  [landing commit](sinter:changes#landing-commit=v1) `M` whose
  [object store](sinter:object-store#tree-object-store=v1) is invalid,
  while a later head commit `H` fixes `.sinter/`. The job skips `M`,
  appends the `"progress"`
  [observation](sinter:ontology#observation=v1) and kept objects of
  `H`, reports `M`, and ends with an error. When the job skips a
  landing commit whose `.sinter/` store is invalid, a person can still
  record that skipped delivery with a `"done"`
  [judgment](sinter:ontology#judgment=v1).
- Suppose a [task](sinter:ontology#task=v1) has a current
  [definition statement](sinter:ontology#definition-statement=v1) `D`
  at `M` whose [scope object](sinter:ontology#scope-object=v1) `S` is
  not withdrawn in `M`, and a later counting
  [void statement](sinter:ontology#void-statement=v1) in `H` withdraws
  `S` ([object-withdrawal](sinter:ontology#object-withdrawal=v1)). The
  `"delivered"` observation still carries an `observes`
  [edge](sinter:ontology#edge=v1) naming `D`, omits all
  `kept-satisfies` and `kept-verifies` edges, and an unresolved promise
  of `S` does not stop the run.

### Rejecting invalid job runs

@req reject-invalid-job-run=v1
@cites {
    approval#persons=v1,
    changes#{
        default-branch-commit=v1, default-branch-name=v1,
        repository-read=v1, undisturbed-read=v1,
    },
    conformance#{conforming-program=v1, reject-invalid-inputs=v1},
    documents#{file-readers=v1, vector-files=v1},
    evidence#{import=v1, report-file=v1, tree-evidence=v1},
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ledger#{
        agent-marker=v1, agent-markers=v1, intact-history=v1,
        job-marker=v1, job-markers=v1, ledger-remote=v1,
        ledger-validity=v1, log-branch-name=v1,
    },
    object-store#tree-object-store=v1,
    ontology#{job=v1, log-branch=v1, parameter=v1},
    packs#{runner-settings=v1, test-runner=v1},
    #{git-identity=v1, job-range=v1},
}

When a `conforming-program` runs the `job` on a git repository `R` in a
job execution (`job-marker`), with undisturbed `repository-read`s
(`undisturbed-read`) for conditions 2 to 10, and any of the following
conditions holds, the program must append nothing to the `log-branch`,
return exactly one result, the quoted text of the first condition in
this list that holds (`reject-invalid-inputs`), and end with an error:

1. Any binding of the `parameter`s `file-readers`, `vector-files`,
   `default-branch-name`, `ledger-remote`, `log-branch-name`,
   `agent-markers`, `job-markers`, or (when bound) `approval#persons`
   is invalid, or `validate-bindings` returns `"invalid"` for
   `external-namespaces`: return `"invalid bindings"`.
2. The read repository `R′` (`job-range`) does not hold its log-branch
   objects: return `"missing ledger objects"`.
3. The log branch of `R′` is broken or newer (`ledger-validity`), or is
   not intact (`intact-history`): return `"invalid ledger"`.
4. The default branch of `R′` has no commit under `default-branch-name`
   (`default-branch-commit`): return `"no default branch commit"`.
5. Git has no identity (`git-identity`) for `R` in the execution's
   environment: return `"no git identity"`.
6. The execution is an agent execution (`agent-marker`): return
   `"agent execution"`.
7. `R′` does not hold the tree objects (`job-range`) of the default
   branch commit `H`: return `"cannot see range"`.
8. The tree of `H` has an invalid `tree-object-store`: return
   `"invalid object store"`.
9. The run status (`job-range`) for `R′` and `H` is cut, or is ready to
   record with range `C` while `R′` does not hold the landing trees of
   `C` for `H` (`job-range`): return `"cannot see range"`.
10. The run status for `R′` and `H` is ready to record with range `C`,
    `R′` holds the landing trees of `C` for `H`, and the tree of `H`
    has `tree-evidence` `V` with a `report-file` of an `import` whose
    `test-runner` has an invalid binding of `runner-settings`: return
    `"invalid bindings"`.

### Stopping the job at resource limits

@req fail-job-at-limits=v1
@cites {
    conformance#{
        conforming-program=v1, end-runs-at-limits=v1,
        resource-limit=v1, safety-obligation=v1,
    },
    ledger#change-no-ledger-after-stop=v1,
    ontology#{job=v1, log-branch=v1},
}

As a `safety-obligation`, when a `conforming-program` runs the `job`
and reaches a `resource-limit` (`end-runs-at-limits`), the program must
make no further append or update to the `log-branch` after reaching
that limit (`change-no-ledger-after-stop`) and must end with an error.

### Failing the job after a read error

@req fail-job-after-read-error=v1
@cites {
    conformance#{
        conforming-program=v1, input=v1, safety-obligation=v1,
    },
    files#directory=v1,
    ledger#write-no-log-after-read-error=v1,
    ontology#{job=v1, log-branch=v1},
}

As a `safety-obligation`, in a run of the `job` in which content of a
file, a `directory`, or a git object is a part that an `input` lacks
because a `conforming-program` could not read that content, the program
must make no append or update to the `log-branch`
(`write-no-log-after-read-error`) and must end with an error.

### Test vectors

@schema job-vector=v1
@cites {
    gitdoc/gitglossary,
    approval#persons=v1,
    changes#{
        commit=v1, default-branch-commit=v1, default-branch-name=v1,
        message-text=v1, repository-read=v1, shallow-commit=v1,
        undisturbed-read=v1,
    },
    conformance#{conforming-program=v1, own-store=v1},
    data-forms#{
        group-schema=v1, json-value=v1, test-vector-set=v1,
        vector-line=v1, vector-meaning=v1,
    },
    documents#{
        canonical-target=v1, file-readers=v1, vector-files=v1,
    },
    evidence#{
        import=v1, report-file=v1, tree-evidence=v1, tree-outcome=v1,
    },
    files#path=v1,
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    ledger#{
        agent-marker=v1, agent-markers=v1, intact-history=v1,
        job-marker=v1, job-markers=v1, ledger-remote=v1,
        ledger-validity=v1, log-branch-name=v1, needed-log-identity=v1,
        stored-ledger=v1,
    },
    object-store#tree-object-store=v1,
    ontology#{
        computed-identity=v1, content-id=v1, declared-item=v1, edge=v1,
        encoding=v1, job=v1, log-branch=v1, object=v1, object-kind=v1,
        observation=v1, parameter=v1, suspect-edge=v1, tree=v1,
    },
    packs#{runner-settings=v1, test-runner=v1},
    text#{code-point-order=v1, position=v1, span=v1},
    #{
        append-delivered-observations=v1, commit-object-name=v1,
        git-identity=v1, job-range=v1, reject-invalid-job-run=v1,
    },
}

`job-vector` is a `group-schema` for group `job` in
[work.test-vectors.jsonl](work.test-vectors.jsonl) and tests
`append-delivered-observations` and `reject-invalid-job-run`. That file
is a `test-vector-set` of `vector-line` entries whose meaning follows
`vector-meaning`. Group `job` uses no `needs` and omits `result`. Each
vector stands for one execution of a `conforming-program` running the
`job` on a git repository `R` in a job execution (`job-marker`) with
undisturbed `repository-read`s (`undisturbed-read`), where `R′` is the
read repository (`job-range`) and `H` is its `default-branch-commit`.

| field | type | meaning |
|---|---|---|
| `input.bindings` | object | ten boolean members for the `parameter`s `agent-markers`, `default-branch-name`, `external-namespaces`, `file-readers`, `job-markers`, `ledger-remote`, `log-branch-name`, `persons`, `runner-settings`, and `vector-files`: `true` when valid and `false` when invalid (`validate-bindings` for `external-namespaces`; `true` also covers unbound `approval#persons`; `false` for `runner-settings` means `H` has evidence and a `report-file` of an `import` has a `test-runner` with an invalid binding) |
| `input.persons` | array of strings (optional) | valid binding of `approval#persons`; omitted when unbound or invalid |
| `input.log` | string or object | `"missing-objects"` when `R′` lacks its log-branch objects; `"broken-or-newer"` when `R′` holds them and the `log-branch` is broken, newer (`ledger-validity`), or not intact (`intact-history`); otherwise `{"observations": [...], "kept": [...]}` holding stored `observation`s in `seq` order and kept `object`s (`stored-ledger`), both empty when missing |
| `input.commits[]` | array of objects | one object per `commit` of `R′` |
| `input.commits[].id` | string | `commit-object-name` of the commit |
| `input.commits[].parents` | array of strings | parent object names (`gitglossary`) in order; a name matching no `id` names a git object not in `R′` |
| `input.commits[].shallow` | boolean (optional) | `true` when the commit is a `shallow-commit` of `R′` |
| `input.commits[].text` | string (optional) | `message-text` of the commit; omitted when the message has no text |
| `input.commits[].missing-tree` | boolean (optional) | `true` when `R′` does not hold the tree objects of the commit |
| `input.commits[].store` | array of objects or `"invalid"` (optional) | canonical objects of the commit tree's `tree-object-store`, or `"invalid"` when invalid; when omitted, equal to `input.tree.store` |
| `input.default-branch` | string (optional) | `commit-object-name` of `H`; omitted when the default branch of `R′` has no commit |
| `input.tree` | object (optional) | summary of the tree of `H`; omitted when `default-branch` is omitted or `R′` lacks the tree objects of `H` |
| `input.tree.has-evidence` | boolean | `true` when the tree of `H` has `tree-evidence`, `false` otherwise |
| `input.tree.edges[]` | array of objects | edge summaries of the tree of `H` |
| `input.tree.edges[].kind` | string | `"satisfies"` or `"verifies"` |
| `input.tree.edges[].req` | string | requirement name targeted directly or through a vector set or group |
| `input.tree.edges[].fits` | boolean | `true` when the edge fits its kind (`ontology#edge`) and is not suspect (`suspect-edge`); `false` otherwise |
| `input.tree.edges[].source` | string | `"text"` for a text-file citation, `"store"` for a declared item in `.sinter/`, or `"own-store"` for a program's `own-store` |
| `input.tree.edges[].target-id` | string | `canonical-target` (`content-id`) |
| `input.tree.edges[].path` | string (optional) | valid `path` of the file for `"text"` and `"store"` |
| `input.tree.edges[].line` | integer (optional) | 1-based start line (`position`) of the citation entry for `"text"` |
| `input.tree.edges[].column` | integer (optional) | 1-based start column (`position`) of the citation entry for `"text"` |
| `input.tree.edges[].end-line` | integer (optional) | 1-based end line (`span`) of the citation entry for `"text"` |
| `input.tree.edges[].end-column` | integer (optional) | 1-based end column (`span`) of the citation entry for `"text"` |
| `input.tree.edges[].source-id` | string (optional) | `content-id` of the source declared item for `"own-store"` |
| `input.tree.edges[].test-outcome` | string (optional) | for a `"verifies"` edge when `has-evidence` is `true`: `"passed"`, `"failed"`, `"not run"`, or `"no-outcome"` (no `tree-outcome` in the evidence); when absent for a `"verifies"` edge while `has-evidence` is `true`, the test has neither `"passed"` nor `"no-outcome"` |
| `input.tree.store` | array of objects or `"invalid"` | canonical objects of the `tree-object-store` of `H`, or `"invalid"` when invalid |
| `input.tree.declared-items` | array of objects | canonical objects of the `declared-item`s of the tree of `H` in either `encoding` |
| `input.tree.requirements[]` | array of objects | one `{"id": string, "name": string}` entry per `req` item in `declared-items`, holding its `content-id` and name |
| `input.tree.needed-identities` | array of objects | canonical `computed-identity` objects needed by `declared-items` (`needed-log-identity`) |
| `input.identity` | string (optional) | `git-identity` for `R`; omitted when git has no identity for `R` |
| `input.agent` | boolean | `true` for an agent execution (`agent-marker`), `false` otherwise |
| `values.error` | boolean | `true` when the run ends with an error, `false` when it ends without an error |
| `values.appended-observations` | array of objects | appended `"delivered"` and `"progress"` canonical observations in append order |
| `values.appended-kept` | array of strings | `content-id`s of newly appended kept objects in `code-point-order` |
| `values.report` | string (optional) | one of these nine results (`"already recorded"`, `"cannot see range"`, `"invalid bindings"`, `"invalid ledger"`, `"invalid object store"`, `"missing ledger objects"`, `"no default branch commit"`, `"no git identity"`, `"agent execution"`); omitted when none is returned |

The `json-value` objects `input`, `input.bindings`, `input.log` (when
an object), `input.commits[]`, `input.tree`, `input.tree.edges[]`,
`input.tree.requirements[]`, and `values` hold only the members listed
in this table; nested canonical `object`s in `input.log.observations`,
`input.log.kept`, `input.commits[].store`, `input.tree.store`,
`input.tree.declared-items`, `input.tree.needed-identities`, and
`values.appended-observations` follow `ontology#object-kind`.

A `conforming-program` running the job on `input` returns the result of
`values.report` once (or none of those nine results when omitted), ends
with an error when `values.error` is `true` and without an error when
`false`, appends `values.appended-observations` in order, appends the
kept objects named by `values.appended-kept`, and appends no other
observation and no other kept object.

@example Sample lines testing
[appended deliveries](sinter:#append-delivered-observations=v1)
with [job-range](sinter:#job-range=v1) and
[job-promise-outcome](sinter:#job-promise-outcome=v1) on a first run
and on a scope withdrawn by a counting void in `H` only
([object-withdrawal](sinter:ontology#object-withdrawal=v1),
[vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#job-vector=v1","group":"job","input":{"agent":false,"bindings":{"agent-markers":true,"default-branch-name":true,"external-namespaces":true,"file-readers":true,"job-markers":true,"ledger-remote":true,"log-branch-name":true,"persons":true,"runner-settings":true,"vector-files":true},"commits":[{"id":"1111111111111111111111111111111111111111","parents":[],"text":"Initial\n"},{"id":"2222222222222222222222222222222222222222","parents":["1111111111111111111111111111111111111111"],"text":"Enforce limit\n\nDelivers: task:d3e073f4bae981aa8a042274c335422f 220c2c\n"},{"id":"3333333333333333333333333333333333333333","parents":["1111111111111111111111111111111111111111","2222222222222222222222222222222222222222"],"text":"Merge limit\n"},{"id":"4444444444444444444444444444444444444444","parents":["3333333333333333333333333333333333333333"],"text":"Verify limit\n\nDelivers: task:e1ade641a6990b8e16f8142d2cd54b01 56bf71\n"},{"id":"5555555555555555555555555555555555555555","parents":["3333333333333333333333333333333333333333","4444444444444444444444444444444444444444"],"text":"Merge test\n"}],"default-branch":"5555555555555555555555555555555555555555","identity":"Ada Lovelace <ada@example.com>","log":{"kept":[],"observations":[]},"tree":{"declared-items":[{"edges":[{"kind":"about","to":"name:2f5499ffd40584baddb649053699467a"}],"kind":"req","label":"v1","name":"billing#limit","text":"Billing must reject charges over the limit.","v":1}],"edges":[{"column":1,"end-column":25,"end-line":1,"fits":true,"kind":"satisfies","line":1,"path":"src/billing/a.ml","req":"billing#limit","source":"text","target-id":"name:2f5499ffd40584baddb649053699467a"},{"column":1,"end-column":25,"end-line":1,"fits":true,"kind":"verifies","line":1,"path":"test/billing/a_test.ml","req":"billing#limit","source":"text","target-id":"name:2f5499ffd40584baddb649053699467a","test-outcome":"passed"}],"has-evidence":true,"needed-identities":[],"requirements":[{"id":"req:e8db5e696c34e0701a9c0725effe7c1e","name":"billing#limit"}],"store":[{"kind":"task","nonce":"00000000000000000000000000000001","v":1},{"kind":"task","nonce":"00000000000000000000000000000002","v":1},{"kind":"name","name":"billing#limit","v":1},{"edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"promises-satisfies","to":"name:2f5499ffd40584baddb649053699467a"}],"kind":"scope","paths":["src/billing/**"],"v":1},{"edges":[{"kind":"about","to":"task:e1ade641a6990b8e16f8142d2cd54b01"},{"kind":"promises-verifies","to":"name:2f5499ffd40584baddb649053699467a"}],"kind":"scope","paths":["test/billing/**"],"v":1},{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"scoped-by","to":"scope:220c2c3804849c2931b1a19666cedd6c"}],"kind":"task-def","name":"Enforce billing limit","v":1},{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"task:e1ade641a6990b8e16f8142d2cd54b01"},{"kind":"scoped-by","to":"scope:56bf71390007ccb491b7eedf7fc754e9"}],"kind":"task-def","name":"Verify billing limit","v":1}]}},"note":"first run appends delivered observations in parents-first order, one progress observation, and kept declared items","values":{"appended-kept":["req:e8db5e696c34e0701a9c0725effe7c1e"],"appended-observations":[{"by":"Ada Lovelace <ada@example.com>","commit":"2222222222222222222222222222222222222222","edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"kept-satisfies","to":"req:e8db5e696c34e0701a9c0725effe7c1e"},{"kind":"observes","to":"task-def:3534f53b5f704a01e6efe76b0cbdb53d"}],"hash":"220c2c","head":"5555555555555555555555555555555555555555","kind":"delivered","merge":"3333333333333333333333333333333333333333","seq":1,"v":1},{"by":"Ada Lovelace <ada@example.com>","commit":"4444444444444444444444444444444444444444","edges":[{"kind":"about","to":"task:e1ade641a6990b8e16f8142d2cd54b01"},{"kind":"kept-verifies","to":"req:e8db5e696c34e0701a9c0725effe7c1e"},{"kind":"observes","to":"task-def:9ddd16473db0d9cca2c9e78461cbcf1d"}],"hash":"56bf71","head":"5555555555555555555555555555555555555555","kind":"delivered","merge":"5555555555555555555555555555555555555555","seq":2,"v":1},{"by":"Ada Lovelace <ada@example.com>","head":"5555555555555555555555555555555555555555","kind":"progress","seq":3,"v":1}],"error":false}}
{"form":"#job-vector=v1","group":"job","input":{"agent":false,"bindings":{"agent-markers":true,"default-branch-name":true,"external-namespaces":true,"file-readers":true,"job-markers":true,"ledger-remote":true,"log-branch-name":true,"persons":true,"runner-settings":true,"vector-files":true},"commits":[{"id":"1111111111111111111111111111111111111111","parents":[],"store":[{"kind":"task","nonce":"00000000000000000000000000000001","v":1},{"kind":"name","name":"billing#limit","v":1},{"edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"promises-satisfies","to":"name:2f5499ffd40584baddb649053699467a"}],"kind":"scope","paths":["src/billing/**"],"v":1},{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"scoped-by","to":"scope:220c2c3804849c2931b1a19666cedd6c"}],"kind":"task-def","name":"Enforce billing limit","v":1}],"text":"Enforce limit\n\nDelivers: task:d3e073f4bae981aa8a042274c335422f 220c2c\n"},{"id":"2222222222222222222222222222222222222222","parents":["1111111111111111111111111111111111111111"],"text":"Withdraw scope\n"}],"default-branch":"2222222222222222222222222222222222222222","identity":"Ada Lovelace <ada@example.com>","log":{"kept":[],"observations":[]},"tree":{"declared-items":[{"edges":[{"kind":"about","to":"name:2f5499ffd40584baddb649053699467a"}],"kind":"req","label":"v1","name":"billing#limit","text":"Billing must reject charges over the limit.","v":1}],"edges":[{"column":1,"end-column":25,"end-line":1,"fits":true,"kind":"satisfies","line":1,"path":"src/billing/a.ml","req":"billing#limit","source":"text","target-id":"name:2f5499ffd40584baddb649053699467a"}],"has-evidence":true,"needed-identities":[],"requirements":[{"id":"req:e8db5e696c34e0701a9c0725effe7c1e","name":"billing#limit"}],"store":[{"kind":"task","nonce":"00000000000000000000000000000001","v":1},{"kind":"name","name":"billing#limit","v":1},{"edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"promises-satisfies","to":"name:2f5499ffd40584baddb649053699467a"}],"kind":"scope","paths":["src/billing/**"],"v":1},{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"scoped-by","to":"scope:220c2c3804849c2931b1a19666cedd6c"}],"kind":"task-def","name":"Enforce billing limit","v":1},{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"withdraws","to":"scope:220c2c3804849c2931b1a19666cedd6c"}],"kind":"void","reason":"withdrawn after landing","v":1,"withdrawn-kind":"scope"}]}},"note":"scope withdrawn by counting void in H only records delivery with observes edge and no kept edges","values":{"appended-kept":["req:e8db5e696c34e0701a9c0725effe7c1e"],"appended-observations":[{"by":"Ada Lovelace <ada@example.com>","commit":"1111111111111111111111111111111111111111","edges":[{"kind":"about","to":"task:d3e073f4bae981aa8a042274c335422f"},{"kind":"observes","to":"task-def:3534f53b5f704a01e6efe76b0cbdb53d"}],"hash":"220c2c","head":"2222222222222222222222222222222222222222","kind":"delivered","merge":"1111111111111111111111111111111111111111","seq":1,"v":1},{"by":"Ada Lovelace <ada@example.com>","head":"2222222222222222222222222222222222222222","kind":"progress","seq":2,"v":1}],"error":false}}
```
