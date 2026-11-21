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
@cites findings=v1
@cites packs=v1
@cites documents=v1
@cites ledger=v1
@cites evidence=v1
@cites rfc/5234
@cites rfc/7405
@cites rfc/8259
@cites gitdoc/gitglossary
@cites gitdoc/git
@cites gitdoc/git-commit
@cites gitdoc/git-config
Specifies the parameter `exempt-paths`; work item ids, commit object names, task promises, and task hashes; the fields and acceptance rules of `task`, `plan`, `done`, `abandoned`, and `delivered` ledger entries; the forms of delivery lines and task lines; promise outcomes in the job and in findings; the job on the default branch; the path check and files that only re-pin; the finding classes `malformed-delivery`, `stale-delivery`, `delivery-on-unmet-task`, `missing-delivery`, `delivery-without-change`, `unplanned-change`, `promise-outside-paths`, and `unmet-promise`; and requirements for conforming programs that assign ids, compute task hashes, read message lines, decide acceptance, compute task states, plan states, readiness, and requirement accounting, append `done` and `delivered` ledger entries, and give these findings.

Tasks and plans record planned work in the ledger of a git repository,
and commits name the tasks whose work they advance or finish in task
lines and delivery lines. A task definition fixes a task's display name,
paths, promises, waits, optional plan, and optional external item. A
plan definition fixes a plan's display name, waits, optional plan, and
carried-out items. Acceptance rules decide which ledger entries of the
five work kinds can stand at each point of a ledger, and the accepted
entries give each work item's state, each task's readiness, and which
requirements work accounts for. On the default branch, the job records
each qualifying delivery line of an existing task that no earlier
accepted entry records in a `delivered` ledger entry with the labels,
extent hashes, and promise outcomes observed in the tree of the commit
of the default branch. On branches and trees, eight finding classes
check delivery lines, promises, and whether changed files lie inside the
paths of the tasks of the change or the exempt paths.

From Text and notation (`text`), the design takes characters, spaces,
tabs, line feeds, texts, whole numbers, decimal numerals, hex digits,
code point order, places, boundaries, runs, lines, line numbers,
code spans, the notation of productions, rule names, and algorithms,
valid UTF-8, and what a conforming program, an input, and a result are.
From Identifiers (`identifiers`), it takes slugs, full names, labels,
revisions, citations, citation lines, citation entries, matches,
external ids, bindings of the parameter `external-namespaces`, and the
result "valid" of such a binding. From Files and paths (`files`), it
takes valid paths, path sets, valid path sets, and path-set membership. From Data forms
(`data-forms`), it takes indexes, JSON values, canonical forms,
canonical byte sequences, hashes, hash forms, id prefixes, hash-id
forms, test-vector sets, vector lines, the forms of a group, and the
meaning of a vector.

From the Ontology (`ontology`), the design takes trees, persons, jobs,
declared items, containment, item names, current revisions, revised
content, edges, `satisfies` edges, `verifies` edges, suspect edges,
tests, conformance vectors, groups of conformance vectors, vector sets,
work items, tasks, promises, plans, waits, carried-out items, work item
definitions, delivery lines, task lines, ledger entries, the ledger and
its points, definition entries, judgments, records of the job, work item
states, met waits, ready tasks, accounted-for requirements, finding
classes, and parameters. From Changes (`changes`), it takes commits,
shallow commits, the texts of commit messages, git configurations, the
parameter `default-branch-name`, the commit of the default branch, the
files of the tree of a commit, ancestry, reach, commit ranges,
parents-first order, changes of commits, bases of changes, first-parent
lines, landing commits, line texts, hunks, change diffs, repository reads, undisturbed reads,
and fetches. From Findings (`findings`), it takes the subjects and spots of findings. From Language packs (`packs`), it takes
test runners and bindings of the parameter `runner-settings`. From
Documents (`documents`), it takes bindings of the parameter
`file-readers`, read files, tag texts, accepted
inputs, origins, origin positions, the order of positions, extent
hashes, the edges of a tree, the spots of runs, and tree findings. From
the Ledger (`ledger`), it takes agent markers, job markers, ledger refs, the fields
of a kind of ledger entry, acceptance rules, valid ledgers, ledger
objects, stored ledgers, and the requirement leaving `delivered` entries
to the job.
From Test evidence (`evidence`), it takes report files, imports,
readings of report files, tree evidence, test outcomes in the evidence
for a tree, and the requirement to give the sources of kept `verifies`
promises.

The productions are written in ABNF, the notation of RFC 5234, with the
case-sensitive strings `%s"..."` of RFC 7405. From RFC 8259, the design
takes JSON texts, with their objects, members, arrays, strings, numbers,
and the literal names `true` and `false`. From the git manual pages
`gitglossary`, `git`, `git-commit`, and `git-config`, it takes commit
objects, their object names, and git's configured committer identity in
an environment and git configuration.

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
| [fields of a `delivered` ledger entry](sinter:#delivered-field=v1) | `work-item`, `commit`, `merge`, `head`, `hash`, `definitions`, and `promises` |
| [work-graph cycle](sinter:#work-graph-cycle=v1) | a cycle in the composition edges from plans to their parts or in the combined directed graph of composition edges, direct waits, and waits inherited from plans by their parts |
| [acceptance rule](sinter:ledger#accepted-entry=v1), [accepted](sinter:ledger#accepted-entry=v1) | the condition under which a ledger entry of a given kind can stand at a point of a ledger; a ledger entry is accepted at a point when the acceptance rule of its kind holds for it there |
| [delivered task completion](sinter:#delivered-task-completion=v1) | the condition under which an accepted `delivered` ledger entry records that a delivery line named the current definition of its task and that every promise of that definition was kept |
| [recorded requirement content](sinter:#recorded-requirement-content=v1) | the condition under which an accepted `done` or `delivered` ledger entry records both the current revision and the same revised content of a requirement in a tree |
| [delivery line](sinter:#delivery-line-form=v1), [malformed delivery line](sinter:#delivery-line-form=v1) | a line matching `Delivers: t-<12 hex> <6 hex>` with optional trailing spaces, tabs, or carriage returns; a line that starts with `Delivers:` after optional spaces or tabs and does not match that form |
| [task line](sinter:#task-line-form=v1) | a line matching `Task: t-<12 hex>` with optional trailing spaces, tabs, or carriage returns |
| [counts at a point](sinter:#counting-delivery-line=v1) | a delivery line counts at a point of a ledger when its task exists at that point and its six hex digits are the first six characters of the task hash of the current definition of that task at that point |
| [job promise outcome](sinter:#job-promise-outcome=v1) | the outcome that the job records for a promise of a task definition in a tree: `"kept"` or `"not-kept"` |
| [class promise outcome](sinter:#class-promise-outcome=v1) | the outcome that the finding classes of Work read for a promise of a task definition in a tree: `"known kept"`, `"known not kept"`, or `"not known"` |
| [known to keep a promise outside the paths](sinter:#outside-promise-edge=v1) | an edge whose file is outside a task definition's paths and that would keep a promise of that definition in a tree; for a `verifies` promise, only when the tree has evidence and the test of the edge passed |
| [range of a run](sinter:#job-range=v1), [run status](sinter:#job-range=v1) | the status of a run of the job for a git repository and the commit of the default branch: already recorded, ready to record (with a commit range to the commit of the default branch), or cut when missing commits or shallow commits keep the git repository from deciding the range |
| [git identity](sinter:#git-identity=v1) | the configured committer identity `Name <email>` that git's environment variables and configuration give, excluding any guessed default |
| [ends with an error](sinter:#job-end=v1), [ends without an error](sinter:#job-end=v1) | the two mutually exclusive ways in which an execution of the job ends |
| [tasks of a change](sinter:#change-task=v1) | the existing tasks named by delivery lines or task lines in the commits of the change of a commit |
| [only re-pins](sinter:#repin-only-file=v1) | a read file that can be read in both trees, with the same number of line texts, whose differing lines each hold at least one citation pin and differ only in citation pins, with each changed new pin equal to the current revision of its cited item |
| [path-finding subject](sinter:#path-finding-subject=v1) | the valid path of a changed file, or `/` followed by the valid path with `%`, line feed, space, and tab percent-encoded when the valid path holds a line feed or starts or ends with a space or a tab |
| [tree finding](sinter:documents#tree-finding=v1) | a finding of one tree, with a class, a subject, and either a spot or no spot, that is not ackable |
| [`malformed-delivery`](sinter:#malformed-delivery-finding=v1) | the class of the findings for a malformed delivery line |
| [`stale-delivery`](sinter:#stale-delivery-finding=v1) | the class of the findings for a delivery line that does not count |
| [`delivery-on-unmet-task`](sinter:#delivery-on-unmet-task-finding=v1) | the class of the findings for a task with a counting delivery line in the change and a promise known not kept in the tree |
| [`missing-delivery`](sinter:#missing-delivery-finding=v1) | the class of the findings for an unfinished task with promises, no counting delivery line in the change, every promise known kept in the tree, and some promise known not kept in the base tree |
| [`delivery-without-change`](sinter:#delivery-without-change-finding=v1) | the class of the findings for a task with a counting delivery line in the change when no changed file with a hunk lies in its paths |
| [`unplanned-change`](sinter:#unplanned-change-finding=v1) | the class of the findings for a changed file with a hunk outside the paths of the tasks of the change and outside the exempt paths that does not only re-pin |
| [`promise-outside-paths`](sinter:#promise-outside-paths-finding=v1) | the class of the findings for a promise of an unfinished task that is known not kept while an edge outside the task's paths is known to keep it |
| [`unmet-promise`](sinter:#unmet-promise-finding=v1) | the class of the findings for a promise of an unfinished task that is known not kept in the tree |

## 2. Tasks, plans, delivery, and states

### 2.1 Work item ids and definitions

Each task has a [task id](sinter:#work-item-id=v1) such as
`t-3f2a9c1d07e4`, and each plan has a [plan id](sinter:#work-item-id=v1)
such as `p-0a1b2c3d4e5f`. When a program creates a new task or plan, it
chooses an id of the right form that no existing work item has at the
point of the first definition entry (requirement
`assign-new-work-item-id`).

A `task` ledger entry records one whole definition of a task (schema
`task-field`), and a `plan` ledger entry records one whole definition of
a plan (schema `plan-field`). A task whose `paths` is empty (`[]`)
changes no files, so a counting delivery line for it in a change with a
base gives `delivery-without-change`. When such a task has at least one
promise, no edge can keep that promise, so only a `done` entry can make
the task done. For example, a `task` ledger entry with common fields looks
like this:

```
{"by":"Ada Lovelace <ada@example.com>","def":1,"id":"e-e137e6aa912bea710e6643ab32328a8e","kind":"task","name":"Enforce billing limit","paths":["src/billing/**","!src/billing/generated/**"],"promises":[{"kind":"satisfies","req":"billing#limit"},{"kind":"verifies","req":"billing#limit"}],"seq":1,"v":1,"waits":[],"work-item":"t-3f2a9c1d07e4"}
```

A `plan` ledger entry carries `carries-out` in place of `paths`,
`promises`, and `item`. For example:

```
{"by":"Ada Lovelace <ada@example.com>","carries-out":["billing"],"def":1,"id":"e-46b1cc64df481653a26f4c8378803040","kind":"plan","name":"Billing rollout","seq":2,"v":1,"waits":[],"work-item":"p-0a1b2c3d4e5f"}
```

### 2.2 Acceptance of the five work kinds

Each of the five kinds `task`, `plan`, `done`, `abandoned`, and
`delivered` has an acceptance rule: `definition-acceptance-rule` for
`task` and `plan`, `work-judgment-acceptance-rule` for `done` and
`abandoned`, and `delivered-acceptance-rule` for `delivered`. Every
acceptance rule reads only the candidate ledger entry and the ledger
entries before its point, and never a tree, a commit, a binding, or test
evidence.

Condition 6 of `definition-acceptance-rule` refuses a definition for
which the term `work-graph-cycle` finds a cycle of plans and their
parts, a cycle of waits, or a cycle that mixes both. For example, plan `p1`
under `p2` and `p2` under `p1` forms a cycle of plans; `t1` waiting for
`t2` and `t2` waiting for `t1` forms a cycle of waits; and because every
work item under a plan inherits the waits of that plan, a plan waiting
for one of its own parts forms a cycle from that part to itself, and a
task under `p1` waiting for `t2` under `p2` while `p2` waits for `p1`
forms a cycle through both plans.

Under these rules, a done plan can still be edited and a new part can
name a done plan and reopen it, while an abandoned plan and a done or
abandoned task stay closed. A `delivered` entry for a task that is
already done or abandoned is still accepted as a recorded fact, and it
changes no state of any task or plan. For a done task, such an entry can
still account for a requirement (atom `recorded-requirement-content`).

### 2.3 Task hashes, delivery lines, and task lines

The term `task-hash` gives the
[task-hash pre-image](sinter:#task-hash=v1) and
[task hash](sinter:#task-hash=v1) of a task definition from its `paths`
and `promises` (using [promise order](sinter:#task-promise=v1)). For
example, changing a task's display name or waits keeps the same task
hash.

A [delivery line](sinter:#delivery-line-form=v1) in a commit message has
the form `Delivers: t-3f2a9c1d07e4 0e515c`, with optional spaces, tabs,
or carriage returns at the end of the line. A delivery line can stand on
any line of a commit message. A [task line](sinter:#task-line-form=v1)
has the form `Task: t-3f2a9c1d07e4` with no hash. The term
`counting-delivery-line` gives when a delivery line
[counts at a point](sinter:#counting-delivery-line=v1) of a ledger,
whatever the task's state.

### 2.4 States, readiness, and requirement accounting

The atom `delivered-task-completion` gives the condition on `delivered`
entries that task states, plan states, and readiness read, and the atom
`recorded-requirement-content` gives the condition on `done` and
`delivered` entries that requirement accounting reads. For example, in
a `delivered` entry, a promise with the outcome `not-kept`, or with the
outcome `kept` and neither `label` nor `extent-hash`, counts as not kept,
so the task becomes delivered rather than done.
When a program appends a `done` entry to record that a person judged the
work of a task finished, requirement `record-done-requirements` governs
what the entry records for each promised requirement in the judged tree,
and requirement `omit-work-writes-at-limits` forbids appending a work
entry when a computation whose result it would record stops at a limit.

What a program gives while another process changes a file, a ref, or the
ledger is a matter of the quality of an implementation.

### 2.5 Promises in trees and in the job

The job on the default branch (atom `job-promise-outcome` and
requirement `give-job-promise-outcomes`) and the finding classes of Work
(terms `class-promise-outcome` and `outside-promise-edge`) judge a
`verifies` promise differently when a tree has no evidence.

For example, in a tree with no evidence, the job records `"not-kept"`
for a `verifies` promise, while the finding classes read `"not known"`
when the tree holds a qualifying `verifies` edge inside the task's
paths (`class-promise-outcome`). A promise with the outcome `"not
known"` never causes a finding of `delivery-on-unmet-task`,
`missing-delivery`, `promise-outside-paths`, or `unmet-promise`, and in
the tree of `h` it prevents a finding of `missing-delivery` (atom
`missing-delivery-finding`).

### 2.6 The job on the default branch

The job reads the stored ledger of the git repository (term
`ledger#stored-ledger`), reads the git repository after any fetches that
the run makes before or during its repository reads (term `job-range`),
and runs on the commit `H` of the default branch under
`default-branch-name`, when the environment of a process of the
execution holds a job marker (term `ledger#job-marker`). The
requirements of the job check its inputs in one order: valid bindings of
`file-readers`, `external-namespaces`, and `default-branch-name`
(requirement `reject-job-under-invalid-bindings`), a read repository
that holds its ledger objects (requirement
`reject-job-without-ledger-objects`), a valid ledger (requirement
`reject-job-on-invalid-ledger`), a commit `H` on the default branch
(requirement `reject-job-without-default-branch`), a
[git identity](sinter:#git-identity=v1) in the environment (requirement
`reject-job-without-git-identity`), and no agent marker in the
environment of a process of the execution (term `ledger#agent-marker`,
requirement `reject-job-under-agent-marker`).

When all six checks hold, the term `job-range` gives the
[run status](sinter:#job-range=v1) on the read repository and `H`.
Requirements `report-already-recorded-head`, `report-cut-job-range`,
`reject-job-under-invalid-bindings` (for bindings of `runner-settings`
of the evidence for the tree of `H`), `append-delivered-entries`, and
`fail-job-at-limits` govern the outcome, whether the run
[ends with an error](sinter:#job-end=v1), and the appended `delivered`
entries. For example, if one push brings merge `M1` (with a delivery line for `t1`) and then merge `M2` (with a
delivery line for `t2`), with `H = M2`, both `delivered` entries record
`head = M2`, the entry for `M1` records `merge = M1`, the entry for `M2`
records `merge = M2`, and both record labels, extent hashes, and promise
outcomes observed in the tree of `M2`.

### 2.7 The path check and re-pins

The parameter `exempt-paths` (schema `exempt-paths`) names a valid path
set whose files may change without a task. For example, adding `docs/**`
to `exempt-paths` lets a commit change `docs/guide.md` without a task,
while a `@satisfies` citation in `docs/guide.md` still does not keep a
promise of a task whose paths are `src/**`.

When the default branch has a commit, the term `change-task` gives the
[tasks of a change](sinter:#change-task=v1) for a commit `h`. Each such
task contributes the paths of its current definition at the point; for
example, a well-formed delivery line whose six digits are stale still
contributes its existing task's paths, while a malformed delivery line
or a line naming no existing task contributes none.

The atom `unplanned-change-finding` uses the term `repin-only-file` to
exempt files that [only re-pin](sinter:#repin-only-file=v1),
and uses the term `path-finding-subject` for each finding's subject.
For example, updating a citation pin on a tag line or in a code comment
to the cited item's current revision only re-pins, while editing an
inline citation in prose, a vector-line form pin, text inside a fenced
code block, or a file that cannot be read never only re-pins.
As examples of [path-finding subject](sinter:#path-finding-subject=v1),
the file ` run.sh` has the subject `/%20run.sh` and the spot ` run.sh`,
and a deleted file `tmp.txt ` has the subject `/tmp.txt%20` and no
spot.

### 2.8 Findings, missing bases, and bindings

Each of these eight classes gives [tree findings](sinter:documents#tree-finding=v1).
No finding of these classes is ackable.

| class | atom |
|---|---|
| `malformed-delivery` | [`malformed-delivery-finding`](sinter:#malformed-delivery-finding=v1) |
| `stale-delivery` | [`stale-delivery-finding`](sinter:#stale-delivery-finding=v1) |
| `delivery-on-unmet-task` | [`delivery-on-unmet-task-finding`](sinter:#delivery-on-unmet-task-finding=v1) |
| `missing-delivery` | [`missing-delivery-finding`](sinter:#missing-delivery-finding=v1) |
| `delivery-without-change` | [`delivery-without-change-finding`](sinter:#delivery-without-change-finding=v1) |
| `unplanned-change` | [`unplanned-change-finding`](sinter:#unplanned-change-finding=v1) |
| `promise-outside-paths` | [`promise-outside-paths-finding`](sinter:#promise-outside-paths-finding=v1) |
| `unmet-promise` | [`unmet-promise-finding`](sinter:#unmet-promise-finding=v1) |

Requirements `give-work-tree-findings`, `give-work-commit-findings`,
and `give-work-change-findings` govern the findings of these eight
classes: `promise-outside-paths` and `unmet-promise` read one tree;
`malformed-delivery` and `stale-delivery` read the commits of the change
of `h`; `delivery-on-unmet-task` reads those commits and the tree of
`h`; and `missing-delivery`, `delivery-without-change`, and
`unplanned-change` also read the base of the change of `h`. Requirements
`omit-work-missing-base-report`, `report-work-missing-base`, and
`omit-work-findings-under-invalid-bindings` govern changes with no base
and bindings of `exempt-paths` that are not valid.

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
object q1 comes before a promise object q2 that is not equal to q1 when,
and only when, one of these two conditions is true:

1. The value of `kind` of q1 comes before the value of `kind` of q2 in
   code point order.
2. The value of `kind` of q1 and the value of `kind` of q2 are the same
   text, and the value of `req` of q1 comes before the value of `req` of
   q2 in code point order.

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

For a valid path set G and a finite set Q of promise objects in which no
two promise objects are equal, the task-hash object of G and Q is the
JSON object with exactly two members:

- `paths`, an array whose elements are the path set members of G, each
  as a string, in code point order;
- `promises`, an array whose elements are the promise objects of Q, in
  promise order.

The task-hash pre-image of G and Q is the canonical form of the
task-hash object of G and Q. The task hash of G and Q is the hash of the
canonical byte sequence of the task-hash object of G and Q. For a
definition of a task whose paths are G and whose promises are Q, the
task-hash pre-image of that definition is the task-hash pre-image of G
and Q, and the task hash of that definition is the task hash of G and Q.

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
   is a label, and the member `extent-hash`, whose value is a string
   that fits the hash form; or it has neither `label` nor `extent-hash`.
3. It has no member other than `req`, `label`, and `extent-hash`.

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

1. It has the member `task-hash`, whose value is a string that fits the
   hash form; the member `kind`, whose value is the string `satisfies`
   or the string `verifies`; and the member `req`, whose value is a
   string that matches the production `slug` or the production
   `full-name` of Identifiers.
2. It has the member `outcome`, whose value is one of the strings `kept`
   and `not-kept`.
3. Either it has both the member `label`, whose value is a string that
   is a label, and the member `extent-hash`, whose value is a string
   that fits the hash form; or it has neither `label` nor `extent-hash`.
4. It has no member other than `task-hash`, `kind`, `req`, `outcome`,
   `label`, and `extent-hash`.

The fields of the kind `delivered` are these required fields, with these
values:

- `work-item`, a string that is a task id;
- `commit`, a string that is a commit object name;
- `merge`, a string that is a commit object name;
- `head`, a string that is a commit object name;
- `hash`, a string that is a short task hash;
- `definitions`, an array of strings that each fit the hash form and
  whose first six characters are the value of `hash` of the ledger
  entry, in which no two elements are the same text;
- `promises`, an array of promise observations in which the value of
  `task-hash` of each element is an element of `definitions` of the
  ledger entry, and in which no two elements have the same value of
  `task-hash`, the same value of `kind`, and the same value of `req`.

A ledger entry of the kind `delivered` meets the schema
`delivered-field` when, and only when, its object has each required
field of the kind `delivered` with a value of the form that this schema
gives.

### 4.11 Cycles of plans and waits

@term work-graph-cycle=v1
@cites {
    ledger#{accepted-entry=v1},
    ontology#{
        work-item=v1, task=v1, plan=v1, wait=v1,
        work-item-definition=v1, work-item-state=v1, ledger=v1,
        ledger-entry=v1,
    },
    text#{whole-number=v1, code-span=v1},
    #{delivered-task-completion=v1},
}

For a point P of a ledger, a task or plan w, and a candidate definition
d for w, let W be the set of all work items that exist at P together
with w. The effective definition of w is d, and the effective definition
of each other work item in W is its current definition at P.

A composition edge is a pair (p, x) of a plan p in W and a work item x
in W such that the effective definition of x names p as the plan of x, x
is not abandoned at P, and there is no accepted `abandoned` ledger entry
for p before P at whose point x was not done. A composition cycle is a
finite sequence of one or more
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

A work-graph cycle exists for w and d at P when, and only when, either a
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
        work-graph-cycle=v1, delivered-task-completion=v1,
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
    #{
        work-item-id=v1, done-field=v1, abandoned-field=v1,
        delivered-task-completion=v1,
    },
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
4. For each element g of `definitions` of E, there is an accepted `task`
   ledger entry at an index before P whose `work-item` is the
   `work-item` of E and whose definition has g as its task hash, and the
   set of pairs of `kind` and `req` of the elements of `promises` of E
   whose value of `task-hash` is g is the set of pairs of `kind` and
   `req` of the promises of that definition.

### 4.15 Task completion by `delivered` ledger entries

@atom delivered-task-completion=v1
@refines ontology#work-item-state=v1
@cites {
    ledger#{accepted-entry=v1},
    ontology#{
        ledger=v1, ledger-entry=v1, task=v1, work-item-definition=v1,
        job-record=v1,
    },
    data-forms#{json-value=v1},
    text#{text=v1, code-span=v1},
    #{delivered-field=v1, task-hash=v1},
}

In the atom `ontology#work-item-state`, for an accepted `delivered`
ledger entry E of a task t at its point P, let g be the task hash of the
definition of t that was current at P. E records that the job observed
that a delivery line of t named that current definition and that each
promise of that definition was kept when, and only when, both of these
conditions are true:

1. The member `definitions` of E holds g.
2. Every element of `promises` of E whose value of `task-hash` is g has
   the value `kept` for `outcome`, and has both `label` and
   `extent-hash`.

### 4.16 Recorded requirement content for requirement accounting

@atom recorded-requirement-content=v1
@refines ontology#requirement-accounted-for=v1
@cites {
    ledger#{accepted-entry=v1},
    ontology#{
        ledger=v1, ledger-entry=v1, task=v1, work-item-definition=v1,
        work-item-state=v1, judgment=v1, job-record=v1,
        declared-item=v1, item-name=v1, item-revision=v1,
        revised-content=v1, tree=v1, parameter=v1,
    },
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1, extent-hash=v1},
    data-forms#{json-value=v1},
    text#{conforming-program=v1, result=v1, text=v1, code-span=v1},
    #{done-field=v1, delivered-field=v1, task-hash=v1},
}

In the atom `ontology#requirement-accounted-for`, for a tree T, a valid
binding F of `file-readers`, a binding N of `external-namespaces` for
which a conforming program of Identifiers gives the result "valid", and
an item r of the kind requirement of T under F and N:

- An accepted `done` ledger entry E records both the current revision of
  r in T and the same revised content as the revised content of r in T
  for r when, and only when, `requirements` of E holds an element whose
  `req` is the name of r in T, that element has both `label` and
  `extent-hash`, the value of `label` of that element is the current
  revision of r in T, and the value of `extent-hash` of that element is
  the extent hash of r in T under F and N.
- An accepted `delivered` ledger entry E at its point P records both the
  current revision of r in T and the same revised content as the revised
  content of r in T for a promise of the definition of its task that was
  current at P when, and only when, `definitions` of E holds the task
  hash g of that current definition, and `promises` of E holds an
  element whose value of `task-hash` is g and whose `req` is the name of
  r in T, that element has both `label` and `extent-hash`, the value of
  `label` of that element is the current revision of r in T, and the
  value of `extent-hash` of that element is the extent hash of r in T
  under F and N.

### 4.17 The form of delivery lines

@schema delivery-line-form=v1
@cites {
    rfc/5234,
    rfc/7405,
    ontology#{delivery-line=v1},
    text#{
        text=v1, line=v1, space=v1, tab=v1, hex-digit=v1,
        production=v1, rule-name=v1, code-span=v1,
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
that line starts with zero or more spaces or tabs followed by
`Delivers:` and the line does not meet the schema `delivery-line-form`.

### 4.18 The form of task lines

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

### 4.19 Delivery lines that count

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

### 4.20 Promise outcomes in the job

@atom job-promise-outcome=v1
@cites {
    ontology#{
        promise=v1, tree=v1, task=v1, work-item-definition=v1, edge=v1,
        satisfies-edge=v1, verifies-edge=v1, suspect-edge=v1, test=v1,
        parameter=v1,
    },
    files#{path-set-membership=v1},
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1, tree-edge=v1},
    packs#{runner-settings=v1, test-runner=v1},
    evidence#{import=v1, report-file=v1, tree-evidence=v1, tree-outcome=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{task-promise=v1},
}

This atom applies for a tree T, a valid binding F of `file-readers`, a
binding N of `external-namespaces` for which a conforming program of
Identifiers gives the result "valid", the evidence V for T, and, when T
has evidence, valid bindings of `runner-settings` for the test runners
of the report files of the imports of V.

For a task definition d and a promise q of d, the job promise outcome
of q for d in T under F, N, V, and those bindings of `runner-settings`
is one of "kept" and "not-kept":

- When q has the kind `satisfies`, the job promise outcome is "kept"
  when q is kept in T under F and N by `ontology#promise`, with the
  paths of d as the paths of the task, and "not-kept" otherwise.
- When q has the kind `verifies`, the job promise outcome is "kept" when
  T has evidence and q is kept in T under F, N, and V by
  `ontology#promise` and `evidence#tree-outcome`, with the paths of d as
  the paths of the task, and "not-kept" otherwise.

### 4.21 Promise outcomes in findings

@term class-promise-outcome=v1
@cites {
    ontology#{
        promise=v1, tree=v1, task=v1, work-item-definition=v1, edge=v1,
        verifies-edge=v1, suspect-edge=v1, test=v1,
        declared-item=v1, item-name=v1, conformance-vector=v1,
        conformance-vector-group=v1, vector-set=v1, parameter=v1,
    },
    files#{path=v1, path-set-membership=v1},
    data-forms#{group-form-list=v1},
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1, read-file=v1, tree-edge=v1},
    packs#{runner-settings=v1, test-runner=v1},
    evidence#{
        import=v1, report-file=v1, tree-evidence=v1, tree-outcome=v1,
        give-promise-sources=v1,
    },
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{task-promise=v1},
}

This term applies for a tree T, a valid binding F of `file-readers`, a
binding N of `external-namespaces` for which a conforming program of
Identifiers gives the result "valid", the evidence V for T, and, when T
has evidence, valid bindings of `runner-settings` for the test runners
of the report files of the imports of V.

An edge e of T under F and N is a qualifying `verifies` edge for a
`verifies` promise q in T when, and only when, each of these four
conditions is true:

1. The edge e is of the kind `verifies`, says what the kind of edge
   `verifies` says, and has a test of T as its source.
2. The cited item of e is either the item of the kind requirement whose
   name is the `req` of q, or a group of conformance vectors or a vector
   set that holds a conformance vector saying a vector whose group
   includes the requirement that the item of the kind requirement whose
   name is the `req` of q declares.
3. The edge e is not suspect in T.
4. The file of e is a read file of T.

For a task definition d and a promise q of d, the class promise outcome
of q for d in T under F, N, V, and those bindings of `runner-settings`
is one of "known kept", "known not kept", and "not known":

- When q has the kind `satisfies`, the class promise outcome is "known
  kept" when q is kept in T under F and N by `ontology#promise`, with
  the paths of d as the paths of the task, and "known not kept"
  otherwise.
- When q has the kind `verifies` and T has evidence, the class promise
  outcome is "known kept" when q is kept in T under F, N, and V by
  `ontology#promise` and `evidence#tree-outcome`, with the paths of d as
  the paths of the task, and "known not kept" otherwise.
- When q has the kind `verifies` and T has no evidence, the class
  promise outcome is "not known" when T has at least one qualifying
  `verifies` edge for q whose file has a valid path in the set of the
  paths of d, and "known not kept" otherwise.

A class promise outcome is not a result for whether a `verifies` promise
is kept in T in the sense of `evidence#give-promise-sources`.

### 4.22 Edges that keep a promise outside a task's paths

@term outside-promise-edge=v1
@cites {
    ontology#{
        promise=v1, tree=v1, task=v1, work-item-definition=v1, edge=v1,
        satisfies-edge=v1, verifies-edge=v1, suspect-edge=v1, test=v1,
        declared-item=v1, item-name=v1, parameter=v1,
    },
    files#{path=v1, path-set-membership=v1},
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1, tree-edge=v1},
    packs#{runner-settings=v1, test-runner=v1},
    evidence#{import=v1, report-file=v1, tree-evidence=v1, tree-outcome=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{task-promise=v1, class-promise-outcome=v1},
}

This term applies for a tree T, a valid binding F of `file-readers`, a
binding N of `external-namespaces` for which a conforming program of
Identifiers gives the result "valid", the evidence V for T, and, when T
has evidence, valid bindings of `runner-settings` for the test runners
of the report files of the imports of V.

An edge e of T under F and N is known to keep a promise q of a task
definition d outside the paths of d in T when, and only when, the valid
path of the file of e is not in the set of the paths of d and one of
these two conditions is true:

- The promise q has the kind `satisfies`, and e is an edge of the kind
  `satisfies` that says what the kind of edge `satisfies` says, whose
  cited item is the item of the kind requirement whose name is the
  `req` of q, and that is not suspect in T.
- The promise q has the kind `verifies`, T has evidence, e is a
  qualifying `verifies` edge for q in T, and the test that is the source
  of e has the outcome "passed" in V under F.

### 4.23 The range of a run of the job

@term job-range=v1
@cites {
    gitdoc/gitglossary,
    changes#{
        commit=v1, commit-file=v1, shallow-commit=v1, ancestry=v1,
        reach=v1, commit-range=v1, default-branch-commit=v1,
        default-branch-name=v1, repository-read=v1, remote-transfer=v1,
    },
    ontology#{ledger=v1, ledger-entry=v1, job=v1, parameter=v1},
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    text#{code-span=v1},
    #{
        ledger-index=v1, commit-object-name=v1, delivered-field=v1,
        delivered-acceptance-rule=v1,
    },
}

For a run of the job on a git repository R, the read repository of the
run is R as the repository reads of the run find it, after each fetch
that the program makes into R in the run before or during those
repository reads, or R itself when the program makes no fetch. A git
repository holds the tree objects of a commit c of that git repository
when, and only when, it holds the git tree object of c and every git
tree object and blob named by an entry of the git tree object of c.

The rest of this term is for a git repository R whose ledger is valid
and that holds its ledger objects, and for the commit H of the default
branch of R under a valid binding of `default-branch-name`.

The latest accepted `delivered` entry of R is the accepted `delivered`
ledger entry at the greatest index in the stored ledger of R, or none
when the stored ledger of R has no accepted `delivered` ledger entry.
The start object name of a run is the value of `head` of the latest
accepted `delivered` entry of R, or none when there is none.

A commit c of R has a missing parent when, and only when, c is not a
shallow commit of R and the commit object of c names, as a parent, a git
object that is not a commit of R. A set of commits of R is complete in R
when, and only when, no commit in that set is a shallow commit of R and
no commit in that set has a missing parent.

The run status of a run for R and H is one of already recorded, ready
to record (with a commit range), and cut:

1. When the run has no start object name: let C be the commit range
   from no commit to H. When C is complete in R, the run status is
   ready to record with range C. Otherwise, the run status is cut.
2. When the run has a start object name s and s is the commit object
   name of H: the run status is already recorded.
3. When the run has a start object name s, s is not the commit object
   name of H, and R holds no commit whose commit object name is s:
   - When R has no shallow commit: the run status is decided as in case
     1.
   - When R has at least one shallow commit: the run status is cut.
4. When the run has a start object name s, s is not the commit object
   name of H, and R holds a commit J whose commit object name is s:
   - When J is a shallow commit of R or has a missing parent: the run
     status is cut.
   - Otherwise, when J reaches H: the run status is already recorded.
   - Otherwise, when H reaches J: let C be the commit range from J to
     H. When C is complete in R, the run status is ready to record with
     range C. Otherwise, the run status is cut.
   - Otherwise: when the ancestry of J is not complete in R, the run
     status is cut. When the ancestry of J is complete in R, let C be
     the commit range from no commit to H; when C is complete in R, the
     run status is ready to record with range C, and otherwise the run
     status is cut.

### 4.24 Git identity

@term git-identity=v1
@cites {
    gitdoc/git,
    gitdoc/git-commit,
    gitdoc/git-config,
    changes#{git-configuration=v1},
    text#{text=v1, space=v1, line-feed=v1, code-span=v1},
}

For a git repository R and the environment of an execution, the
configured committer name and configured committer email are the
committer name and committer email that the pages `git`, `git-commit`,
and `git-config` give from the environment variables
(`GIT_COMMITTER_NAME`, `GIT_COMMITTER_EMAIL`, and `EMAIL`) and the
settings of the git configuration of R (`committer.name`, `user.name`,
`committer.email`, and `user.email`), with `<`, `>`, and line feeds
stripped as `git-commit` defines, and excluding any default that git
guesses from the system user name or host name (as when
`user.useConfigOnly` is true in `git-config`).

Git has an identity for R in that environment when, and only when,
those sources give both a non-empty configured committer name and a
non-empty configured committer email. When git has an identity, the git
identity is that configured committer name, then a space, then `<`,
then that configured committer email, then `>`. Otherwise, git has no
identity for R in that environment.

### 4.25 How a run of the job ends

@term job-end=v1
@cites {
    ontology#{job=v1},
    text#{conforming-program=v1},
}

An execution of a conforming program that runs the job ends in one of
two ways: it ends with an error, or it ends without an error. No
execution of the job ends both with an error and without an error.

### 4.26 The tasks of a change

@term change-task=v1
@cites {
    changes#{
        commit=v1, message-text=v1, change-of-a-commit=v1,
        default-branch-name=v1, default-branch-commit=v1,
    },
    ontology#{ledger=v1, task=v1, work-item-state=v1, parameter=v1},
    text#{line=v1},
    #{work-item-id=v1, delivery-line-form=v1, task-line-form=v1},
}

Under a valid binding D of `default-branch-name` under which the default
branch of a git repository has a commit, for a commit h of that git
repository and a point P of a ledger, the tasks of the change of h at P
under D are each task t that exists at P and whose task id is the task
id of a line that meets `delivery-line-form` or `task-line-form` in the
text of the message of a commit of the change of h under D.

### 4.27 Files that only re-pin

@term repin-only-file=v1
@cites {
    ontology#{tree=v1, item-revision=v1, parameter=v1},
    files#{path=v1},
    changes#{line-text=v1},
    identifiers#{
        citation=v1, citation-line=v1, citation-entry=v1, match=v1,
        label=v1, revision=v1, external-namespaces=v1,
        validate-bindings=v1,
    },
    documents#{
        file-readers=v1, read-file=v1, unreadable-file=v1, tag-text=v1,
        accepted-input=v1, origin=v1, tree-edge=v1,
    },
    text#{
        conforming-program=v1, result=v1, text=v1, line=v1,
        line-number=v1, run=v1, boundary=v1, place=v1, valid-utf-8=v1,
        whole-number=v1, code-span=v1,
    },
}

This term is for a valid path f, a base tree B, a tree T, a valid
binding F of `file-readers`, and a binding N of `external-namespaces`
for which a conforming program of Identifiers gives the result "valid".

In a tree A under F and N, a citation pin of f in A is the run of
`label` in the match by `identifiers#citation-line` of a citation entry
of an accepted input of A that is a citation (`identifiers#citation`)
and whose file is the file of A at f: the `label` of `name "=" label`,
of `name "=" revision` when `revision` uses `label`, of `every-part`, or
of `part-name "=" label` or `part-name "=" revision` when `revision`
uses `label`. By `documents#origin`, the characters of a citation pin
come from contiguous places on one line k of the text of the file at f;
that run of line text k of f in A is the pin run of that citation pin,
and the edge of A that its citation entry gives is the edge of that
citation pin.

For a line number k of f in A, the citation pins of f in A on line k
have disjoint pin runs. Ordering them by the boundaries of line text k
where their pin runs start gives m citation pins (m of 0 or more) whose
pin runs divide line text k into m + 1 frame texts: the text before the
first pin run, the text between each two successive pin runs, and the
text after the last pin run (or the whole line text k when m is 0).

The valid path f only re-pins between B and T under F and N when, and
only when, all three of these conditions are true:

1. Both B and T have a file at f; the file at f is a read file of B that
   can be read under F, and a read file of T that can be read under F
   (so the content of each is valid UTF-8).
2. The number of line texts of f in B equals the number of line texts
   of f in T.
3. For each whole number k from 1 to that number such that line text k
   of f in B is not the same text as line text k of f in T:
   - The number m of citation pins of f in B on line k equals the
     number of citation pins of f in T on line k, and m is at least 1.
   - For each i from 0 to m, the i-th frame text of line k of f in B is
     the same text as the i-th frame text of line k of f in T.
   - For each j from 1 to m such that the text of the j-th pin run of
     line k in B is not the same text as the text of the j-th pin run
     of line k in T, the edge of the j-th citation pin of line k in T
     has a cited item in T under F and N, and the text of that pin run
     in T is the current revision of that cited item in T.

### 4.28 Subjects for changed file paths

@term path-finding-subject=v1
@cites {
    files#{path=v1},
    findings#{finding-subject=v1},
    text#{
        text=v1, character=v1, place=v1, space=v1, tab=v1,
        line-feed=v1, algorithm=v1, code-span=v1,
    },
}

A valid path needs path encoding when, and only when, it holds a line
feed, its first character is a space or a tab, or its last character is
a space or a tab.

The path-finding subject of a valid path *f* is the text that these
steps give.

1. If *f* does not need path encoding, give *f*.
2. Let *s* be `/`.
3. For each *ch* of *f*, in order:
   1. Let *out* be *ch*.
   2. If *ch* is `%`, set *out* to `%25`.
   3. If *ch* is a line feed, set *out* to `%0A`.
   4. If *ch* is a space, set *out* to `%20`.
   5. If *ch* is a tab, set *out* to `%09`.
   6. Append *out* to *s*.
4. Give *s*.

### 4.29 Findings of the class `malformed-delivery`

@atom malformed-delivery-finding=v1
@cites {
    ontology#{finding-class=v1, parameter=v1},
    changes#{
        commit=v1, commit-file=v1, message-text=v1,
        change-of-a-commit=v1, default-branch-name=v1,
        default-branch-commit=v1,
    },
    documents#{tree-finding=v1},
    findings#{finding-subject=v1},
    text#{line=v1, line-number=v1, decimal-numeral=v1, code-span=v1},
    #{commit-object-name=v1, delivery-line-form=v1},
}

For a git repository R, a commit h of R, and a valid binding D of
`default-branch-name`:

- When the default branch of R has no commit under D, the tree of h has
  no tree finding of the class `malformed-delivery` under D.
- When the default branch of R has a commit under D, the tree of h has,
  under D, one tree finding of the class `malformed-delivery` for each
  pair of a commit c of the change of h under D whose message has a text
  and a line l (with line number k) of that text such that l is a
  malformed delivery line. The subject of that finding is the commit
  object name of c, then `@L`, then the decimal numeral of k. That
  finding has no spot.

### 4.30 Findings of the class `stale-delivery`

@atom stale-delivery-finding=v1
@cites {
    ontology#{ledger=v1, finding-class=v1, parameter=v1},
    changes#{
        commit=v1, commit-file=v1, message-text=v1,
        change-of-a-commit=v1, default-branch-name=v1,
        default-branch-commit=v1,
    },
    documents#{tree-finding=v1},
    findings#{finding-subject=v1},
    text#{line=v1, line-number=v1, decimal-numeral=v1, code-span=v1},
    #{
        commit-object-name=v1, delivery-line-form=v1,
        counting-delivery-line=v1,
    },
}

For a git repository R, a commit h of R, a valid binding D of
`default-branch-name`, and a point P of the ledger of R:

- When the default branch of R has no commit under D, the tree of h has
  no tree finding of the class `stale-delivery` at P under D.
- When the default branch of R has a commit under D, the tree of h has,
  at P under D, one tree finding of the class `stale-delivery` for each
  pair of a commit c of the change of h under D whose message has a text
  and a line l (with line number k) of that text such that l meets
  `delivery-line-form` and does not count at P. The subject of that
  finding is the commit object name of c, then `@L`, then the decimal
  numeral of k. That finding has no spot.

### 4.31 Findings of the class `delivery-on-unmet-task`

@atom delivery-on-unmet-task-finding=v1
@cites {
    ontology#{
        ledger=v1, task=v1, work-item-definition=v1, work-item-state=v1,
        promise=v1, finding-class=v1, parameter=v1,
    },
    changes#{
        commit=v1, commit-file=v1, message-text=v1,
        change-of-a-commit=v1, default-branch-name=v1,
        default-branch-commit=v1,
    },
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1, tree-finding=v1},
    packs#{runner-settings=v1, test-runner=v1},
    evidence#{
        import=v1, report-file=v1, tree-evidence=v1,
        give-promise-sources=v1,
    },
    findings#{finding-subject=v1},
    text#{conforming-program=v1, result=v1, line=v1, code-span=v1},
    #{
        work-item-id=v1, delivery-line-form=v1,
        counting-delivery-line=v1, class-promise-outcome=v1,
    },
}

For a git repository R, a commit h of R, a valid binding D of
`default-branch-name`, a valid binding F of `file-readers`, a binding N
of `external-namespaces` for which a conforming program of Identifiers
gives the result "valid", the evidence VH for the tree of h, valid
bindings of `runner-settings` for the test runners of the report files
of the imports of VH (when the tree of h has evidence), and a point P of
the ledger of R:

- When the default branch of R has no commit under D, the tree of h has
  no tree finding of the class `delivery-on-unmet-task` at P under
  these bindings and inputs.
- When the default branch of R has a commit under D, the tree of h has,
  at P under these bindings and inputs, one tree finding of the class
  `delivery-on-unmet-task` for each task t that exists at P and meets
  both of these conditions:
  1. At least one line of the text of the message of a commit of the
     change of h under D meets `delivery-line-form`, has the task id of
     t as its task id, and counts at P.
  2. At least one promise of the current definition of t at P has the
     class promise outcome "known not kept" in the tree of h under F, N,
     VH, and those bindings of `runner-settings`.

The subject of that finding is the task id of t. That finding has no
spot. That tree finding holds only its class, its subject, and no spot
(`documents#tree-finding`), and is not a result for whether a `verifies`
promise is kept in a tree in the sense of `evidence#give-promise-sources`.

### 4.32 Findings of the class `missing-delivery`

@atom missing-delivery-finding=v1
@cites {
    ontology#{
        ledger=v1, task=v1, work-item-definition=v1, work-item-state=v1,
        promise=v1, finding-class=v1, parameter=v1,
    },
    changes#{
        commit=v1, commit-file=v1, message-text=v1,
        change-of-a-commit=v1, change-base=v1, default-branch-name=v1,
    },
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1, tree-finding=v1},
    packs#{runner-settings=v1, test-runner=v1},
    evidence#{
        import=v1, report-file=v1, tree-evidence=v1,
        give-promise-sources=v1,
    },
    findings#{finding-subject=v1},
    text#{conforming-program=v1, result=v1, line=v1, code-span=v1},
    #{
        work-item-id=v1, delivered-task-completion=v1,
        delivery-line-form=v1, counting-delivery-line=v1,
        class-promise-outcome=v1,
    },
}

For a git repository R, a commit h of R, a valid binding D of
`default-branch-name` under which the change of h has a base b, a valid
binding F of `file-readers`, a binding N of `external-namespaces` for
which a conforming program of Identifiers gives the result "valid", the
evidence VB and VH for the trees of b and of h, valid bindings of
`runner-settings` for the test runners of the report files of the
imports of VB and VH (when either tree has evidence), and a point P of
the ledger of R, the tree of h has, at P under these bindings and
inputs, one tree finding of the class `missing-delivery` for each task t
that exists at P and meets all five of these conditions:

1. Task t is unfinished at P.
2. The current definition of t at P has at least one promise.
3. No line of the text of the message of a commit of the change of h
   under D meets `delivery-line-form`, has the task id of t as its task
   id, and counts at P.
4. Every promise of the current definition of t at P has the class
   promise outcome "known kept" in the tree of h under F, N, VH, and
   those bindings of `runner-settings`.
5. At least one promise of the current definition of t at P has the
   class promise outcome "known not kept" in the tree of b under F, N,
   VB, and those bindings of `runner-settings`.

The subject of that finding is the task id of t. That finding has no
spot. That tree finding holds only its class, its subject, and no spot
(`documents#tree-finding`), and is not a result for whether a `verifies`
promise is kept in a tree in the sense of `evidence#give-promise-sources`.

### 4.33 Findings of the class `delivery-without-change`

@atom delivery-without-change-finding=v1
@cites {
    ontology#{
        ledger=v1, task=v1, work-item-definition=v1, work-item-state=v1,
        finding-class=v1, parameter=v1,
    },
    files#{path=v1, path-set-membership=v1},
    changes#{
        commit=v1, commit-file=v1, message-text=v1,
        change-of-a-commit=v1, change-base=v1, hunk=v1, change-diff=v1,
        default-branch-name=v1,
    },
    documents#{tree-finding=v1},
    findings#{finding-subject=v1},
    text#{line=v1, code-span=v1},
    #{
        work-item-id=v1, delivery-line-form=v1,
        counting-delivery-line=v1,
    },
}

For a git repository R, a commit h of R, a valid binding D of
`default-branch-name` under which the change of h has a base b, and a
point P of the ledger of R, the tree of h has, at P under D, one tree
finding of the class `delivery-without-change` for each task t that
exists at P and meets both of these conditions:

1. At least one line of the text of the message of a commit of the
   change of h under D meets `delivery-line-form`, has the task id of t
   as its task id, and counts at P.
2. No valid path f that has at least one hunk in a diff of the change
   of h under D is in the set of the paths of the current definition of
   t at P.

The subject of that finding is the task id of t. That finding has no
spot.

### 4.34 Findings of the class `unplanned-change`

@atom unplanned-change-finding=v1
@cites {
    ontology#{
        ledger=v1, task=v1, work-item-definition=v1,
        work-item-state=v1, finding-class=v1, parameter=v1,
    },
    files#{path=v1, path-set-membership=v1},
    changes#{
        commit=v1, commit-file=v1, change-of-a-commit=v1,
        change-base=v1, hunk=v1, change-diff=v1,
        default-branch-name=v1,
    },
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1, tree-finding=v1},
    findings#{finding-subject=v1, spot=v1},
    text#{conforming-program=v1, result=v1, code-span=v1},
    #{
        exempt-paths=v1, change-task=v1, repin-only-file=v1,
        path-finding-subject=v1,
    },
}

For a git repository R, a commit h of R, a valid binding D of
`default-branch-name` under which the change of h has a base b, a valid
binding X of `exempt-paths`, a valid binding F of `file-readers`, a
binding N of `external-namespaces` for which a conforming program of
Identifiers gives the result "valid", and a point P of the ledger of R,
the tree of h has, at P under these bindings and inputs, one tree
finding of the class `unplanned-change` for each valid path f that meets
all four of these conditions:

1. The valid path f has at least one hunk in a diff of the change of h
   under D.
2. For each task t of the tasks of the change of h at P under D, f is
   not in the set of the paths of the current definition of t at P.
3. The valid path f is not in the set of X.
4. The valid path f does not only re-pin between the tree of b and the
   tree of h under F and N.

The subject of that finding is the path-finding subject of f. When the
tree of h has a file at f, the spot of that finding is f alone, with no
span. When the tree of h has no file at f, that finding has no spot.

### 4.35 Findings of the class `promise-outside-paths`

@atom promise-outside-paths-finding=v1
@cites {
    ontology#{
        ledger=v1, tree=v1, task=v1, promise=v1,
        work-item-definition=v1, work-item-state=v1, finding-class=v1,
        parameter=v1,
    },
    files#{path=v1},
    identifiers#{
        external-namespaces=v1, validate-bindings=v1,
        citation-entry=v1,
    },
    documents#{
        file-readers=v1, tree-edge=v1, origin=v1, origin-position=v1,
        position-order=v1, run-spot=v1, tree-finding=v1,
    },
    packs#{runner-settings=v1, test-runner=v1},
    evidence#{
        import=v1, report-file=v1, tree-evidence=v1,
        give-promise-sources=v1,
    },
    findings#{finding-subject=v1, spot=v1},
    text#{
        conforming-program=v1, result=v1, space=v1, code-point-order=v1,
        code-span=v1,
    },
    #{
        work-item-id=v1, task-promise=v1, delivered-task-completion=v1,
        class-promise-outcome=v1, outside-promise-edge=v1,
    },
}

For a tree T, a valid binding F of `file-readers`, a binding N of
`external-namespaces` for which a conforming program of Identifiers
gives the result "valid", the evidence V for T, valid bindings of
`runner-settings` for the test runners of the report files of the
imports of V (when T has evidence), and a point P of a ledger, T has, at
P under these bindings and inputs, one tree finding of the class
`promise-outside-paths` for each pair of a task t that is unfinished at
P and a promise q of the current definition of t at P that meets both of
these conditions:

1. The class promise outcome of q for the current definition of t at P
   in T under F, N, V, and those bindings of `runner-settings` is "known
   not kept".
2. At least one edge of T under F and N is known to keep q outside the
   paths of the current definition of t at P in T under F, N, V, and
   those bindings of `runner-settings`.

The subject of that finding is the task id of t, then a space, then the
`kind` of q (`satisfies` or `verifies`), then a space, then the `req`
of q.

An edge e1 of T comes before another edge e2 of T in outside-edge order
when, and only when, the valid path of the file of e1 comes before the
valid path of the file of e2 in code point order, or the two files have
the same valid path and the origin position of the citation entry of e1
comes before the origin position of the citation entry of e2 in the
order of positions. The spot of that finding is the spot of the run of
the citation entry of the first edge of T in outside-edge order that is
known to keep q outside the paths of the current definition of t at P
in T, in the text of the file of that edge. That tree finding holds only
its class, its subject, and its spot (`documents#tree-finding`), and is
not a result for whether a `verifies` promise is kept in a tree in the
sense of `evidence#give-promise-sources`.

### 4.36 Findings of the class `unmet-promise`

@atom unmet-promise-finding=v1
@cites {
    ontology#{
        ledger=v1, tree=v1, task=v1, promise=v1,
        work-item-definition=v1, work-item-state=v1, finding-class=v1,
        parameter=v1,
    },
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1, tree-finding=v1},
    packs#{runner-settings=v1, test-runner=v1},
    evidence#{
        import=v1, report-file=v1, tree-evidence=v1,
        give-promise-sources=v1,
    },
    findings#{finding-subject=v1},
    text#{conforming-program=v1, result=v1, space=v1, code-span=v1},
    #{
        work-item-id=v1, task-promise=v1, delivered-task-completion=v1,
        class-promise-outcome=v1,
    },
}

For a tree T, a valid binding F of `file-readers`, a binding N of
`external-namespaces` for which a conforming program of Identifiers
gives the result "valid", the evidence V for T, valid bindings of
`runner-settings` for the test runners of the report files of the
imports of V (when T has evidence), and a point P of a ledger, T has, at
P under these bindings and inputs, one tree finding of the class
`unmet-promise` for each pair of a task t that is unfinished at P and a
promise q of the current definition of t at P whose class promise
outcome in T under F, N, V, and those bindings of `runner-settings` is
"known not kept".

The subject of that finding is the task id of t, then a space, then the
`kind` of q (`satisfies` or `verifies`), then a space, then the `req`
of q. That finding has no spot. That tree finding holds only its class,
its subject, and no spot (`documents#tree-finding`), and is not a result
for whether a `verifies` promise is kept in a tree in the sense of
`evidence#give-promise-sources`.

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
task at a point P of a ledger, the program must set `work-item` of that
ledger entry to a task id that no work item has at P. When a conforming
program appends a `plan` ledger entry to create a new plan at a point P
of a ledger, the program must set `work-item` of that ledger entry to a
plan id that no work item has at P.

### 5.2 Task hashes

@req give-task-hash=v1
@cites {
    files#{path-set=v1, valid-path-set=v1},
    text#{conforming-program=v1},
    #{task-promise=v1, task-hash=v1},
}

For a valid path set G and a finite set Q of promise objects in which no
two promise objects are equal, when a conforming program gives the
task-hash pre-image of G and Q, it must give only the task-hash
pre-image of G and Q, or refuse for limits of its own and give no
result. For such G and Q, when a conforming program gives the task hash
of G and Q, it must give only the task hash of G and Q, or refuse for
limits of its own and give no result.

### 5.3 Delivery lines of commit messages

@req give-delivery-lines=v1
@cites {
    changes#{commit=v1, message-text=v1},
    text#{conforming-program=v1, line=v1, line-number=v1},
    #{delivery-line-form=v1},
}

When a conforming program gives the delivery lines of a commit whose
message has a text, it must give each line of that text that meets
`delivery-line-form` once, in the order of their line numbers, with its
line number, its task id, and its short task hash, and no other line.
When the message of a commit has no text, a conforming program must give
no delivery line for that commit.

### 5.4 Malformed delivery lines of commit messages

@req give-malformed-delivery-lines=v1
@cites {
    changes#{commit=v1, message-text=v1},
    text#{conforming-program=v1, line=v1, line-number=v1},
    #{delivery-line-form=v1},
}

When a conforming program gives the malformed delivery lines of a commit
whose message has a text, it must give each line of that text that is a
malformed delivery line once, in the order of their line numbers, with
its line number, and no other line. When the message of a commit has no
text, a conforming program must give no malformed delivery line for that
commit.

### 5.5 Task lines of commit messages

@req give-task-lines=v1
@cites {
    changes#{commit=v1, message-text=v1},
    text#{conforming-program=v1, line=v1, line-number=v1},
    #{task-line-form=v1},
}

When a conforming program gives the task lines of a commit whose message
has a text, it must give each line of that text that meets
`task-line-form` once, in the order of their line numbers, with its line
number and its task id, and no other line. When the message of a commit
has no text, a conforming program must give no task line for that
commit.

### 5.6 The acceptance of work ledger entries

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
        delivered-acceptance-rule=v1, delivered-task-completion=v1,
    },
}

When a conforming program gives whether a ledger entry E of one of the
kinds `task`, `plan`, `done`, `abandoned`, and `delivered` is accepted
at a point P of a valid ledger of a git repository that holds its ledger
objects, and no other process changes that git repository while the
program reads it, it must give exactly one result, and only "accepted"
or "not accepted": "accepted" when the acceptance rule of the kind of E
holds for E at P, and "not accepted" when that acceptance rule does not
hold for E at P.

### 5.7 The states of tasks

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

### 5.8 The states of plans

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

### 5.9 The readiness of tasks

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

### 5.10 Accounted-for requirements

@req give-requirement-accounting=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1, extent-hash=v1},
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    ontology#{
        ledger=v1, tree=v1, declared-item=v1,
        requirement-accounted-for=v1, parameter=v1,
    },
    text#{conforming-program=v1, result=v1},
    #{delivered-task-completion=v1, recorded-requirement-content=v1},
}

This requirement applies under a valid binding F of `file-readers` and a
binding N of `external-namespaces` for which a conforming program of
Identifiers gives the result "valid". When a conforming program gives,
under F and N, whether an item r of the kind requirement of a tree T is
accounted for in T at a point P of a valid ledger of a git repository
that holds its ledger objects, and no other process changes that git
repository while the program reads it, the program must give exactly one
result, and only "accounted for" or "not accounted for": "accounted for"
when r is accounted for in T at P by
`ontology#requirement-accounted-for`, `delivered-task-completion`, and
`recorded-requirement-content`, and "not accounted for" otherwise.

### 5.11 What a `done` ledger entry records

@req record-done-requirements=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1, extent-hash=v1},
    ontology#{
        ledger=v1, ledger-entry=v1, person=v1, task=v1, declared-item=v1,
        item-name=v1, item-revision=v1, work-item-definition=v1,
        work-item-state=v1, tree=v1, parameter=v1,
    },
    text#{conforming-program=v1, result=v1, code-point-order=v1, code-span=v1},
    #{work-item-id=v1, done-field=v1},
}

This requirement applies under a valid binding F of `file-readers` and a
binding N of `external-namespaces` for which a conforming program of
Identifiers gives the result "valid". When a conforming program appends
a `done` ledger entry E at a point P of a ledger to record that a person
judged the work of a task t finished in a tree T under F and N, all four
of these rules apply:

1. The program must set `work-item` of E to the task id of t.
2. The program must set `requirements` of E to an array holding one
   requirement record for each distinct value of `req` among the
   promises of the current definition of t at P, in code point order of
   `req`, and no other element.
3. For each requirement record in `requirements` of E, when T has, under
   F and N, exactly one declared item of the kind requirement whose name
   in T is the value of `req` of that requirement record, the program
   must write `label` with the current revision of that declared item in
   T and `extent-hash` with the extent hash of that declared item in T
   under F and N in that requirement record.
4. For each requirement record in `requirements` of E, when T has, under
   F and N, no declared item of the kind requirement whose name in T is
   the value of `req` of that requirement record, or more than one such
   declared item, the program must write neither `label` nor
   `extent-hash` in that requirement record.

### 5.12 No work ledger write after a stop at a limit

@req omit-work-writes-at-limits=v1
@cites {
    ledger#{ledger-ref=v1},
    ontology#{ledger=v1, ledger-entry=v1},
    text#{conforming-program=v1, code-span=v1},
}

When a conforming program stops at a limit of its own in a computation
whose result a `task`, `plan`, `done`, or `abandoned` ledger entry would
record, it must append no such ledger entry and must change no ledger
ref.

### 5.13 Results for `verifies` promises in the job

@req give-job-promise-outcomes=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1},
    packs#{runner-settings=v1, test-runner=v1},
    evidence#{
        import=v1, report-file=v1, tree-evidence=v1,
        give-promise-sources=v1,
    },
    ledger#{job-marker=v1},
    ontology#{
        job=v1, ledger-entry=v1, promise=v1, task=v1,
        work-item-definition=v1, tree=v1, parameter=v1,
    },
    text#{conforming-program=v1, input=v1, result=v1, code-span=v1},
    #{job-promise-outcome=v1},
}

This requirement applies for a tree T, a valid binding F of
`file-readers`, a binding N of `external-namespaces` for which a
conforming program of Identifiers gives the result "valid", the evidence
V for T, and, when T has evidence, valid bindings of `runner-settings`
for the test runners of the report files of the imports of V. When a
conforming program runs the job in an execution whose input says that
the execution is the job and appends a `delivered` ledger entry that
records a `verifies` promise q of a task definition d in T under F, N,
V, and those bindings of `runner-settings`, the program must give, apart
from the appended `delivered` ledger entry, exactly one result for
whether q is kept in T for d, and only "kept" or "not-kept": the job
promise outcome of q for d in T. When T has evidence, the program must
also give, apart from the appended `delivered` ledger entry and with
that result, the test outcomes and sources that
`evidence#give-promise-sources` requires for q in T, taking the paths of
d as the paths of the task in `ontology#promise`.

### 5.14 Appending `delivered` ledger entries

@req append-delivered-entries=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1, extent-hash=v1},
    packs#{runner-settings=v1, test-runner=v1},
    evidence#{import=v1, report-file=v1, tree-evidence=v1},
    changes#{
        commit=v1, commit-file=v1, message-text=v1,
        parents-first-order=v1, first-parent-line=v1, landing-commit=v1,
        default-branch-name=v1, default-branch-commit=v1,
        repository-read=v1, undisturbed-read=v1,
    },
    ledger#{
        accepted-entry=v1, agent-marker=v1, job-marker=v1,
        ledger-validity=v1, ledger-object=v1, stored-ledger=v1,
        leave-delivered-entries-to-job=v1,
    },
    ontology#{
        job=v1, ledger=v1, ledger-entry=v1, task=v1, declared-item=v1,
        item-name=v1, item-revision=v1, work-item-definition=v1,
        work-item-state=v1, parameter=v1,
    },
    text#{
        conforming-program=v1, input=v1, result=v1, line=v1,
        line-number=v1, code-point-order=v1, code-span=v1,
    },
    #{
        work-item-id=v1, commit-object-name=v1, task-promise=v1,
        task-hash=v1, delivered-field=v1,
        definition-acceptance-rule=v1, delivered-acceptance-rule=v1,
        delivery-line-form=v1, job-promise-outcome=v1, job-range=v1,
        git-identity=v1, job-end=v1,
    },
}

This requirement applies for an execution of a conforming program that
runs the job on a git repository R and whose input says that the
execution is the job, when all of these conditions hold: F is a valid
binding of `file-readers`; N is a binding of `external-namespaces` for
which a conforming program of Identifiers gives the result "valid"; D is
a valid binding of `default-branch-name`; the read repository R′ of the
run (term `job-range`) holds its ledger objects and its ledger is valid;
the default branch of R′ has a commit H under D; git has an identity for
R in the execution's environment; the input of the execution does not
say that an agent runs the execution; each repository read of the run is
undisturbed; the run status that `job-range` gives from the stored
ledger of R′ and H is ready to record with range C; R′ holds the tree
objects of H; and, for the evidence V for the tree of H, when the tree
of H has evidence, the binding of `runner-settings` for the test runner
of each report file of each import of V is valid.

When the program finishes the run under these conditions, with the
evidence V for the tree of H and those bindings of `runner-settings`,
the program must give none of "already recorded", "cannot see range",
"invalid bindings", "invalid ledger", "missing ledger objects", "no
default branch commit", "no git identity", and "agent execution", must
end without an error, and, taking each commit c of C in parents-first
order and, when c has a message text, each line l of that message text
in line-number order, must append the `delivered` ledger entries in that
order:

1. For each line l that meets `delivery-line-form` whose task id t
   names a task that exists at the current end of the stored ledger of
   R′ and for which no accepted `delivered` ledger entry before that
   point has the commit object name of c as `commit`, t as `work-item`,
   and the short task hash of l as `hash`, the program must append one
   `delivered` ledger entry with:
   - `by`: the git identity for R in the execution's environment;
   - `work-item`: t;
   - `commit`: the commit object name of c;
   - `merge`: the commit object name of the landing commit of c on the
     first-parent line of H;
   - `head`: the commit object name of H;
   - `hash`: the short task hash of l;
   - `definitions`: an array holding each distinct task hash among the
     accepted `task` ledger entries of t before that point whose first
     six characters are the short task hash of l, in code point order,
     and no other element;
   - `promises`: an array holding one promise observation for each pair
     of a task hash g in `definitions` and a promise q of the definition
     with task hash g, ordered first by g in code point order and then
     by q in promise order, and no other element.
2. In each promise observation of `promises`, for its task hash g and
   promise q of the definition with task hash g, the program must write:
   - `task-hash` as g, `kind` as the `kind` of q, and `req` as the `req`
     of q;
   - `outcome` as the job promise outcome of q for that definition in
     the tree of H under F, N, V, and those bindings of
     `runner-settings`;
   - when the tree of H has, under F and N, exactly one declared item
     of the kind requirement whose name in the tree of H is the `req` of
     q, `label` as the current revision of that item in the tree of H
     and `extent-hash` as the extent hash of that item in the tree of H
     under F and N;
   - when the tree of H has, under F and N, no such declared item or
     more than one such declared item, neither `label` nor
     `extent-hash`.
3. The program must append no `delivered` ledger entry for any
   malformed delivery line, for any delivery line whose task does not
   exist at that point, or for any delivery line that an earlier
   accepted `delivered` ledger entry already records. When no line in C
   qualifies under rule 1, the program must append no `delivered`
   ledger entry.

### 5.15 The job on an already-recorded head

@req report-already-recorded-head=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1},
    changes#{
        default-branch-name=v1, default-branch-commit=v1,
        repository-read=v1, undisturbed-read=v1,
    },
    ledger#{
        agent-marker=v1, job-marker=v1, ledger-validity=v1,
        ledger-object=v1, stored-ledger=v1,
    },
    ontology#{job=v1, ledger=v1, parameter=v1},
    text#{conforming-program=v1, input=v1, result=v1},
    #{job-range=v1, git-identity=v1, job-end=v1},
}

When a conforming program runs the job on a git repository R in an
execution whose input says that the execution is the job, under a valid
binding of `file-readers`, a binding of `external-namespaces` for which
a conforming program of Identifiers gives the result "valid", a valid
binding of `default-branch-name` under which the default branch of the
read repository R′ of the run (term `job-range`) has a commit H, while
git has an identity for R in the execution's environment and the input
of the execution does not say that an agent runs the execution, with
undisturbed repository reads, a valid ledger of R′ whose ledger objects
R′ holds, and a run status (given by `job-range` from the stored ledger
of R′ and H) that is already recorded, the program must append no
`delivered` ledger entry, must give exactly one result, and only
"already recorded", and must end without an error.

### 5.16 The job when its range is cut

@req report-cut-job-range=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, repository-read=v1,
        undisturbed-read=v1,
    },
    ledger#{
        agent-marker=v1, job-marker=v1, ledger-validity=v1,
        ledger-object=v1, stored-ledger=v1,
    },
    ontology#{job=v1, ledger=v1, parameter=v1},
    text#{conforming-program=v1, input=v1, result=v1},
    #{job-range=v1, git-identity=v1, job-end=v1},
}

When a conforming program runs the job on a git repository R in an
execution whose input says that the execution is the job, under a valid
binding of `file-readers`, a binding of `external-namespaces` for which
a conforming program of Identifiers gives the result "valid", a valid
binding of `default-branch-name` under which the default branch of the
read repository R′ of the run (term `job-range`) has a commit H, while
git has an identity for R in the execution's environment and the input
of the execution does not say that an agent runs the execution, with
undisturbed repository reads, and a valid ledger of R′ whose ledger
objects R′ holds, and either the run status that `job-range` gives from
the stored ledger of R′ and H is cut, or that run status is ready to
record and R′ does not hold the tree objects of H, the program must
append no `delivered` ledger entry, must give exactly one result, and
only "cannot see range", and must end with an error.

### 5.17 The job under bindings that are not valid

@req reject-job-under-invalid-bindings=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1},
    changes#{
        commit=v1, commit-file=v1, default-branch-name=v1,
        default-branch-commit=v1, repository-read=v1,
        undisturbed-read=v1,
    },
    packs#{runner-settings=v1, test-runner=v1},
    evidence#{import=v1, report-file=v1, tree-evidence=v1},
    ledger#{
        agent-marker=v1, job-marker=v1, ledger-validity=v1,
        ledger-object=v1, stored-ledger=v1,
    },
    ontology#{job=v1, ledger=v1, parameter=v1},
    text#{conforming-program=v1, input=v1, result=v1},
    #{job-range=v1, git-identity=v1, job-end=v1},
}

Under a binding of `file-readers` that is not valid, under a binding of
`external-namespaces` for which a conforming program of Identifiers
gives the result "invalid", or under a binding of `default-branch-name`
that is not valid, when a conforming program runs the job in an
execution whose input says that the execution is the job, it must append
no `delivered` ledger entry, must give exactly one result, and only
"invalid bindings", and must end with an error.

When a conforming program runs the job on a git repository R in an
execution whose input says that the execution is the job, under a valid
binding of `file-readers`, a binding of `external-namespaces` for which
a conforming program of Identifiers gives the result "valid", a valid
binding of `default-branch-name` under which the default branch of the
read repository R′ of the run (term `job-range`) has a commit H, while
git has an identity for R in the execution's environment and the input
of the execution does not say that an agent runs the execution, with
undisturbed repository reads, a valid ledger of R′ whose ledger objects
R′ holds, a run status (given by `job-range` from the stored ledger of
R′ and H) that is ready to record, and R′ holding the tree objects of H,
and the tree of H has evidence V with a report file of an import whose
test runner has a binding of `runner-settings` that is not valid, the
program must append no `delivered` ledger entry, must give exactly one
result, and only "invalid bindings", and must end with an error.

### 5.18 The job when the repository lacks its ledger objects

@req reject-job-without-ledger-objects=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1},
    changes#{default-branch-name=v1, repository-read=v1, undisturbed-read=v1},
    ledger#{job-marker=v1, ledger-object=v1},
    ontology#{job=v1, ledger=v1, parameter=v1},
    text#{conforming-program=v1, input=v1, result=v1},
    #{job-range=v1, job-end=v1},
}

Under a valid binding of `file-readers`, a binding of
`external-namespaces` for which a conforming program of Identifiers
gives the result "valid", and a valid binding of `default-branch-name`,
when a conforming program runs the job on a git repository R in an
execution whose input says that the execution is the job, each
repository read is undisturbed, and the read repository R′ of the run
(term `job-range`) does not hold its ledger objects, the program must
append no `delivered` ledger entry, must give exactly one result, and
only "missing ledger objects", and must end with an error.

### 5.19 The job on a ledger that is not valid

@req reject-job-on-invalid-ledger=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1},
    changes#{default-branch-name=v1, repository-read=v1, undisturbed-read=v1},
    ledger#{
        job-marker=v1, ledger-validity=v1, ledger-object=v1,
        stored-ledger=v1,
    },
    ontology#{job=v1, ledger=v1, parameter=v1},
    text#{conforming-program=v1, input=v1, result=v1},
    #{job-range=v1, job-end=v1},
}

Under a valid binding of `file-readers`, a binding of
`external-namespaces` for which a conforming program of Identifiers
gives the result "valid", and a valid binding of `default-branch-name`,
when a conforming program runs the job on a git repository R in an
execution whose input says that the execution is the job, each
repository read is undisturbed, and the read repository R′ of the run
(term `job-range`) holds its ledger objects and its ledger is broken or
newer, the program must append no `delivered` ledger entry, must give
exactly one result, and only "invalid ledger", and must end with an
error.

### 5.20 The job when the default branch has no commit

@req reject-job-without-default-branch=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1},
    changes#{
        default-branch-name=v1, default-branch-commit=v1,
        repository-read=v1, undisturbed-read=v1,
    },
    ledger#{
        job-marker=v1, ledger-validity=v1, ledger-object=v1,
        stored-ledger=v1,
    },
    ontology#{job=v1, ledger=v1, parameter=v1},
    text#{conforming-program=v1, input=v1, result=v1},
    #{job-range=v1, job-end=v1},
}

When a conforming program runs the job on a git repository R in an
execution whose input says that the execution is the job, under a valid
binding of `file-readers`, a binding of `external-namespaces` for which
a conforming program of Identifiers gives the result "valid", a valid
ledger of the read repository R′ of the run (term `job-range`) whose
ledger objects R′ holds, a valid binding of `default-branch-name` under
which the default branch of R′ has no commit, and undisturbed repository
reads, it must append no `delivered` ledger entry, must give exactly one
result, and only "no default branch commit", and must end with an error.

### 5.21 The job without a git identity

@req reject-job-without-git-identity=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1},
    changes#{
        default-branch-name=v1, default-branch-commit=v1,
        repository-read=v1, undisturbed-read=v1,
    },
    ledger#{
        job-marker=v1, ledger-validity=v1, ledger-object=v1,
        stored-ledger=v1,
    },
    ontology#{job=v1, ledger=v1, parameter=v1},
    text#{conforming-program=v1, input=v1, result=v1},
    #{job-range=v1, git-identity=v1, job-end=v1},
}

When a conforming program runs the job on a git repository R in an
execution whose input says that the execution is the job, under a valid
binding of `file-readers`, a binding of `external-namespaces` for which
a conforming program of Identifiers gives the result "valid", a valid
ledger of the read repository R′ of the run (term `job-range`) whose
ledger objects R′ holds, a valid binding of `default-branch-name` under
which the default branch of R′ has a commit, and undisturbed repository
reads, while git has no identity for R in the execution's environment,
the program must append no `delivered` ledger entry, must give exactly
one result, and only "no git identity", and must end with an error.

### 5.22 The job under an agent marker

@req reject-job-under-agent-marker=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1},
    changes#{
        default-branch-name=v1, default-branch-commit=v1,
        repository-read=v1, undisturbed-read=v1,
    },
    ledger#{
        agent-marker=v1, job-marker=v1, ledger-validity=v1,
        ledger-object=v1, stored-ledger=v1,
    },
    ontology#{job=v1, ledger=v1, parameter=v1},
    text#{conforming-program=v1, input=v1, result=v1},
    #{job-range=v1, git-identity=v1, job-end=v1},
}

When a conforming program runs the job on a git repository R in an
execution whose input says that the execution is the job, under a valid
binding of `file-readers`, a binding of `external-namespaces` for which
a conforming program of Identifiers gives the result "valid", a valid
ledger of the read repository R′ of the run (term `job-range`) whose
ledger objects R′ holds, a valid binding of `default-branch-name` under
which the default branch of R′ has a commit, and undisturbed repository
reads, while git has an identity for R in the execution's environment and
the input of the execution says that an agent runs the execution, the
program must append no `delivered` ledger entry, must give exactly one
result, and only "agent execution", and must end with an error.

### 5.23 The job after a stop at a limit

@req fail-job-at-limits=v1
@cites {
    ledger#{ledger-ref=v1},
    ontology#{job=v1, ledger=v1, ledger-entry=v1},
    text#{conforming-program=v1, code-span=v1},
    #{job-end=v1},
}

When a conforming program runs the job and stops at a limit of its own,
it must append no `delivered` ledger entry, must change no ledger ref,
and must end with an error.

### 5.24 Findings of the classes `promise-outside-paths` and `unmet-promise`

@req give-work-tree-findings=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1, tree-finding=v1},
    packs#{runner-settings=v1, test-runner=v1},
    evidence#{import=v1, report-file=v1, tree-evidence=v1},
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    ontology#{finding-class=v1, tree=v1, ledger=v1, parameter=v1},
    text#{conforming-program=v1, result=v1},
    #{
        delivered-task-completion=v1,
        promise-outside-paths-finding=v1, unmet-promise-finding=v1,
    },
}

This requirement applies for a tree T, a valid binding F of
`file-readers`, a binding N of `external-namespaces` for which a
conforming program of Identifiers gives the result "valid", the evidence
V for T, and, when T has evidence, valid bindings of `runner-settings`
for the test runners of the report files of the imports of V. When a
conforming program gives the findings of one of the classes
`promise-outside-paths` and `unmet-promise` of T at a point P of a valid
ledger of a git repository that holds its ledger objects, and no other
process changes that git repository while the program reads it, the
program must give each tree finding of that class that T has at P under
these bindings and inputs once, and must give no other finding of that
class.

### 5.25 Findings of the classes `malformed-delivery`, `stale-delivery`, and `delivery-on-unmet-task`

@req give-work-commit-findings=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1, tree-finding=v1},
    packs#{runner-settings=v1, test-runner=v1},
    evidence#{import=v1, report-file=v1, tree-evidence=v1},
    changes#{
        commit=v1, commit-file=v1, change-of-a-commit=v1,
        default-branch-name=v1, repository-read=v1,
        undisturbed-read=v1,
    },
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    ontology#{finding-class=v1, ledger=v1, parameter=v1},
    text#{conforming-program=v1, result=v1},
    #{
        malformed-delivery-finding=v1, stale-delivery-finding=v1,
        delivery-on-unmet-task-finding=v1,
    },
}

This requirement applies for a commit h of a git repository R under a
valid binding D of `default-branch-name`, when each repository read is
undisturbed:

- When a conforming program gives the findings of the class
  `malformed-delivery` of the tree of h under D, the program must give
  each tree finding of that class that the tree of h has under D once,
  and must give no other finding of that class.
- When a conforming program gives the findings of the class
  `stale-delivery` of the tree of h at a point P of a valid ledger of R
  (where R holds its ledger objects) under D, the program must give each
  tree finding of that class that the tree of h has at P under D once,
  and must give no other finding of that class.
- Under a valid binding F of `file-readers`, a binding N of
  `external-namespaces` for which a conforming program of Identifiers
  gives the result "valid", the evidence VH for the tree of h, and, when
  the tree of h has evidence, valid bindings of `runner-settings` for
  the test runners of the report files of the imports of VH, when a
  conforming program gives the findings of the class
  `delivery-on-unmet-task` of the tree of h at a point P of a valid
  ledger of R (where R holds its ledger objects) under these bindings
  and inputs, the program must give each tree finding of that class that
  the tree of h has at P under these bindings and inputs once, and must
  give no other finding of that class.

### 5.26 Findings of the classes `missing-delivery`, `delivery-without-change`, and `unplanned-change`

@req give-work-change-findings=v1
@cites {
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1, tree-finding=v1},
    packs#{runner-settings=v1, test-runner=v1},
    evidence#{import=v1, report-file=v1, tree-evidence=v1},
    changes#{
        commit=v1, commit-file=v1, change-of-a-commit=v1,
        change-base=v1, default-branch-name=v1, repository-read=v1,
        undisturbed-read=v1,
    },
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    ontology#{finding-class=v1, ledger=v1, parameter=v1},
    text#{conforming-program=v1, result=v1},
    #{
        exempt-paths=v1, delivered-task-completion=v1,
        missing-delivery-finding=v1,
        delivery-without-change-finding=v1, unplanned-change-finding=v1,
    },
}

This requirement applies for a commit h of a git repository R under a
valid binding D of `default-branch-name` under which the change of h has
a base b, at a point P of a valid ledger of R where R holds its ledger
objects, when each repository read is undisturbed:

- When a conforming program gives the findings of the class
  `delivery-without-change` of the tree of h at P under D, the program
  must give each tree finding of that class that the tree of h has at P
  under D once, and must give no other finding of that class.
- Under a valid binding X of `exempt-paths`, a valid binding F of
  `file-readers`, and a binding N of `external-namespaces` for which a
  conforming program of Identifiers gives the result "valid", when a
  conforming program gives the findings of the class `unplanned-change`
  of the tree of h at P under these bindings and inputs, the program
  must give each tree finding of that class that the tree of h has at P
  under these bindings and inputs once, and must give no other finding
  of that class.
- Under a valid binding F of `file-readers`, a binding N of
  `external-namespaces` for which a conforming program of Identifiers
  gives the result "valid", the evidence VB and VH for the trees of b
  and of h, and, when either tree has evidence, valid bindings of
  `runner-settings` for the test runners of the report files of the
  imports of VB and VH, when a conforming program gives the findings of
  the class `missing-delivery` of the tree of h at P under these
  bindings and inputs, the program must give each tree finding of that
  class that the tree of h has at P under these bindings and inputs
  once, and must give no other finding of that class.

### 5.27 The change of a commit with a base

@req omit-work-missing-base-report=v1
@cites {
    ontology#{finding-class=v1, parameter=v1},
    changes#{
        commit=v1, change-of-a-commit=v1, change-base=v1,
        default-branch-name=v1, repository-read=v1,
        undisturbed-read=v1,
    },
    text#{conforming-program=v1, result=v1},
}

This requirement applies for a commit h under a valid binding D of
`default-branch-name` under which the change of h has a base, when a
conforming program gives the findings of one of the classes
`missing-delivery`, `delivery-without-change`, and `unplanned-change`
of the tree of h under D and each repository read from which that
program takes whether the change of h has a base is undisturbed. Under
these conditions, that program must not give the result "no base" for
the change of h.

### 5.28 The change of a commit with no base

@req report-work-missing-base=v1
@cites {
    ontology#{finding-class=v1, parameter=v1},
    changes#{
        commit=v1, change-of-a-commit=v1, change-base=v1,
        default-branch-name=v1, repository-read=v1,
        undisturbed-read=v1,
    },
    text#{conforming-program=v1, result=v1},
}

This requirement applies for a commit h under a valid binding D of
`default-branch-name` under which the change of h has no base, when a
conforming program gives the findings of one of the classes
`missing-delivery`, `delivery-without-change`, and `unplanned-change`
of the tree of h under D and each repository read from which that
program takes that the change of h has no base is undisturbed. Under
these conditions, that program must give exactly one result, and only
"no base", for the change of h, and must give no finding of that class.

### 5.29 No `unplanned-change` finding under `exempt-paths` that is not valid

@req omit-work-findings-under-invalid-bindings=v1
@cites {
    ontology#{finding-class=v1, parameter=v1},
    text#{conforming-program=v1},
    #{exempt-paths=v1, unplanned-change-finding=v1},
}

Under a binding of `exempt-paths` that is not valid, a conforming
program must give no finding of the class `unplanned-change`.

## 6. Conformance

A program, or a part of a program, conforms to this design when it is a
conforming program of this design: when it meets every requirement of
section 5.

The vectors of this design are in the file
[`work.test-vectors.jsonl`](work.test-vectors.jsonl), in the same folder
as this design. The file is a test-vector set, as the specification
[`test-vectors`](sinter:data-forms#test-vectors=v1) of Data forms gives
it. A vector is an input and what a conforming program gives for it.
Each vector follows from the requirements and adds nothing to them. The
vectors are in six groups: `task-hash`, `message-lines`, `acceptance`,
`states`, `promise-findings`, and `change-findings`. Each group has a
subsection in this section that gives the forms of that group, as the
term [`group-form-list`](sinter:data-forms#group-form-list=v1) gives the
forms of a group. No vector follows from the requirements
`assign-new-work-item-id`, `record-done-requirements`,
`omit-work-writes-at-limits`, `give-job-promise-outcomes`,
`append-delivered-entries`, `report-already-recorded-head`,
`report-cut-job-range`, `reject-job-under-invalid-bindings`,
`reject-job-without-ledger-objects`, `reject-job-on-invalid-ledger`,
`reject-job-without-default-branch`, `reject-job-without-git-identity`,
`reject-job-under-agent-marker`, `fail-job-at-limits`,
`omit-work-missing-base-report`, `report-work-missing-base`, and
`omit-work-findings-under-invalid-bindings`.

Each requirement from which vectors follow applies only when a program
gives the thing that the requirement names, such as whether a ledger
entry is accepted at a point. So a vector holds a program only to what
the program gives for the input.

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

Each vector of the group holds when the program reaches no limit of its
own. When a conforming program gives the task-hash pre-image for the
input of a vector, it gives the text of `pre-image`, and no other text.
When a conforming program gives the task hash for the input of a vector,
it gives the text of `hash`, and no other text.

```
{"form":"#task-hash-vector=v1","group":"task-hash","input":{"paths":["src/billing/**"],"promises":[{"kind":"satisfies","req":"billing#limit"}]},"note":"one path and one satisfies promise","values":{"hash":"de291f3f7d292d0bb2d3153cb5c4ae0089b9db46852a8c23a3e2058982c63a13","pre-image":"{\"paths\":[\"src/billing/**\"],\"promises\":[{\"kind\":\"satisfies\",\"req\":\"billing#limit\"}]}"}}
```

### 6.2 Message lines

@schema message-lines-vector=v1
@cites {
    rfc/8259,
    text#{
        conforming-program=v1, text=v1, character=v1, line=v1,
        line-number=v1, whole-number=v1, decimal-numeral=v1,
        code-span=v1,
    },
    changes#{commit=v1, message-text=v1},
    data-forms#{
        json-value=v1, vector-line=v1, group-form-list=v1,
        vector-meaning=v1, test-vectors=v1,
    },
    #{
        work-item-id=v1, delivery-line-form=v1, task-line-form=v1,
        give-delivery-lines=v1, give-malformed-delivery-lines=v1,
        give-task-lines=v1,
    },
}

The group `message-lines` holds the vectors of the requirements
`give-delivery-lines`, `give-malformed-delivery-lines`, and
`give-task-lines`. Each vector gives the text of the message of
a commit, or says that the commit message has no text, and gives the
delivery lines, the malformed delivery lines, and the task lines of that
commit. The group uses no need, so these forms give no need names.

The JSON values, objects, arrays, strings, and numbers of this schema
are as RFC 8259 defines them. Inside the members `input` and `values`, a
text is a JSON string whose characters are the characters of the text,
in order, and a line number is a JSON number written as the decimal
numeral of a whole number of 1 or more.

- `input`: a JSON object with zero or one member. When the commit
  message has a text, `input` holds the member `text`, whose value is
  that text. When the commit message has no text, `input` has no member
  `text`.
- `result`: no vector of the group has this member; these forms name no
  question for `result`.
- `values`: a JSON object with three members:
  - `delivery-lines`: a JSON array, in line-number order, of JSON objects
    with the members `line` (the line number), `task` (the task id), and
    `hash` (the short task hash);
  - `malformed-delivery-lines`: a JSON array of the line numbers of the
    malformed delivery lines, in line-number order;
  - `task-lines`: a JSON array, in line-number order, of JSON objects
    with the members `line` (the line number) and `task` (the task id).

When the program reaches no limit of its own and a conforming program
gives the delivery lines, malformed delivery lines, or task lines for
the commit of a vector, it gives the elements of the matching member of
`values` once, in order, and no other line.

```
{"form":"#message-lines-vector=v1","group":"message-lines","input":{"text":"Enforce billing limit\n\nDelivers: t-3f2a9c1d07e4 0e515c\n"},"note":"single valid delivery line","values":{"delivery-lines":[{"hash":"0e515c","line":3,"task":"t-3f2a9c1d07e4"}],"malformed-delivery-lines":[],"task-lines":[]}}
```

### 6.3 Acceptance

@schema acceptance-vector=v1
@cites {
    rfc/8259,
    text#{
        conforming-program=v1, text=v1, character=v1, result=v1,
        code-span=v1,
    },
    data-forms#{
        json-value=v1, vector-line=v1, group-form-list=v1,
        vector-meaning=v1, test-vectors=v1,
    },
    ontology#{ledger=v1, ledger-entry=v1},
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    #{
        task-field=v1, plan-field=v1,
        done-field=v1, abandoned-field=v1, delivered-field=v1,
        definition-acceptance-rule=v1, work-judgment-acceptance-rule=v1,
        delivered-acceptance-rule=v1, give-work-entry-acceptance=v1,
    },
}

The group `acceptance` holds the vectors of the requirement
`give-work-entry-acceptance`. Each vector gives a ledger whose ledger
entries of the kinds `task`, `plan`, `done`, `abandoned`, and
`delivered` are the given ones, in order. For each of those ledger
entries, the vector gives whether that ledger entry is accepted at its
point. The group uses no need, so these forms give no need names.

The input of each vector stands for a valid ledger of a git repository
that holds its ledger objects. No other process changes that git
repository while the program reads it.

The JSON values, objects, arrays, strings, numbers, and the literal
names `true` and `false` of this schema are as RFC 8259 defines them.
Inside the members `input` and `values`, a text is a JSON string whose
characters are the characters of the text, in order, and a sequence is a
JSON array of its elements, in order.

- `input`: a JSON object with one member, `ledger`. `ledger` is the
  ledger entries of the five work kinds of the ledger, as a sequence in
  the order of the ledger. Each ledger entry is a JSON object that holds
  `kind` and each field of the kind that the object of the ledger entry
  has, with the same values. The other members of the object of the
  ledger entry have no effect on the vector. The ledger has no other
  ledger entry of these five kinds.
- `result`: no vector of the group has this member; these forms name no
  question for `result`.
- `values`: a JSON object with one member, `accepted`. `accepted` is a
  JSON array with one element for each element of `ledger`, in the same
  order. Each element is `true` when that ledger entry is accepted at
  its point, and `false` when that ledger entry is not accepted at its
  point.

When the program reaches no limit of its own and a conforming program
gives whether one of these ledger entries is accepted at its point, the
program gives "accepted" when the element of `accepted` for that ledger
entry is `true`, and gives "not accepted" when that element is `false`.

```
{"form":"#acceptance-vector=v1","group":"acceptance","input":{"ledger":[{"def":1,"kind":"task","name":"Initial","paths":[],"promises":[],"waits":[],"work-item":"t-000000000001"},{"def":2,"kind":"task","name":"Renamed","paths":[],"promises":[],"waits":[],"work-item":"t-000000000001"},{"def":2,"kind":"task","name":"Stale","paths":[],"promises":[],"waits":[],"work-item":"t-000000000001"},{"def":4,"kind":"task","name":"Skipped","paths":[],"promises":[],"waits":[],"work-item":"t-000000000001"}]},"note":"task definition sequence: def 1, def 2, stale def 2, skipped def 4","values":{"accepted":[true,true,false,false]}}
```

### 6.4 States, readiness, and accounting

@schema states-vector=v1
@cites {
    rfc/8259,
    text#{
        conforming-program=v1, text=v1, character=v1, result=v1,
        code-span=v1,
    },
    data-forms#{
        json-value=v1, vector-line=v1, group-form-list=v1,
        vector-meaning=v1, test-vectors=v1, hash-form=v1,
    },
    identifiers#{
        slug=v1, full-name=v1, label=v1, external-namespaces=v1,
        validate-bindings=v1,
    },
    documents#{file-readers=v1, extent-hash=v1},
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    ontology#{
        ledger=v1, tree=v1, task=v1, plan=v1, declared-item=v1,
        item-name=v1, item-revision=v1, containment=v1,
        work-item-state=v1, ready-task=v1,
        requirement-accounted-for=v1, parameter=v1,
    },
    #{
        work-item-id=v1, delivered-task-completion=v1,
        recorded-requirement-content=v1,
        give-task-states=v1, give-plan-states=v1,
        give-task-readiness=v1, give-requirement-accounting=v1,
        acceptance-vector=v1,
    },
}

The group `states` holds the vectors of the requirements
`give-task-states`, `give-plan-states`, `give-task-readiness`, and
`give-requirement-accounting`. Each vector gives a ledger, task ids,
plan ids, and items of the kind requirement of a tree, and gives the
task states, plan states, task readiness, and requirement accounting at
the point after the last ledger entry of that ledger. The group uses no
need, so these forms give no need names.

The input of each vector stands for a valid ledger of a git repository
that holds its ledger objects, a valid binding of `file-readers`, and a
binding of `external-namespaces` for which a conforming program of
Identifiers gives the result "valid". No other process changes the git
repository while the program reads it.

The JSON values, objects, arrays, strings, and the literal names `true`
and `false` of this schema are as RFC 8259 defines them. Inside the
members `input` and `values`, a text is a JSON string whose characters
are the characters of the text, in order.

- `input`: a JSON object with four members:
  - `ledger`: the ledger entries of the five work kinds of the ledger,
    in the form that the schema `acceptance-vector` gives;
  - `tasks`: a JSON array of distinct task ids;
  - `plans`: a JSON array of distinct plan ids;
  - `requirements`: a JSON array of JSON objects with distinct values of
    `req`, each standing for one declared item of the kind requirement
    of the tree, with `req` (its name), `label` (its current revision),
    `extent-hash` (its extent hash), optional `spec` (the name of the
    item of the kind specification that holds it, if any), and optional
    `design` (the name of the item of the kind design to which it
    belongs, if any).
- `result`: no vector of the group has this member; these forms name no
  question for `result`.
- `values`: a JSON object with four members:
  - `task-states`: a JSON object whose members are each task id in
    `tasks` that exists at the point, each mapped to `"open"`,
    `"delivered"`, `"done"`, or `"abandoned"`;
  - `plan-states`: a JSON object whose members are each plan id in
    `plans` that exists at the point, each mapped to `"open"`, `"done"`,
    or `"abandoned"`;
  - `ready`: a JSON object whose members are each task id in `tasks`
    that exists at the point, each mapped to `true` (for "ready") or
    `false` (for "not ready");
  - `accounted-for`: a JSON object whose members are each `req` in
    `requirements`, each mapped to `true` (for "accounted for") or
    `false` (for "not accounted for").

When the program reaches no limit of its own, for each queried task id,
plan id, or requirement, a conforming program gives the result that the
matching member of `values` gives, and gives no state or readiness
result for a task id or plan id that does not appear in `task-states`,
`plan-states`, or `ready`.

```
{"form":"#states-vector=v1","group":"states","input":{"ledger":[{"def":1,"kind":"task","name":"Old name","paths":["src/**"],"promises":[{"kind":"satisfies","req":"billing#limit"}],"waits":[],"work-item":"t-000000000001"},{"def":2,"kind":"task","name":"New name","paths":["src/**"],"promises":[{"kind":"satisfies","req":"billing#limit"}],"waits":[],"work-item":"t-000000000001"},{"commit":"1111111111111111111111111111111111111111","definitions":["8c391ae69123435eeecc2d6ee1bbcc27497c1e65d5460c1b38a040ce63631c79"],"hash":"8c391a","head":"1111111111111111111111111111111111111111","kind":"delivered","merge":"1111111111111111111111111111111111111111","promises":[{"extent-hash":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","kind":"satisfies","label":"v1","outcome":"kept","req":"billing#limit","task-hash":"8c391ae69123435eeecc2d6ee1bbcc27497c1e65d5460c1b38a040ce63631c79"}],"work-item":"t-000000000001"}],"plans":["p-000000000001"],"requirements":[{"design":"billing","extent-hash":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","label":"v1","req":"billing#limit","spec":"billing#rules"},{"design":"auth","extent-hash":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","label":"v1","req":"auth#login"}],"tasks":["t-000000000001","t-000000000002"]},"note":"task becomes done via delivered entry matching current task hash after display-name edit","values":{"accounted-for":{"auth#login":false,"billing#limit":true},"plan-states":{},"ready":{"t-000000000001":false},"task-states":{"t-000000000001":"done"}}}
```

### 6.5 Promise findings

@schema promise-findings-vector=v1
@cites {
    rfc/8259,
    text#{
        conforming-program=v1, text=v1, character=v1, whole-number=v1,
        decimal-numeral=v1, code-point-order=v1, result=v1,
        code-span=v1,
    },
    files#{path=v1},
    data-forms#{
        json-value=v1, vector-line=v1, group-form-list=v1,
        vector-meaning=v1, test-vectors=v1,
    },
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{
        file-readers=v1, tree-edge=v1, origin-position=v1, run-spot=v1,
        tree-finding=v1,
    },
    packs#{runner-settings=v1},
    evidence#{tree-evidence=v1, tree-outcome=v1},
    changes#{
        commit=v1, message-text=v1, change-of-a-commit=v1,
        change-base=v1, default-branch-name=v1, repository-read=v1,
        undisturbed-read=v1,
    },
    findings#{finding-subject=v1, spot=v1},
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    ontology#{
        ledger=v1, tree=v1, edge=v1, finding-class=v1, parameter=v1,
    },
    #{
        class-promise-outcome=v1, outside-promise-edge=v1,
        delivery-on-unmet-task-finding=v1, missing-delivery-finding=v1,
        promise-outside-paths-finding=v1, unmet-promise-finding=v1,
        give-work-tree-findings=v1, give-work-commit-findings=v1,
        give-work-change-findings=v1, acceptance-vector=v1,
    },
}

The group `promise-findings` holds the vectors of the requirements
`give-work-tree-findings`, `give-work-commit-findings` (for the class
`delivery-on-unmet-task`), and `give-work-change-findings` (for the
class `missing-delivery`). Each vector gives a ledger, a summary of the
tree of a commit (with its edges and evidence status), optional commit
message texts of the change of that commit, and an optional summary of
the base tree of that change, and gives the resulting findings at the
point after the last ledger entry of that ledger. The group uses no
need, so these forms give no need names.

The input of each vector stands for a valid ledger of a git repository
that holds its ledger objects, a valid binding of `file-readers`, a
binding of `external-namespaces` for which a conforming program of
Identifiers gives the result "valid", a valid binding of
`default-branch-name` under which the default branch has a commit (and
the change has a base when `base` is present), valid bindings of
`runner-settings`, and undisturbed repository reads.

The JSON values, objects, arrays, strings, numbers, and the literal
names `true` and `false` of this schema are as RFC 8259 defines them.
Inside the members `input` and `values`, a text is a JSON string whose
characters are the characters of the text, in order, and each line or
column number is a JSON number written as the decimal numeral of a whole
number of 1 or more.

A tree summary is a JSON object with two members: `has-evidence` (`true`
when the tree has evidence, `false` otherwise), and `edges`, a JSON array
of edge summaries. Each edge summary is a JSON object with: `kind`
(`"satisfies"` or `"verifies"`), `req` (the requirement name that the
edge targets directly, or, for a `verifies` edge, through a group of
conformance vectors or a vector set), `fits` (`true` when the edge says
what its kind says, has a test source for `verifies`, stands in a read
file, and is not suspect, `false` otherwise), `path` (the valid path of
the file of the edge), `line` and `col` (the origin position of its
citation entry), `end-line` and `end-col` (the position after the spot
of its citation entry), and, for a `verifies` edge when `has-evidence`
is `true`, optional `test-outcome` (`"passed"`, `"failed"`, or
`"not run"`). When `test-outcome` is absent on a `verifies` edge while
`has-evidence` is `true`, the evidence shows no outcome for the test of
that edge.

- `input`: a JSON object with two to four members: `ledger` (in the form
  of `acceptance-vector`), `tree` (a tree summary), optional `commits`
  (a JSON array of the message texts of the commits of the change), and
  optional `base` (a tree summary of the base tree, present only when
  `commits` is present).
- `result`: no vector of the group has this member; these forms name no
  question for `result`.
- `values`: a JSON object with one member, `findings`, a JSON object
  holding:
  - `unmet-promise`: a JSON array of the finding subjects in code point
    order;
  - `promise-outside-paths`: a JSON array, in code point order of
    `subject`, of JSON objects with `subject` and `spot` (a JSON object
    with `path`, `start-line`, `start-col`, `end-line`, and `end-col`);
  - when `commits` is present, `delivery-on-unmet-task`: a JSON array of
    the task id subjects in code point order;
  - when `commits` and `base` are present, `missing-delivery`: a JSON
    array of the task id subjects in code point order.

When the program reaches no limit of its own and a conforming program
gives the findings of any class named in `findings`, it gives one
finding for each element of that member (with that spot for
`promise-outside-paths`, and no spot for the other three classes), and
no other finding of that class.

```
{"form":"#promise-findings-vector=v1","group":"promise-findings","input":{"ledger":[{"def":1,"kind":"task","name":"Sat","paths":["src/billing/**"],"promises":[{"kind":"satisfies","req":"billing#limit"}],"waits":[],"work-item":"t-000000000001"}],"tree":{"edges":[{"col":1,"end-col":20,"end-line":1,"fits":true,"kind":"satisfies","line":1,"path":"src/billing/a.ml","req":"billing#limit"}],"has-evidence":true}},"note":"satisfies kept inside paths gives no finding","values":{"findings":{"promise-outside-paths":[],"unmet-promise":[]}}}
```

### 6.6 Change findings

@schema change-findings-vector=v1
@cites {
    rfc/8259,
    text#{
        conforming-program=v1, text=v1, character=v1, whole-number=v1,
        decimal-numeral=v1, code-point-order=v1, result=v1,
        code-span=v1,
    },
    files#{path=v1, valid-path-set=v1},
    data-forms#{
        json-value=v1, vector-line=v1, group-form-list=v1,
        vector-meaning=v1, test-vectors=v1,
    },
    identifiers#{external-namespaces=v1, validate-bindings=v1},
    documents#{file-readers=v1, tree-finding=v1, unreadable-file=v1},
    changes#{
        commit=v1, message-text=v1, change-of-a-commit=v1,
        change-base=v1, hunk=v1, change-diff=v1,
        default-branch-name=v1, default-branch-commit=v1,
        repository-read=v1, undisturbed-read=v1,
    },
    findings#{finding-subject=v1, spot=v1},
    ledger#{ledger-validity=v1, ledger-object=v1, stored-ledger=v1},
    ontology#{ledger=v1, finding-class=v1, parameter=v1},
    #{
        exempt-paths=v1, commit-object-name=v1, change-task=v1,
        repin-only-file=v1, path-finding-subject=v1,
        malformed-delivery-finding=v1, stale-delivery-finding=v1,
        delivery-without-change-finding=v1, unplanned-change-finding=v1,
        give-work-commit-findings=v1, give-work-change-findings=v1,
        acceptance-vector=v1,
    },
}

The group `change-findings` holds the vectors of the requirements
`give-work-commit-findings` (for the classes `malformed-delivery` and
`stale-delivery`) and `give-work-change-findings` (for the classes
`delivery-without-change` and `unplanned-change`). Each vector gives a
ledger, a valid binding of `exempt-paths`, optional commits of the
change of a commit, and optional changed files with hunks between the
base tree and the tree of that commit, and gives the resulting findings
at the point after the last ledger entry of that ledger. The group uses
no need, so these forms give no need names.

The input of each vector stands for a valid ledger of a git repository
that holds its ledger objects, a valid binding of `file-readers`, a
binding of `external-namespaces` for which a conforming program of
Identifiers gives the result "valid", a valid binding of
`default-branch-name` (under which the default branch has a commit when
`commits` is present, has no commit when `commits` is absent, and the
change has a base when `changed-files` is present), and undisturbed
repository reads.

The JSON values, objects, arrays, strings, numbers, and the literal
names `true` and `false` of this schema are as RFC 8259 defines them.
Inside the members `input` and `values`, a text is a JSON string whose
characters are the characters of the text, in order.

A file summary is a JSON object with two members: `readable` (`true`
when the file is a read file that can be read in its tree under
`file-readers`, `false` otherwise), and `lines`, a JSON array of line
objects in line-number order. Each line object has `text` (the line
text) and `pins`, a JSON array of the citation pins (term
`repin-only-file`) on that line. Each pin object has `start` and `end`
(the 0-based start and end boundaries of the pin run in `text`), and, in
the tree of the commit, optional `matches-current` (`true` when the edge
of that citation pin has a cited item whose current revision is that pin
run's text, `false` otherwise). When `matches-current` is absent on a pin
in the tree of the commit, that pin's edge has no cited item whose
current revision is that pin run's text (the same as `false`).

- `input`: a JSON object with two to four members:
  - `ledger`: in the form of `acceptance-vector`;
  - `exempt-paths`: a JSON array of strings forming a valid path set;
  - optional `commits`: a JSON array of JSON objects, each with `id` (a
    commit object name) and optional `text` (the commit message text,
    omitted when the message has no text);
  - optional `changed-files` (present only when `commits` is present,
    and only when the change has a base): a JSON array of objects for
    each valid path with a hunk in a diff of the change, each holding
    `path`, optional `base` (a file summary in the base tree, omitted
    when the file was added), and optional `head` (a file summary in the
    commit tree, omitted when the file was deleted).
- `result`: no vector of the group has this member; these forms name no
  question for `result`.
- `values`: a JSON object with one member, `findings`, a JSON object
  holding:
  - `malformed-delivery`: a JSON array of finding subjects in code point
    order;
  - `stale-delivery`: a JSON array of finding subjects in code point
    order;
  - when `commits` and `changed-files` are present,
    `delivery-without-change`: a JSON array of task id subjects in code
    point order;
  - when `commits` and `changed-files` are present, `unplanned-change`:
    a JSON array, in code point order of `subject`, of JSON objects with
    `subject` and `has-spot` (`true` when the finding has the valid path
    alone as its spot, `false` when the finding has no spot).

When the program reaches no limit of its own and a conforming program
gives the findings of any class named in `findings`, it gives one
finding for each element of that member (with no spot for
`malformed-delivery`, `stale-delivery`, and `delivery-without-change`,
and with or without a spot as `has-spot` says for `unplanned-change`),
and no other finding of that class.

```
{"form":"#change-findings-vector=v1","group":"change-findings","input":{"changed-files":[{"base":{"lines":[{"pins":[],"text":"old"}],"readable":true},"head":{"lines":[{"pins":[],"text":"new"}],"readable":true},"path":"src/billing/a.ml"},{"base":{"lines":[{"pins":[],"text":"old"}],"readable":true},"head":{"lines":[{"pins":[],"text":"new"}],"readable":true},"path":"src/other/b.ml"}],"commits":[{"id":"1111111111111111111111111111111111111111","text":"Delivers: t-000000000001 000000\nDelivers: t-000000000002 e0cbba\nDelivers: bad\n"}],"exempt-paths":[],"ledger":[{"def":1,"kind":"task","name":"Billing","paths":["src/billing/**"],"promises":[],"waits":[],"work-item":"t-000000000001"}]},"note":"malformed-delivery for malformed line and stale-delivery for stale hash and missing task; stale well-formed line still contributes task paths","values":{"findings":{"delivery-without-change":[],"malformed-delivery":["1111111111111111111111111111111111111111@L3"],"stale-delivery":["1111111111111111111111111111111111111111@L1","1111111111111111111111111111111111111111@L2"],"unplanned-change":[{"has-spot":true,"subject":"src/other/b.ml"}]}}}
```
