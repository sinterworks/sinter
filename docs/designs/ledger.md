<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# The ledger
@design ledger=v1
@cites conformance=v1
@cites text=v1
@cites identifiers=v1
@cites files=v1
@cites data-forms=v1
@cites ontology=v1
@cites findings=v1
@cites changes=v1
@cites object-store=v1
@cites gitdoc/git-config
@cites rfc/3339
@cites rfc/5234
@cites rfc/7405
@cites rfc/8259
Specifies the split ledger of a repository: the log branch, its remote-tracking ref, its chunks of `{"id","object"}` envelope lines, its newer lines, its validity, its key-present closure, and its intact append-only history checked against git's reflog; common record fields, record writers, voids, and acceptance rules; the checks of git entries at or inside `.sinter/`, of added and withdrawn store files, of agent writers, of unaccepted voids, of latest targets, of uncommitted store files, and of conflicts; agent markers, job markers, and tracker boundaries; and requirements for conforming programs that read, check, and write statements and the log branch.

The ledger of a repository has two parts. Statements — definitions,
judgments, and voids — live as fixed object files in `.sinter/` of a
tree, forming a content-addressed graph through their `edges`.
Observations (`delivered` and `progress`) and kept objects (merged
declared items and the computed identity objects that they need) live on
a dedicated git branch, the log branch, stored in chunks of canonical
envelope lines. Only the job writes the log branch, by appending new
lines and pushing as a fast-forward. Checks read statements from a tree
and read the log branch from the remote-tracking ref of a configured
remote without fetching refs or calling a host.

From Conformance (`conformance`), the Ledger takes conforming programs,
inputs, dependence, limits of a program's own, reports, safety
obligations, objects, encodings, valid program's own stores, and the
general requirements that bind every conforming program. From Text and
notation (`text`), it takes texts, characters, spaces, hex digits, whole
numbers, bytes, byte sequences, valid UTF-8, texts and UTF-8 encodings
of byte sequences, 0x numerals, code spans, code point order,
productions, rule names, sequences, and results. From Identifiers
(`identifiers`), it takes external ids. From Files and paths (`files`),
it takes valid paths. From Data forms (`data-forms`), it takes JSON
values, objects and their members, line objects, canonical byte
sequences, the JSON values of byte sequences, hex texts, id prefixes,
hash ids, vector lines, the forms of a group, the meaning of a vector,
and test-vector sets. The file that holds the conformance vectors of the
Ledger is a test-vector set.

From the Ontology (`ontology`), the Ledger takes trees, objects, the
schema table of object kinds (`object-kind`), content hashes, content
ids, computed identity objects, declared items, edges, records,
statements, definition statements, judgments, voids, object withdrawal
and counting voids, records of the job (observations), the log branch,
the ledger, things and latest statements, conflicts, states, persons,
agents, the job, external items, parameters, and finding classes. From
Findings (`findings`), it takes the parts of a finding, finding
subjects, path-finding subjects, messages, spots, marks, related
messages, fixes, and ackable findings. From Changes (`changes`), it
takes git repositories, working trees, commits and their parents,
shallow commits, refs and the commits of refs, ref names, branch names,
head commits, git tree objects with their entries and byte paths, reach
and ancestry, change bases, git configurations, remotes and their fetch
and push addresses, reflog commits, mapped refs, repository reads,
undisturbed repository reads, and the requirement
`run-no-configured-programs`. From the Object store (`object-store`), it
takes object paths, store paths, store files, valid object files, needed
identity files, and the object store of a tree.

From the page git-config of git's documentation, the Ledger takes how a
remote's fetch and push addresses resolve. From RFC 3339, it takes the
rule `date-time` for record timestamps. The production `chunk-path` uses
ABNF from RFC 5234 with the case-sensitive quoted strings `%s"..."` of
RFC 7405. From RFC 8259, it takes JSON texts for the conformance vector
schemas.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [conforming program](sinter:conformance#conforming-program=v1) | a program, or a part of a program, that meets every requirement of a design together with the general requirements of Conformance |
| [safety obligation](sinter:conformance#safety-obligation=v1) | an obligation of a requirement that states that a program reads, alters, writes, follows, or runs no thing other than what the requirement allows, gains no permission, never permits an unsafe action, or ends code that it runs |
| [report](sinter:conformance#report=v1) | a thing that a conforming program gives to identify a stop at a limit of its own, an input that is not valid, or a missing part of a valid input |
| [ledger](sinter:ontology#ledger=v1) | the statements stored as fixed object files in `.sinter/` of a tree together with the observations and kept objects on the log branch |
| [log branch](sinter:ontology#log-branch=v1) | the dedicated git branch, named by `log-branch-name`, that holds only the observations (`delivered` and `progress`) and kept objects that the job writes |
| [record](sinter:ontology#ledger-entry=v1) | an object of one of the nine record kinds in `ontology#object-kind`: the seven statement kinds and the two observation kinds |
| [statement](sinter:ontology#statement=v1) | a record of one of the seven statement kinds (definition statements, judgments, and voids) stored as a fixed object file in `.sinter/` |
| [definition statement](sinter:ontology#definition-entry=v1) | a statement of the kind `task-def` or `plan-def` |
| [judgment](sinter:ontology#judgment=v1) | a statement recording a person's decision (one of the four judgment kinds in `ontology#judgment`) |
| [void](sinter:ontology#void-statement=v1) | a statement of the kind `void` with which a person withdraws one withdrawable object in `.sinter/` or on the log branch |
| [counting void](sinter:ontology#object-withdrawal=v1), [withdrawn](sinter:ontology#object-withdrawal=v1) | a `void` in a valid object file of `.sinter/` that meets its acceptance rule, carries no `agent`, satisfies any bound list of persons, and matches the permitted copied edges when the withdrawn object is held; an object named by a counting void's `withdraws` edge |
| [observation](sinter:ontology#job-record=v1) | a record of the kind `delivered` or `progress` on the log branch, written only by the job |
| [kept object](sinter:ontology#log-branch=v1) | a canonical copy of a merged declared item, or of a computed identity object that a kept declared item needs, stored on the log branch with no `seq` and no `by` |
| [person](sinter:ontology#person=v1), [agent](sinter:ontology#agent=v1), [job](sinter:ontology#job=v1) | a human who works on a repository; a program that uses a language model to write texts as one person runs it; an execution of a conforming program that records observations and kept objects after merges to the default branch |
| [object](sinter:ontology#object=v1), [content hash](sinter:ontology#content-hash=v1), [content id](sinter:ontology#content-id=v1) | an entity of one of the twenty-five kinds in `ontology#object-kind`; the SHA-256 hash of its canonical byte sequence (no `id`, no final line feed); its kind word, `:`, and the first 32 lowercase hex digits of its content hash |
| [computed identity](sinter:ontology#computed-identity=v1) | an object of one of the five kinds `name`, `pin`, `ext`, `vector-set`, and `vector-group` |
| [latest statement](sinter:ontology#thing=v1), [conflict](sinter:ontology#conflict=v1) | a counting statement of a group of a thing that no other counting statement of that group replaces; two or more disagreeing latest statements of a group, or a completing `delivered` observation with a latest `abandoned` judgment of the same task definition |
| [parameter](sinter:ontology#parameter=v1) | a word whose value a design leaves open; configuration gives its binding |
| [finding](sinter:ontology#finding-class=v1), [finding class](sinter:ontology#finding-class=v1) | a report of one condition at one part of a repository; a kind of finding named by a slug |
| [store file](sinter:object-store#store-file=v1), [valid object file](sinter:object-store#valid-object-file=v1), [object store of a tree](sinter:object-store#tree-object-store=v1) | a file of a tree in `.sinter/` outside `.sinter/local/`; a store file holding one valid canonical object at its object path; the set of all store files of a tree |
| [remote-tracking ref of the log branch](sinter:#log-branch-ref=v1), [log-branch commit](sinter:#log-branch-ref=v1), [missing log branch](sinter:#log-branch-ref=v1) | the mapped ref of `refs/heads/<log-branch-name>` for `ledger-remote`; the commit of that ref; the condition when no such mapped ref exists or that ref does not exist |
| [chunk path](sinter:#chunk-path=v1), [chunk](sinter:#chunk=v1), [line of a chunk](sinter:#chunk=v1) | a path of the form `entries/<2 hex>/<32 hex>.jsonl` with matching two-digit prefix; a regular-file entry at a chunk path in a git tree object; one byte sequence ending in `0x0A` (or trailing bytes after the last `0x0A`) in a chunk's blob |
| [valid log-branch line](sinter:#log-branch-line=v1) | a canonical `{"id":"<content-id>","object":{...}}` line ending in `0x0A` whose `object` meets its row of `ontology#object-kind`, has a kind allowed on the log branch, and hashes to `id` |
| [newer line](sinter:#newer-line=v1) | a line of a chunk ending in `0x0A` whose JSON value has string `id` and JSON object `object` with integer `v > 1` and a valid `kind` id prefix whose canonical byte sequence hashes to `id` |
| [field](sinter:#entry-field=v1), [common field](sinter:#entry-field=v1) | a member of a record named by `ontology#object-kind` or a design; the common members `kind`, `v`, `by`, `ts`, `edges`, `agent` (statements), and `seq` (observations) |
| [writer that a record records](sinter:#entry-writer=v1) | the agent named by `agent` when present, or else the person or the job named by `by` |
| [ledger objects](sinter:#ledger-object=v1), [history objects](sinter:#ledger-object=v1) | the git objects needed to read the log-branch commit (ref target, commit, tree objects, and chunk blobs); and those git objects for every commit that the log-branch commit reaches |
| [valid log-branch tree](sinter:#valid-ledger-tree=v1) | a git tree object that is not newer and holds only valid chunks of valid log-branch lines with unique `id`s and contiguous `seq` values across observations |
| [needed log identity](sinter:#needed-log-identity=v1), [unclosed](sinter:#needed-log-identity=v1) | a computed identity content id named by an edge of a kept declared item that does not hold that key itself; a kept object whose needed computed identity object is absent from the log branch |
| [valid](sinter:#ledger-validity=v1), [broken](sinter:#ledger-validity=v1), [newer](sinter:#ledger-validity=v1) | the three validity states of an existing log branch whose ledger objects are held |
| [stored ledger](sinter:#stored-ledger=v1), [stored statements](sinter:#stored-ledger=v1), [stored observations](sinter:#stored-ledger=v1) | the stored statements of a tree's valid object store together with the stored observations and kept objects of a valid, intact log branch |
| [extend](sinter:#ledger-extension=v1), [intact](sinter:#intact-history=v1) | a commit `d` extends `c` along a single-parent chain that drops or alters no chunk line; a log branch history is intact when its tip extends a root commit with every reached commit valid and reaches every reflog commit of its remote-tracking ref |
| [acceptance rule](sinter:#accepted-entry=v1), [accepted](sinter:#accepted-entry=v1) | the condition under which a statement or observation is accepted; the Ledger defines the acceptance rule of `void` |
| [base comparison](sinter:#base-comparison=v1) | the base tree `B` and head tree `H` compared by change checks and default-branch checks (caller-named base, change base, or first parent; missing when a change has no base or a default-branch head is a shallow commit) |
| [agent marker](sinter:#agent-marker=v1), [job marker](sinter:#job-marker=v1) | an environment variable named by `agent-markers` showing an agent runs the execution; an environment variable named by `job-markers` showing the execution is the job |
| [`invalid-store-entry`](sinter:#invalid-store-entry-finding=v1) | non-ackable finding class reporting a symbolic link (`120000`), submodule (`160000`), or non-UTF-8 entry name at `.sinter` or inside `.sinter/` and outside `.sinter/local/` in a checked commit |
| [`altered-store-file`](sinter:#altered-store-file-finding=v1) | non-ackable finding class of the check "Only added" reporting a base store file altered or deleted without an allowed exception |
| [`withdrawn-store-file`](sinter:#withdrawn-store-file-finding=v1) | non-ackable finding class of the check "Withdrawn files" reporting a new or changed store file whose canonical object a counting void withdraws |
| [`agent-writer`](sinter:#agent-writer-finding=v1) | non-ackable finding class of the check "Writers" reporting a judgment or void carrying the member `agent` |
| [`unaccepted-statement`](sinter:#unaccepted-statement-finding=v1) | non-ackable finding class of the check "Kind rules" reporting a statement that fails a cross-object rule or the acceptance rule of its kind |
| [`non-latest-target`](sinter:#non-latest-target-finding=v1) | non-ackable finding class of the check "Latest targets" reporting a new unwithdrawn non-void statement naming a non-latest record with `revises` or `judges` |
| [`statement-conflict`](sinter:#statement-conflict-finding=v1) | non-ackable finding class of the check "Conflicts" reporting a conflict in a tree |

## 2. The ledger, the log branch, and the checks

### 2.1 Statements in `.sinter/` and observations on the log branch

The ledger of a repository splits across two stores (term
`stored-ledger`). Statements (definitions, judgments, and voids) live in
the object store of a tree under `.sinter/` outside `.sinter/local/`,
one canonical object per file (`object-store#tree-object-store`), with
no central order and no member `seq`. Observations (`delivered` and
`progress`) and kept objects (merged declared items and the computed
identity objects that they need) live on the log branch, named by the
parameter `log-branch-name` (such as `sinter-log`).

Every record conforms to its row of `ontology#object-kind`, carries a
required member `by`, and holds its links in `edges`. Conforming
programs write no `seq` and no `branch` on statements and no `agent` on
observations; statements may carry `agent` and `ts`. Observations carry
`seq` (numbered 1 to `m` across observations on the log branch) and may
carry `ts`. Kept objects carry neither `by` nor `seq`. When a conforming
program writes `ts`, `ts` uses the RFC 3339 format of `entry-field`,
such as `2026-10-31T14:05:09Z`.

### 2.2 Log-branch lines, chunks, and closure

The git tree object of a log-branch commit holds chunks: regular files
with mode `100644` at chunk paths of the form
`entries/<2 hex>/<32 hex>.jsonl` (terms `chunk-path` and `chunk`). Each
line of a chunk is a canonical envelope line `{"id":"...","object":{...}}`
followed by `0x0A` (schema `log-branch-line`). The member `object` is a
canonical line object of one of the fourteen kinds that
`ontology#object-kind` marks as allowed on the log branch, and `id` is
its content id (`ontology#content-id`). A line of an unknown or
disallowed kind that is not a newer line makes the log branch broken.

For example, a `progress` observation has the content id
`progress:f457e35a60af035247dce0814e5ebe1c` and the chunk path
`entries/f4/f457e35a60af035247dce0814e5ebe1c.jsonl` when it is the first
line of its chunk:

```
{"id":"progress:f457e35a60af035247dce0814e5ebe1c","object":{"by":"ci-bot","head":"1111111111111111111111111111111111111111","kind":"progress","seq":1,"ts":"2026-10-31T14:05:09Z","v":1}}
```

A kept declared item and a kept computed identity object use the same
plain envelope with no `seq` and no `by`, deduplicated by `id`:

```
{"id":"req:e24c49b7d08a4e9545fb0fccc8743761","object":{"edges":[{"kind":"about","to":"name:0f17c8dd86ac60f052972d0be8ace0c2"},{"kind":"cites","to":"name:5bf08b8c6eb65e796933fb330e48a007"}],"kind":"req","label":"v1","name":"billing#cap","text":"Limit amounts with fee.","v":1}}
{"id":"name:5bf08b8c6eb65e796933fb330e48a007","object":{"kind":"name","name":"billing#fee","v":1}}
```

Closure on the log branch is key-present (term `needed-log-identity`).
In the example above, `req:e24c49b7d08a4e9545fb0fccc8743761` holds its
own `name` (`billing#cap`), so it does not need a line for
`name:0f17c8dd86ac60f052972d0be8ace0c2`; it does need the line for
`name:5bf08b8c6eb65e796933fb330e48a007`. When a valid log branch lacks a
computed identity object that a kept declared item needs, the log branch
stays valid. The check "Growth of the log branch" gives a
`conformance#report` identifying that kept object and that missing
identity content id (`validate-histories`). When no input of the run
gives that computed identity object or its key, it is a missing part, so
a program withholds only the results that need its key; when another
input of the run (such as a text file) gives it, the program still gives
that closure report and gives every result.

A chunk line whose `object` has an integer `v` greater than 1 and whose
`id` matches the hash id of `object`'s canonical byte sequence is a
newer line (term `newer-line`), which makes the log branch `"newer"`. A
damaged `v: 2` line whose `id` does not match that hash is not a newer
line and makes the log branch `"broken"`.

### 2.3 Reading the log branch and checking its growth

Checks read the log branch from the remote-tracking ref of the log
branch: the mapped ref (`changes#mapped-ref`) of
`refs/heads/<log-branch-name>` for the remote named by `ledger-remote`
(term `log-branch-ref`). Checks fetch no ref and call no host, while
partial-clone fetches of missing git objects stay allowed during reads
(`report-missing-ledger-objects`).

When the repository has no mapped ref for the log branch, or when its
remote-tracking ref does not exist, the log branch is missing: it is
never read as an empty valid log branch. A program reports that the
job's records are missing (`report-missing-log-branch`), gives no
observation and no kept object, and withholds every result that depends
on observations or kept objects (`give-states-only-from-valid-ledgers`),
while still giving results that depend only on the tree.

When the remote-tracking ref exists and the repository holds its ledger
objects, the log branch is `"valid"`, `"broken"`, or `"newer"` (atom
`ledger-validity`, requirement `validate-ledgers`). The check "Growth of
the log branch" checks that the history of the log branch is intact
(atom `intact-history`, requirement `validate-histories`): the tip
extends a root commit along a single-parent chain of valid log-branch
trees that never drops or changes a line, and the tip reaches every
reflog commit (`changes#reflog-commit`) of the remote-tracking ref. When
the log branch is broken, newer, or not intact, or when ledger or
history objects are missing, a program gives no observation, no kept
object, and no result that depends on observations or kept objects.

### 2.4 Writing statements and updating the log branch

A conforming program writes statement files to `.sinter/` through the
rules and safety obligations of the Object store (`object-store`), only
when the statement is accepted (`append-only-accepted-entries`) and has
valid fields (`write-entry-fields`).

Only the job creates or updates the log branch
(`append-only-to-valid-ledgers`, `leave-delivered-entries-to-job`). The
first run creates a root commit holding the initial observations and
kept objects. Each later run appends to a valid, intact log branch in a
commit that extends the tip, assigns the next `seq` values to new
observations, deduplicates kept objects by `id`, includes each needed
computed identity object for key-present closure, and pushes to the
remote as a plain fast-forward (`append-entries-at-end`). When the
remote refuses a fast-forward push because another run pushed first, the
job fetches the log branch again, checks that the fetched tip is valid
and intact, drops observations already recorded and kept objects whose
`id` is already present, renumbers `seq` on the remaining observations,
and pushes again — or stops after a number of refusals of its own
choice, reports that it stopped, and writes nothing more.

In every fetch or push of the log branch, a program runs no configured
program that `changes#run-no-configured-programs` forbids
(`limit-programs-in-log-transfers`). After a program reaches a limit of
its own in a run, the program writes no further statement, appends no
further observation or kept object, and makes no further update of the
log branch in that run (`change-no-ledger-after-stop`). In a run in
which the program could not read a file, a folder, or a git object under
`conformance#input`, the program writes no statement, appends no
observation or kept object, and makes no update of the log branch
(`write-no-log-after-read-error`).

What a conforming program gives while another process changes an input
repository or working tree is a matter of quality of implementation; the
safety obligations still hold.

### 2.5 Voids, acceptance rules, and conflicts

A `void` statement in `.sinter/` withdraws one withdrawable object in
`.sinter/` or on the log branch (including a kept declared-item object
or an observation, never a `void`, a `task`, a `plan`, a computed
identity object, or a `vector-group-def`). For example, to withdraw the
approval `approval:eb7c19392daf9123c7fc2506385dc3e4` of
`req:f6259f147d032738f64394a0796087a3`, a person writes the `void` file
at `.sinter/36/36cfcb55423e10ddf3cf0c8352d9cf69.json`:

```json
{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"req:f6259f147d032738f64394a0796087a3"},{"kind":"judges","to":"req:f6259f147d032738f64394a0796087a3"},{"kind":"withdraws","to":"approval:eb7c19392daf9123c7fc2506385dc3e4"}],"kind":"void","reason":"recorded by mistake","ts":"2026-10-31T14:15:00Z","v":1,"withdrawn-kind":"approval"}
```

The `void` copies the withdrawn object's edges to non-identity objects
in its own `edges` (for a withdrawn declared item, only its `revises`
edges; for a withdrawn `scope` object or record, every edge whose target
is not a computed identity object). When the valid inputs (the valid
object store of the checked tree, the valid object store of any base
tree, or the valid, intact log branch) hold the withdrawn object, the
acceptance rule of `void` (`accepted-entry`) checks that the `void`'s
copied edges match those exact edges; when no valid input holds the
withdrawn object, the acceptance rule checks only that the copied edges
fit `withdrawn-kind`. Whether a `void` counts as a
counting void follows `ontology#object-withdrawal`, which excludes
voids carrying `agent` and applies any bound list of persons (with
withholding under an invalid binding).

A counting void withdraws its target across `.sinter/` and the log
branch while leaving log-branch bytes intact and never withdrawing a
declared item in the text encoding. Its copied `revises` edges keep
replaced objects replaced. When a counting void withdraws the only
latest statement of a group, that group has no latest statement, so a
new statement of that group names no record with `revises`.

The non-ackable finding classes `unaccepted-statement` (check "Kind
rules", required here for `void`) and `statement-conflict` (check
"Conflicts") report unaccepted statements and conflicts across record
kinds.

### 2.6 Checks of `.sinter/` in a commit, a change, and a working tree

Beside the Object store's check "Form", five checks of `.sinter/` and
one notice for uncommitted store files apply:

- **Git entries at or inside `.sinter/`** (`invalid-store-entry`,
  requirement `give-store-entry-findings`): in a checked commit's git
  tree object, reports every symbolic link (`120000`), submodule
  (`160000`), and entry with a non-UTF-8 name at `.sinter` or inside
  `.sinter/` and outside `.sinter/local/`, while accepting executable
  regular files (`100755`).
- **Only added** (`altered-store-file`, requirement
  `give-only-added-findings`): compares a head tree with a base tree
  (term `base-comparison`: a caller-named base, the change base on a
  branch, or the first parent on the default branch) and reports every
  base store file that changed or disappeared, except a deleted valid
  object file withdrawn by a counting void in a valid head object store
  or a deleted unneeded computed identity file when every head store
  file is valid.
- **Withdrawn files** (`withdrawn-store-file`, requirement
  `give-withdrawn-file-findings`): reports every new or changed valid
  object file in a valid head object store (not matching the base tree
  byte for byte) whose canonical object a counting void in the head tree
  withdraws.
- **Writers (`agent`)** (`agent-writer`, requirement
  `give-agent-writer-findings`): reports every judgment or void in a
  tree's valid object store that carries `agent`.
- **Latest targets** (`non-latest-target`, requirement
  `give-latest-target-findings`): for a change, reports each record
  content id that a new, unwithdrawn non-void statement names with
  `revises` (or `judges` on `done` or `abandoned`) when that target is
  not a latest statement in the head tree with that new statement and
  its new replacements removed.
- **Uncommitted store files** (`report-uncommitted-statements`): when
  checking a working tree whose `.sinter/` holds any store file absent
  from or differing from the head commit, gives a notice that it read
  uncommitted store files.

### 2.7 Agents, the job, and trackers

An agent marker shows that an agent runs an execution (term
`agent-marker`); a job marker shows that an execution is the job (term
`job-marker`). Under an agent marker, each statement that a program
writes carries `agent` (`record-agent-writers`), and the program writes
no judgment, no void, and no observation, and writes nothing to the log
branch (`limit-agents-to-definitions`). Only the job (without an agent
marker) appends observations or kept objects to the log branch
(`leave-delivered-entries-to-job`).

A record may name an external item by its external id, such as `gh/42`,
through an `ext` computed identity object, and holds no other data taken
from a tracker (`keep-tracker-data-out`). Git objects that a host
adapter reads from a host are not data of a tracker.

## 3. Parameters

### 3.1 `agent-markers`

@schema agent-markers=v1
@cites {ontology#{parameter=v1}, text#{text=v1, code-span=v1}}

A binding of the parameter `agent-markers` is a finite set of texts.

### 3.2 `job-markers`

@schema job-markers=v1
@cites {ontology#{parameter=v1}, text#{text=v1, code-span=v1}}

A binding of the parameter `job-markers` is a finite set of texts.

### 3.3 `ledger-remote`

@schema ledger-remote=v1
@cites {ontology#{parameter=v1}, text#{text=v1, code-span=v1}}

A binding of the parameter `ledger-remote` is a text, such as `origin`.

### 3.4 `log-branch-name`

@schema log-branch-name=v1
@cites {
    ontology#{parameter=v1},
    changes#{branch-name=v1},
    text#{code-span=v1},
}

A binding of the parameter `log-branch-name` is a branch name
(`changes#branch-name`), such as `sinter-log`.

## 4. Definitions

### 4.1 The ref of the log branch

@term log-branch-ref=v1
@cites {
    gitdoc/git-config,
    conformance#{input=v1},
    ontology#{log-branch=v1, parameter=v1},
    changes#{
        commit=v1, ref-name=v1, ref-commit=v1, branch-name=v1,
        git-configuration=v1, remote-transfer=v1, mapped-ref=v1,
    },
    text#{text=v1, code-span=v1},
    #{ledger-remote=v1, log-branch-name=v1},
}

Under a valid binding `b` of `log-branch-name` and a valid binding `r`
of `ledger-remote`:

- The remote ref name of the log branch is the ref name `refs/heads/`
  followed by `b`.
- The remote-tracking ref of the log branch of a git repository is the
  mapped ref (`changes#mapped-ref`) of `refs/heads/` followed by `b` for
  the remote `r` in that git repository, when `refs/heads/` followed by
  `b` has a mapped ref for `r`. Otherwise, the git repository has no
  remote-tracking ref of the log branch.
- The log-branch commit of a git repository is the commit of its
  remote-tracking ref of the log branch (`changes#ref-commit`), when
  that git repository has a remote-tracking ref of the log branch and
  that ref has a commit.
- The log branch of a git repository is missing when the git repository
  has no remote-tracking ref of the log branch, or when that
  remote-tracking ref does not exist. A missing log branch is a part
  that a valid input can lack under `conformance#input`, and is never a
  valid empty log branch.
- The remote log-branch repository of a git repository for a fetch is
  the git repository at the address of the remote `r` for a fetch, as
  the page git-config and `changes#remote-transfer` give that address;
  for a push, it is each git repository at an address of the remote `r`
  for a push.

### 4.2 Chunk paths

@term chunk-path=v1
@cites {
    rfc/5234,
    rfc/7405,
    text#{
        production=v1, rule-name=v1, hex-digit=v1, text=v1,
        character=v1, code-span=v1,
    },
}

A chunk path is a text that matches the production `chunk-path` and in
which the two hex digits right after `entries/` equal the first two hex
digits right after the second `/`:

```abnf
chunk-path  = %s"entries/" 2hex-digit "/" 32hex-digit %s".jsonl"
```

### 4.3 Chunks and their lines

@term chunk=v1
@cites {
    changes#{commit-file=v1},
    text#{byte=v1, byte-sequence=v1, utf-8-encoding=v1, 0x-numeral=v1},
    #{chunk-path=v1},
}

A chunk of a git tree object is a regular-file entry that is among the
entries of that git tree object and whose byte path is the UTF-8
encoding of a chunk path. The chunk path of the chunk is that chunk
path. The content of a chunk is the content of the blob that the chunk
names. The lines of a chunk are the byte sequences that remain when its
content is cut right after each byte 0x0A, without an empty byte
sequence at the end. So each line of a chunk, other than the last, ends
with the byte 0x0A and holds no other byte 0x0A. The lines of a git tree
object are the lines of its chunks. A line counts once each time that it
stands in a chunk, so the same bytes in two chunks, or twice in one
chunk, are two lines.

### 4.4 Log-branch lines

@schema log-branch-line=v1
@cites {
    data-forms#{
        json-value=v1, line-object=v1, canonical-byte-sequence=v1,
    },
    ontology#{
        object=v1, object-kind=v1, content-id=v1, log-branch=v1,
    },
    text#{byte=v1, byte-sequence=v1, 0x-numeral=v1, code-span=v1},
}

A byte sequence meets `log-branch-line` (is a valid log-branch line)
when, and only when, all four of these conditions hold:

1. It ends with the byte 0x0A, and the byte sequence before that final
   byte 0x0A is the canonical byte sequence of a JSON object that has
   exactly two members: `id`, whose value is a string, and `object`,
   whose value is a line object (`data-forms#line-object`).
2. That line object meets its row of `ontology#object-kind`.
3. The value of the member `kind` of that line object is one of the
   fourteen object kinds that `ontology#object-kind` marks as allowed on
   the log branch.
4. The value of `id` equals the content id (`ontology#content-id`) of
   that canonical object.

For a valid log-branch line, its envelope id is the value of its member
`id`, and its canonical object is the line object held by its member
`object`.

### 4.5 Newer lines

@term newer-line=v1
@cites {
    data-forms#{
        json-value=v1, json-value-of-a-byte-sequence=v1,
        canonical-byte-sequence=v1, id-prefix=v1, hash-id=v1,
    },
    text#{
        byte=v1, byte-sequence=v1, 0x-numeral=v1, code-span=v1,
        whole-number=v1,
    },
    #{chunk=v1},
}

A line of a chunk is a newer line when, and only when, all three of
these conditions hold:

1. It ends with the byte 0x0A, and the JSON value of the byte sequence
   before that final byte 0x0A (`data-forms#json-value-of-a-byte-sequence`)
   is a JSON object that has the member `id` with a string and the
   member `object` with a JSON object `o`.
2. `o` has the member `v` with an integer greater than 1 and the member
   `kind` with a string `k` such that `k` followed by `:` is an id
   prefix (`data-forms#id-prefix`).
3. The value of `id` equals the hash id (`data-forms#hash-id`) of the
   canonical byte sequence of `o` with the id prefix `k:` and length 32.

### 4.6 Fields of records

@schema entry-field=v1
@cites {
    rfc/3339,
    conformance#{conforming-program=v1},
    ontology#{
        ledger-entry=v1, statement=v1, job-record=v1, void-statement=v1,
        object-kind=v1, person=v1, agent=v1, job=v1, edge=v1,
    },
    data-forms#{json-value=v1},
    text#{text=v1, code-span=v1},
}

A field of a record is a member of its canonical object that
`ontology#object-kind` or another design names for records of its kind.
The common fields of records follow `ontology#object-kind`:

- `kind`, a required string naming the record kind;
- `v`, a required integer equal to 1;
- `by`, a required string naming the person who wrote the statement, the
  person for whom the agent acts, or the job;
- `agent`, an optional string on statements naming the agent that wrote
  the statement (not written by a conforming program on observations);
- `seq`, a required integer of 1 or more on observations giving the
  observation's sequence number on the log branch (not written by a
  conforming program on statements);
- `ts`, an optional string giving the time at which the record was
  written: when written by a conforming program, a text that matches the
  rule `date-time` of RFC 3339, with the letters `T` and `Z` in upper
  case, with `Z` as its time offset, and with no fraction of a second,
  such as `2026-10-31T14:05:09Z`;
- `edges`, an optional set of flat edge objects (absent when empty and
  absent on `progress`), as `ontology#object-kind` and `ontology#edge`
  define it.

The fields of the kind `void` beyond the common fields are
`withdrawn-kind` (a required string matching the object kind word of the
target of its `withdraws` edge) and `reason` (a required string giving
the reason for the withdrawal). The fields of any other kind of record
are the members listed by its row of `ontology#object-kind` and defined
by the design that owns that kind.

### 4.7 Writers of records

@term entry-writer=v1
@cites {
    ontology#{ledger-entry=v1, person=v1, agent=v1, job=v1},
    data-forms#{json-value=v1},
    text#{code-span=v1},
    #{entry-field=v1},
}

When a record has the member `agent`, the writer that the record records
is the agent that the member `agent` of that record names. When a record
has no member `agent`, the writer that the record records is the person
or the job that the member `by` of that record names.

### 4.8 Ledger objects

@term ledger-object=v1
@cites {
    changes#{commit=v1, ref-commit=v1, commit-file=v1, ancestry=v1},
    #{log-branch-ref=v1, chunk=v1},
}

For a commit `c` whose git tree object is `t`, the ledger objects of `c`
are `c`, `t`, each git tree object that a tree entry among the entries
of `t` names, and each blob that a chunk of `t` names. For a git
repository whose remote-tracking ref of the log branch exists, the
ledger objects of that git repository are the git object to which its
remote-tracking ref of the log branch resolves (`changes#ref-commit`)
and, when that git object is a commit, the ledger objects of that
commit. The history objects of that git repository are its ledger
objects and, for each commit that its log-branch commit reaches, the
ledger objects of that commit. A git repository does not hold the ledger
objects of a commit when a tree entry among the entries of its git tree
object names a git object that is not a git tree object, when a chunk of
its git tree object names a git object that is not a blob, or when any
of those git objects is absent.

### 4.9 Valid log-branch trees

@schema valid-ledger-tree=v1
@cites {
    changes#{commit-file=v1},
    data-forms#{json-value=v1},
    ontology#{content-hash=v1, job-record=v1},
    text#{whole-number=v1, character=v1, utf-8-encoding=v1, code-span=v1},
    #{chunk-path=v1, chunk=v1, log-branch-line=v1, newer-line=v1},
}

A git tree object is newer when at least one of its lines is a newer
line. A git tree object that is not newer is a valid log-branch tree
when, and only when, each of these five conditions holds:

1. Its entries, at any depth, are exactly these: its chunks, each with
   the mode 100644; for each of its chunks, the tree entry whose byte
   path is the UTF-8 encoding of the first 10 characters of the chunk
   path of that chunk; and, when the git tree object has at least one
   chunk, the tree entry whose byte path is the UTF-8 encoding of
   `entries`. No two entries of the git tree object have the same byte
   path.
2. The content of each of its chunks has at least one line, and each
   line of each of its chunks meets `log-branch-line`.
3. For each chunk of the git tree object, the 32 characters of its chunk
   path after the first 11 characters (before `.jsonl`) equal the first
   32 hex digits of the content hash of the canonical object of the
   first line of that chunk.
4. No two of its lines have the same envelope id.
5. For the number `m` of its lines whose canonical object has `kind`
   equal to `delivered` or `progress`, the values of `seq` of those `m`
   canonical objects are the whole numbers from 1 to `m`, each once.

### 4.10 Needed computed identity objects on the log branch

@term needed-log-identity=v1
@cites {
    conformance#{input=v1, own-store=v1},
    ontology#{
        object=v1, object-kind=v1, computed-identity=v1,
        declared-item=v1, content-id=v1, edge=v1, log-branch=v1,
    },
    object-store#{tree-object-store=v1},
    data-forms#{json-value=v1},
    text#{code-span=v1},
    #{log-branch-line=v1, valid-ledger-tree=v1},
}

Let `O` be a canonical object of a valid log-branch line, and let `c` be
a content id whose object kind word is one of the five computed identity
kinds (`name`, `pin`, `ext`, `vector-set`, and `vector-group`).

`O` holds the key of `c` itself when, and only when, `O` is a
declared-item object and `c` is the content id of the `name` computed
identity object whose member `name` equals the member `name` of `O`.

`O` needs the computed identity object `c` when, and only when, `O`
holds at least one edge in its member `edges` whose member `to` equals
`c`, and `O` does not hold the key of `c` itself.

On a valid log-branch tree `t`, a canonical object `O` of a line of `t`
is unclosed for `c` when, and only when, `O` needs `c` and no line of
`t` has envelope id `c`. An unclosed kept object does not make `t` not a
valid log-branch tree. Such an absent computed identity object is a part
that a valid log branch can lack under `conformance#input`: when no
input of a run (neither the log branch, nor a declared-item object
holding its own `name` key, nor any valid encoding input, nor a valid
program's own store) gives that computed identity object or its key (as
`object-store#tree-object-store` defines these words), that computed
identity object is a missing part of the run, and a thing that a
requirement obliges needs that missing part when, and only when, that
thing needs its key. When another input of the run gives that computed
identity object or its key, the run does not lack that part.

### 4.11 Valid, broken, and newer log branches

@atom ledger-validity=v1
@cites {
    changes#{commit=v1, ref-commit=v1},
    #{log-branch-ref=v1, ledger-object=v1, valid-ledger-tree=v1},
}

For a git repository whose log branch is not missing (its
remote-tracking ref of the log branch exists) and that holds its ledger
objects, the log branch is newer, valid, or broken:

- The log branch is newer when, and only when, its remote-tracking ref
  has a commit whose git tree object is newer.
- The log branch is valid when, and only when, its remote-tracking ref
  has a commit whose git tree object is a valid log-branch tree.
- The log branch is broken when, and only when, the log branch is
  neither newer nor valid: its remote-tracking ref exists and has no
  commit, or the git tree object of its log-branch commit is neither
  newer nor a valid log-branch tree.

### 4.12 Stored ledgers

@term stored-ledger=v1
@cites {
    conformance#{own-store=v1},
    ontology#{
        ledger=v1, statement=v1, job-record=v1, log-branch=v1,
        declared-item=v1, computed-identity=v1, object=v1, tree=v1,
        state-input=v1,
    },
    object-store#{tree-object-store=v1},
    text#{code-span=v1},
    #{
        log-branch-ref=v1, chunk=v1, log-branch-line=v1,
        valid-ledger-tree=v1, ledger-validity=v1,
    },
}

For a tree `T` whose object store (`object-store#tree-object-store`) is
valid, the stored statements of `T` are the set of all canonical objects
of the seven statement kinds (`ontology#statement`) that the object
store of `T` holds.

For a valid log-branch tree `t`:

- The stored observations of `t` are the canonical objects of the lines
  of `t` whose `kind` is `delivered` or `progress`, in increasing order
  of their `seq` (no state depends on `seq`).
- The kept objects of `t` are the set of canonical objects of the lines
  of `t` whose `kind` is one of the seven declared-item kinds or one of
  the five computed identity kinds.

For a git repository whose log branch is not missing, holds its ledger
objects, and is valid, its stored observations and kept objects are
those of the git tree object of its log-branch commit. Together with the
stored statements of a tree (or the same canonical objects from a valid
program's own store), they form the stored ledger for that tree and git
repository.

### 4.13 Extensions

@term ledger-extension=v1
@cites {changes#{commit=v1}, #{chunk=v1}}

Extension is the smallest relation between commits in which each commit
`d` extends `d`, and a commit `d` extends a commit `c` when `d` has
exactly one parent, that parent extends `c`, and each line of the git
tree object of that parent is a line of the git tree object of `d`.

### 4.14 Intact histories

@atom intact-history=v1
@cites {
    changes#{commit=v1, ancestry=v1, reach=v1, reflog-commit=v1},
    text#{result=v1},
    #{
        log-branch-ref=v1, ledger-object=v1, valid-ledger-tree=v1,
        ledger-extension=v1,
    },
}

For a git repository whose log branch is not missing, whose log-branch
commit's git tree object is not newer (when its remote-tracking ref has
a commit), and that holds its history objects, the history of the log
branch is intact when, and only when, all three of these conditions
hold:

1. Its remote-tracking ref `R` of the log branch has a commit `c`, and
   `c` extends a commit that has no parent.
2. The git tree object of each commit that `c` reaches is a valid
   log-branch tree.
3. `c` reaches (`changes#reach`) every reflog commit
   (`changes#reflog-commit`) of `R`.

When `R` exists and has no commit, the history of the log branch is not
intact. For a git repository whose log branch is not missing, not newer,
and holds its history objects, the result for whether its history is
intact is "valid" when intact, and "invalid" when not intact.

### 4.15 Accepted records and the acceptance rule of `void`

@term accepted-entry=v1
@cites {
    conformance#{design=v1, input=v1},
    ontology#{
        ledger-entry=v1, statement=v1, job-record=v1, void-statement=v1,
        object-withdrawal=v1, object-kind=v1, declared-item=v1,
        computed-identity=v1, content-id=v1, edge=v1, thing=v1, tree=v1,
    },
    object-store#{tree-object-store=v1},
    data-forms#{json-value=v1},
    text#{code-span=v1},
    #{
        log-branch-ref=v1, ledger-object=v1, ledger-validity=v1,
        intact-history=v1,
    },
}

The acceptance rule of a kind of statement or observation is the
condition, which a design gives for that kind, under which a record of
that kind is accepted in a tree (for a statement) or on the log branch
(for an observation). A record of a kind for which no design gives an
acceptance rule is not accepted.

This design gives the acceptance rule of the kind `void`. For a tree `T`
whose object store (`object-store#tree-object-store`) is valid, let `V`
be a `void` object in `T`, and let `U` be the set of canonical objects
held by the valid inputs of the operation: the object store of `T`, the
object store of any base tree `B` when a change is checked and the
object store of `B` is valid, and the log branch when it is not missing,
holds its ledger objects and history objects, is valid, and is intact.
When the object store of `T` is not valid, no `void` is accepted in `T`
(an object store that holds a store file that is not valid gives no
result over its objects and no finding under this rule); when the object
store of `B` is not valid, `B` contributes no canonical object to `U`.
`V` is accepted in `T` when, and only when, all three of these
conditions hold:

1. `V` meets its row of `ontology#object-kind` (so its one `withdraws`
   edge names a content id `w` of a withdrawable kind — never `void`,
   `task`, `plan`, a computed identity kind, or `vector-group-def` — its
   `withdrawn-kind` equals the object kind word of `w`, and no edge of
   `V` targets a computed identity kind).
2. Every edge of `V` other than its `withdraws` edge is permitted for
   `withdrawn-kind`: when `withdrawn-kind` is one of the seven
   declared-item kinds, every such edge has `kind` equal to `revises`
   and targets a declared-item kind; when `withdrawn-kind` is another
   withdrawable kind, every such edge has an edge kind and a
   non-identity target kind permitted by the row of `withdrawn-kind` in
   `ontology#object-kind`.
3. When `U` holds an object `X` whose content id equals `w`, the set of
   edges of `V` other than its `withdraws` edge equals: for a
   declared-item kind, the set of `revises` edges of `X`; for any other
   withdrawable kind, the set of edges of `X` whose target is not of one
   of the five computed identity kinds.

Whether a `void` counts in `T` (is a counting void in `T`), and its
effect on objects in `.sinter/`, kept objects on the log branch,
observations, replaced objects, and latest statements (including
withholding under an invalid binding of a list of persons), are given by
`ontology#object-withdrawal`, `ontology#void-statement`, and
`ontology#thing`. After a counting void withdraws the only latest
statement of a group of a thing, that group has no latest statement, so
a new statement of that group names no record with `revises`.

### 4.16 Base comparison for checks

@term base-comparison=v1
@cites {
    conformance#{input=v1},
    ontology#{tree=v1, default-branch=v1},
    changes#{
        commit=v1, commit-file=v1, change-base=v1, shallow-commit=v1,
        working-tree=v1, head-commit=v1,
    },
}

For a check that compares a head tree `H` with a base tree `B`:

- For a change on a branch, `H` is the checked tree of the change (such
  as the tree of the merge result commit, or a working tree), and `h` is
  the commit of that tree (for a working tree, its head commit). `B` is
  the tree of the base commit named by the caller or, when the caller
  names none, the tree of the base of the change of `h`
  (`changes#change-base`).
- On the default branch, for a head commit `h`, `H` is the tree of `h`,
  and `B` is the tree of the base commit named by the caller or, when
  the caller names none, the tree of the first parent of `h`, or the
  empty tree with zero files when `h` has no parent and is not a shallow
  commit (`changes#shallow-commit`).

When the caller names no base commit, and either (for a change) the
working tree has no head commit or the change of `h` has no base, or (on
the default branch) `h` is a shallow commit, `B` is a part that the git
repository lacks under `conformance#input`, and each finding of a check
that compares `H` with `B` needs that part. The choice of `B` never
reads the log branch.

### 4.17 Agent markers

@term agent-marker=v1
@cites {
    ontology#{parameter=v1, agent=v1},
    conformance#{input=v1},
    text#{text=v1, code-span=v1},
    #{agent-markers=v1},
}

An agent marker of a process is an environment variable of that process
whose name is a text of the binding of the parameter `agent-markers`,
whatever the value of that variable. The input of an execution of a
program says that an agent runs the execution when, and only when, the
environment of a process of that execution holds an agent marker.

### 4.18 Job markers

@term job-marker=v1
@cites {
    ontology#{parameter=v1, job=v1},
    conformance#{input=v1},
    text#{text=v1, code-span=v1},
    #{job-markers=v1},
}

A job marker of a process is an environment variable of that process
whose name is a text of the binding of the parameter `job-markers`,
whatever the value of that variable. The input of an execution of a
program says that the execution is the job when, and only when, the
environment of a process of that execution holds a job marker.

### 4.19 Findings of the class `invalid-store-entry`

@atom invalid-store-entry-finding=v1
@cites {
    findings#{
        finding-part=v1, finding-subject=v1, path-finding-subject=v1,
        message=v1, spot=v1, mark=v1, related-message=v1, fix=v1,
        ackable-finding=v1,
    },
    files#{path=v1},
    changes#{commit=v1, commit-file=v1},
    data-forms#{hex-text=v1},
    ontology#{finding-class=v1, tree=v1},
    text#{
        byte-sequence=v1, valid-utf-8=v1, utf-8-encoding=v1,
        text-of-a-byte-sequence=v1, code-span=v1,
    },
}

For a commit `c` whose git tree object is `T`, an entry `E` among the
entries of `T` (`changes#commit-file`), with byte path `bp`, lies at
`.sinter` or inside `.sinter/` and outside `.sinter/local/` when, and
only when, both of these hold:

1. `bp` equals the UTF-8 encoding of `.sinter`, or `bp` starts with the
   UTF-8 encoding of `.sinter/`.
2. `bp` does not start with the UTF-8 encoding of `.sinter/local/`.

`c` has one finding of the class `invalid-store-entry` for each entry
`E` of `T` at `.sinter` or inside `.sinter/` and outside
`.sinter/local/` that meets at least one of these three conditions, and
no other finding of that class:

- `E` is a symbolic-link entry (mode 120000);
- `E` is a submodule entry (mode 160000);
- the name of `E` is not valid UTF-8.

The finding has these parts:

- its tree is the tree of `c`;
- its finding class is `invalid-store-entry`;
- its subject is the path-finding subject
  (`findings#path-finding-subject`) of the text of `bp` when `bp` is the
  UTF-8 encoding of a valid path (`files#path`), and otherwise `bytes:`
  followed by the lowercase `data-forms#hex-text` of `bp`;
- it has no spot, no mark, and no fix, and it is not ackable;
- its message says what is wrong;
- its related messages are those that the program gives.

### 4.20 Findings of the class `altered-store-file`

@atom altered-store-file-finding=v1
@cites {
    findings#{
        finding-part=v1, finding-subject=v1, path-finding-subject=v1,
        message=v1, spot=v1, mark=v1, related-message=v1, fix=v1,
        ackable-finding=v1,
    },
    files#{path=v1},
    ontology#{
        finding-class=v1, tree=v1, object-withdrawal=v1,
        computed-identity=v1,
    },
    object-store#{
        store-file=v1, valid-object-file=v1, tree-object-store=v1,
        needed-identity-file=v1,
    },
    #{base-comparison=v1},
}

For a base tree `B` and a head tree `H`, `H` has one tree finding of the
class `altered-store-file` for each store file `F` of `B` (with valid
path `p` and content `b`) such that `H` does not hold a store file at
`p` with content `b`, except when `H` holds no file at `p` and at least
one of these two exceptions holds, and no other finding of that class:

1. Every store file of `H` is a valid object file, and `F` is a valid
   object file whose canonical object is withdrawn by a counting void
   (`ontology#object-withdrawal`) in `H`.
2. Every store file of `H` is a valid object file, `F` is a valid object
   file whose canonical object is a computed identity object, and no
   canonical object of the object store of `H` needs the identity file
   of that computed identity object (`object-store#needed-identity-file`).

When `H` holds no file at `p`, every store file of `H` is a valid object
file, `F` is a valid object file, exception 2 does not hold, and whether
a `void` in `H` naming `F`'s canonical object counts is withheld under
`ontology#object-withdrawal`, whether `H` has an `altered-store-file`
finding for `F` is withheld.

The finding has these parts:

- its tree is `H`;
- its finding class is `altered-store-file`;
- its subject is the path-finding subject
  (`findings#path-finding-subject`) of `p`;
- its spot is `p` alone (with no span) in `H` when `H` holds a file at
  `p`, and none when `H` holds no file at `p`;
- it has no mark and no fix, and it is not ackable;
- its message says what is wrong;
- its related messages are those that the program gives.

### 4.21 Findings of the class `withdrawn-store-file`

@atom withdrawn-store-file-finding=v1
@cites {
    findings#{
        finding-part=v1, finding-subject=v1, path-finding-subject=v1,
        message=v1, spot=v1, mark=v1, related-message=v1, fix=v1,
        ackable-finding=v1,
    },
    files#{path=v1},
    ontology#{finding-class=v1, tree=v1, object-withdrawal=v1},
    object-store#{
        store-file=v1, valid-object-file=v1, tree-object-store=v1,
    },
    #{base-comparison=v1},
}

For a base tree `B` and a head tree `H` whose object store
(`object-store#tree-object-store`) is valid, `H` has one tree finding of
the class `withdrawn-store-file` for each valid object file `F` of `H`
(with valid path `p` and content `b`) such that `B` does not hold a
store file at `p` with content `b` and the canonical object of `F` is
withdrawn by a counting void (`ontology#object-withdrawal`) in `H`, and
no other finding of that class. When whether a `void` in `H` naming
`F`'s canonical object counts is withheld under
`ontology#object-withdrawal`, whether `H` has a `withdrawn-store-file`
finding for `F` is withheld.

The finding has these parts:

- its tree is `H`;
- its finding class is `withdrawn-store-file`;
- its subject is the path-finding subject
  (`findings#path-finding-subject`) of `p`;
- its spot is `p` alone (with no span) in `H`;
- it has no mark and no fix, and it is not ackable;
- its message says what is wrong;
- its related messages are those that the program gives.

### 4.22 Findings of the class `agent-writer`

@atom agent-writer-finding=v1
@cites {
    findings#{
        finding-part=v1, finding-subject=v1, message=v1, spot=v1,
        mark=v1, related-message=v1, fix=v1, ackable-finding=v1,
    },
    ontology#{
        finding-class=v1, tree=v1, judgment=v1, void-statement=v1,
        agent=v1, content-id=v1,
    },
    object-store#{object-path=v1, tree-object-store=v1},
    data-forms#{json-value=v1},
    text#{code-span=v1},
    #{stored-ledger=v1, entry-writer=v1},
}

A tree `T` whose object store is valid has one tree finding of the class
`agent-writer` for each stored statement `S` of `T` that is a judgment
(`ontology#judgment`) or a void (`ontology#void-statement`) and whose
recorded writer (`entry-writer`) is an agent (that is, `S` carries the
member `agent`), and no other finding of that class.

The finding has these parts:

- its tree is `T`;
- its finding class is `agent-writer`;
- its subject is the content id of `S`;
- its spot is the object path of `S` alone (with no span) in `T` when
  taken from `.sinter/`, and none when taken from a program's own store;
- it has no mark and no fix, and it is not ackable;
- its message says what is wrong;
- its related messages are those that the program gives.

### 4.23 Findings of the class `unaccepted-statement`

@atom unaccepted-statement-finding=v1
@cites {
    findings#{
        finding-part=v1, finding-subject=v1, message=v1, spot=v1,
        mark=v1, related-message=v1, fix=v1, ackable-finding=v1,
    },
    ontology#{
        finding-class=v1, tree=v1, statement=v1, thing=v1,
        object-kind=v1, content-id=v1,
    },
    object-store#{object-path=v1, tree-object-store=v1},
    #{stored-ledger=v1, accepted-entry=v1},
}

A tree `T` whose object store is valid has one tree finding of the class
`unaccepted-statement` for each stored statement `S` of `T` that is not
accepted in `T` (fails a cross-object rule of `ontology#object-kind` or
fails the acceptance rule of its kind, `accepted-entry`), and no other
finding of that class. For statements of the kind `void`,
`accepted-entry` gives the acceptance rule; a design that gives an
acceptance rule for another kind of statement refines this class for
that kind.

The finding has these parts:

- its tree is `T`;
- its finding class is `unaccepted-statement`;
- its subject is the content id of `S`;
- its spot is the object path of `S` alone (with no span) in `T` when
  taken from `.sinter/`, and none when taken from a program's own store;
- it has no mark and no fix, and it is not ackable;
- its message says what is wrong;
- its related messages are those that the program gives.

### 4.24 Findings of the class `non-latest-target`

@atom non-latest-target-finding=v1
@cites {
    findings#{
        finding-part=v1, finding-subject=v1, message=v1, spot=v1,
        mark=v1, related-message=v1, fix=v1, ackable-finding=v1,
    },
    ontology#{
        finding-class=v1, tree=v1, statement=v1, void-statement=v1,
        judgment=v1, thing=v1, object-kind=v1, object-withdrawal=v1,
        edge=v1, content-id=v1, log-branch=v1,
    },
    object-store#{
        object-path=v1, store-file=v1, valid-object-file=v1,
        tree-object-store=v1,
    },
    text#{space=v1, code-span=v1},
    #{stored-ledger=v1, base-comparison=v1},
}

For a base tree `B` and a head tree `H` whose object store is valid, a
stored statement `S` of `H` is new relative to `B` when `B` does not
hold a valid object file whose canonical object has the content id of
`S`.

For a new stored statement `S` of `H` whose `kind` is not `void` and
that no counting void (`ontology#object-withdrawal`) in `H` withdraws,
let the reduced tree `H_S` be the tree `H` without the store files whose
canonical objects are `S` and every new stored statement of `H`
(relative to `B`) that replaces `S` (directly or through a chain of
`revises` edges, including copied `revises` edges of counting voids in
`H` that are new relative to `B`).

For each new stored statement `S` of `H` whose `kind` is not `void` and
that no counting void in `H` withdraws, and each content id `t` that `S`
names with a `revises` edge or (when `S` has `kind` equal to `done` or
`abandoned`) with a `judges` edge, `H` has one tree finding of the class
`non-latest-target` for the pair `(S, t)` when `t` is not the content id
of a latest statement of its group (`ontology#thing`) in `H_S`, and no
other finding of that class. In `H_S`, each cross-object rule of
`ontology#object-kind` reads only the objects of `H_S` (using the copied
edges of a counting void in `H_S` when `H_S` does not hold the target
object, as `ontology#thing` states), and reads neither `B` nor the log
branch. When whether a `void` in `H` naming `S` counts, or whether `t`
is a latest statement in `H_S`, is withheld under an invalid binding of
a list of persons (`ontology#thing`, `ontology#object-withdrawal`),
whether `H` has that finding is withheld.

The finding has these parts:

- its tree is `H`;
- its finding class is `non-latest-target`;
- its subject is the content id of `S`, then a space, then `t`;
- its spot is the object path of `S` alone (with no span) in `H` when
  taken from `.sinter/`, and none when taken from a program's own store;
- it has no mark and no fix, and it is not ackable;
- its message says that the writer did not see a newer statement;
- its related messages are those that the program gives.

### 4.25 Findings of the class `statement-conflict`

@atom statement-conflict-finding=v1
@cites {
    findings#{
        finding-part=v1, finding-subject=v1, message=v1, spot=v1,
        mark=v1, related-message=v1, fix=v1, ackable-finding=v1,
    },
    ontology#{
        finding-class=v1, tree=v1, conflict=v1, thing=v1,
        content-id=v1, declared-item=v1, work-item=v1,
        work-item-definition=v1,
    },
    object-store#{tree-object-store=v1},
    #{stored-ledger=v1},
}

A tree `T` whose object store is valid has one tree finding of the class
`statement-conflict` for each conflict (`ontology#conflict`) that exists
in `T`, and no other finding of that class. When whether a conflict
exists is withheld under `ontology#conflict` or `ontology#thing`,
whether `T` has that finding is withheld. A design that owns a kind of
statement or observation taking part in conflicts refines this class for
that kind.

The finding has these parts:

- its tree is `T`;
- its finding class is `statement-conflict`;
- its subject is the content id of the conflicted unit: for a conflict
  of judgments of a declared-item object `O`, the content id of `O`; for
  a conflict of definition statements of a work item `W`, the content id
  of `W`; and for a conflict of `done` and `abandoned` judgments of a
  task definition `D`, or of a completing `delivered` observation of `D`
  and one or more latest `abandoned` judgments of `D`, the content id of
  `D`;
- it has no spot, no mark, and no fix, and it is not ackable;
- its message says what is in conflict;
- its related messages are those that the program gives.

## 5. Requirements

### 5.1 Reading the stored ledger

@req give-stored-ledgers=v1
@cites {
    conformance#{
        conforming-program=v1, give-results-over-canonical-objects=v1,
    },
    ontology#{statement=v1, job-record=v1, log-branch=v1, tree=v1},
    changes#{repository-read=v1, undisturbed-read=v1},
    object-store#{tree-object-store=v1},
    #{
        log-branch-ref=v1, ledger-object=v1, ledger-validity=v1,
        intact-history=v1, stored-ledger=v1,
    },
}

When a conforming program gives the stored statements of a tree `T`, it
must give once each stored statement of `T` when the object store of `T`
is valid, and no other statement; it must give no stored statement of
`T` when the object store of `T` is not valid.

When a conforming program gives the stored observations or kept objects
of the log branch of a git repository in an undisturbed repository read,
it must give once each stored observation (in increasing order of `seq`
when ordered) and once each kept object, and no other observation or
kept object, when the log branch is not missing, the git repository
holds its ledger objects and its history objects, its log branch is
valid, and its history is intact. It must give no observation and no
kept object when the log branch is missing, broken, newer, or not
intact, or when the git repository does not hold its ledger objects or
its history objects.

### 5.2 The validation of the log branch

@req validate-ledgers=v1
@cites {
    conformance#{conforming-program=v1},
    changes#{repository-read=v1, undisturbed-read=v1},
    text#{result=v1},
    #{log-branch-ref=v1, ledger-object=v1, ledger-validity=v1},
}

When a conforming program gives a result for whether the log branch of a
git repository is valid in an undisturbed repository read, and the log
branch is not missing and the git repository holds its ledger objects,
the conforming program must give exactly one result: "valid" when the
log branch is valid, "broken" when the log branch is broken, and "newer"
when the log branch is newer. The conforming program must give no result
when the log branch is missing or when the git repository does not hold
its ledger objects.

### 5.3 Growth of the log branch

@req validate-histories=v1
@cites {
    conformance#{
        conforming-program=v1, report=v1, report-missing-parts=v1,
    },
    changes#{repository-read=v1, undisturbed-read=v1},
    text#{result=v1},
    #{
        log-branch-ref=v1, ledger-object=v1, ledger-validity=v1,
        intact-history=v1, needed-log-identity=v1,
    },
}

When a conforming program gives a result for whether the history of the
log branch of a git repository is intact in an undisturbed repository
read, and the log branch is not missing, the git repository holds its
history objects, and the log branch is not newer, the conforming program
must give exactly one result: "valid" when that history is intact, and
"invalid" when that history is not intact. The conforming program must
give neither result when the log branch is missing, when the log branch
is newer, or when the git repository does not hold its history objects.

When the log branch is valid and its history is intact, and a conforming
program checks the growth of the log branch, for each pair of a kept
object `O` of the log-branch commit and a computed identity content id
`c` such that `O` is unclosed for `c` (`needed-log-identity`), the
conforming program must give one `conformance#report` identifying `O`
and `c`, and must give no such report when `O` is not unclosed for `c`.
When no input of the run gives that computed identity object or its key,
that report is the report of this design for that missing part under
`conformance#report-missing-parts`.

### 5.4 States only from valid ledgers

@req give-states-only-from-valid-ledgers=v1
@cites {
    conformance#{conforming-program=v1},
    ontology#{state=v1, ledger=v1, job-record=v1, log-branch=v1, tree=v1},
    changes#{repository-read=v1, undisturbed-read=v1},
    object-store#{tree-object-store=v1},
    #{
        log-branch-ref=v1, ledger-object=v1, ledger-validity=v1,
        intact-history=v1, stored-ledger=v1,
    },
}

A conforming program must give no state or result that depends on
observations or kept objects of the log branch of a git repository in an
undisturbed repository read when the log branch is missing, broken,
newer, or not intact, or when the git repository does not hold its
ledger objects or history objects.

A conforming program must give no state or result that depends on the
stored statements of a tree when the object store of that tree is not
valid.

### 5.5 Missing log branch

@req report-missing-log-branch=v1
@cites {
    conformance#{
        conforming-program=v1, report=v1, report-missing-parts=v1,
    },
    changes#{repository-read=v1, undisturbed-read=v1},
    #{log-branch-ref=v1},
}

When a conforming program runs an operation on a git repository in an
undisturbed repository read that needs the log branch of that git
repository, and the log branch is missing (`log-branch-ref`), the
conforming program must give one `conformance#report` stating that the
job's records are missing, as the report for that missing part under
`conformance#report-missing-parts`, and must give no such report when
the log branch is not missing.

### 5.6 Missing ledger objects and check fetches

@req report-missing-ledger-objects=v1
@cites {
    conformance#{
        conforming-program=v1, report=v1, report-missing-parts=v1,
        safety-obligation=v1,
    },
    changes#{
        repository-read=v1, undisturbed-read=v1, remote-transfer=v1,
    },
    #{log-branch-ref=v1, ledger-object=v1},
}

In a read operation (any check that does not run as the job updating the
log branch), a conforming program must fetch no ref and must call no
host; the conforming program may let a repository read fetch git objects
that a partial clone leaves out (`changes#repository-read`).

When a conforming program runs an operation on a git repository in an
undisturbed repository read that needs the ledger objects of the log
branch, the log branch is not missing, and that git repository does not
hold its ledger objects after each permitted fetch of missing git
objects, the conforming program must give one `conformance#report`
stating that the git repository does not hold its ledger objects, and
must give no such report when it holds them.

When a conforming program runs an operation on a git repository in an
undisturbed repository read that needs the history objects of the log
branch, the log branch is not missing, and that git repository does not
hold its history objects after each permitted fetch of missing git
objects, the conforming program must give one `conformance#report`
stating that the git repository does not hold its history objects, and
must give no such report when it holds them.

### 5.7 Git entries at or inside `.sinter/` of a commit

@req give-store-entry-findings=v1
@cites {
    conformance#{conforming-program=v1},
    changes#{commit=v1, commit-file=v1},
    findings#{finding-part=v1},
    #{invalid-store-entry-finding=v1},
}

When a conforming program checks the git entries at or inside `.sinter/`
of a commit `c`, the conforming program must give once each finding of
the class `invalid-store-entry` that `c` has, and no other finding of
that class.

### 5.8 Only added

@req give-only-added-findings=v1
@cites {
    conformance#{conforming-program=v1},
    ontology#{tree=v1},
    findings#{finding-part=v1},
    #{base-comparison=v1, altered-store-file-finding=v1},
}

When a conforming program runs the check "Only added" comparing a base
tree `B` and a head tree `H` (`base-comparison`), the conforming program
must give once each tree finding of the class `altered-store-file` that
`H` has relative to `B`, and no other finding of that class.

### 5.9 Withdrawn files

@req give-withdrawn-file-findings=v1
@cites {
    conformance#{conforming-program=v1},
    ontology#{tree=v1},
    object-store#{tree-object-store=v1},
    findings#{finding-part=v1},
    #{base-comparison=v1, withdrawn-store-file-finding=v1},
}

When a conforming program runs the check "Withdrawn files" comparing a
base tree `B` and a head tree `H` (`base-comparison`) whose object store
is valid, the conforming program must give once each tree finding of the
class `withdrawn-store-file` that `H` has relative to `B`, and no other
finding of that class.

### 5.10 Agent writers on judgments and voids

@req give-agent-writer-findings=v1
@cites {
    conformance#{conforming-program=v1},
    ontology#{tree=v1},
    findings#{finding-part=v1},
    #{agent-writer-finding=v1},
}

When a conforming program runs the check "Writers" for `agent` on a tree
`T` whose object store is valid, the conforming program must give once
each tree finding of the class `agent-writer` that `T` has, and no other
finding of that class.

### 5.11 Kind rules for `void`

@req give-void-acceptance-findings=v1
@cites {
    conformance#{conforming-program=v1},
    ontology#{tree=v1, void-statement=v1},
    findings#{finding-part=v1},
    #{unaccepted-statement-finding=v1, accepted-entry=v1},
}

When a conforming program runs the check "Kind rules" on a tree `T`
whose object store is valid, for statements of the kind `void`, the
conforming program must give once each tree finding of the class
`unaccepted-statement` that `T` has for a `void` statement, and no other
finding of that class for a `void` statement.

### 5.12 Latest targets

@req give-latest-target-findings=v1
@cites {
    conformance#{conforming-program=v1},
    ontology#{tree=v1},
    findings#{finding-part=v1},
    #{base-comparison=v1, non-latest-target-finding=v1},
}

When a conforming program runs the check "Latest targets" for a change
comparing a base tree `B` and a head tree `H` (`base-comparison`) whose
object store is valid, the conforming program must give once each tree
finding of the class `non-latest-target` that `H` has relative to `B`,
and no other finding of that class.

### 5.13 Uncommitted store files

@req report-uncommitted-statements=v1
@cites {
    conformance#{conforming-program=v1},
    changes#{
        working-tree=v1, head-commit=v1, commit-file=v1,
        working-tree-file=v1, repository-read=v1, undisturbed-read=v1,
    },
    object-store#{store-file=v1},
}

When a conforming program checks a working tree of a git repository in
an undisturbed repository read, and the working tree holds at least one
store file that is absent from or has content different from the tree of
the head commit of that working tree (or the working tree has no head
commit and holds at least one store file), the conforming program must
give one notice (in any form that identifies the fact) stating that it
read uncommitted store files. When every store file of the working tree
matches the tree of its head commit byte for byte, the conforming
program must give no such notice.

### 5.14 Log-branch updates only by the job and on valid ledgers

@req append-only-to-valid-ledgers=v1
@cites {
    conformance#{conforming-program=v1, input=v1, safety-obligation=v1},
    ontology#{log-branch=v1, job=v1, agent=v1},
    #{
        log-branch-ref=v1, ledger-object=v1, ledger-validity=v1,
        intact-history=v1, job-marker=v1, agent-marker=v1,
    },
}

A conforming program must create or update the log branch only in an
execution whose input says that the execution is the job (`job-marker`)
and does not say that an agent runs the execution (`agent-marker`). When
the log branch already exists on the remote, a conforming program must
append to the log branch only when the repository holds its ledger
objects and history objects, its log branch is valid, and its history is
intact.

### 5.15 Appending to and pushing the log branch

@req append-entries-at-end=v1
@cites {
    conformance#{conforming-program=v1, report=v1},
    ontology#{
        log-branch=v1, job=v1, job-record=v1, declared-item=v1,
        computed-identity=v1, content-id=v1,
    },
    changes#{commit=v1, ancestry=v1, remote-transfer=v1},
    text#{whole-number=v1, code-span=v1},
    #{
        log-branch-ref=v1, chunk=v1, log-branch-line=v1,
        valid-ledger-tree=v1, needed-log-identity=v1,
        ledger-extension=v1, intact-history=v1,
    },
}

When a conforming program creates or updates the log branch in a run of
the job, it must satisfy all four of these conditions:

1. When creating the log branch (no commit exists on the remote), the
   new commit `d` extends a commit with no parent. When updating an
   existing tip commit `c`, `d` extends `c`. Every commit that `d`
   reaches and that `c` does not reach (or every commit that `d` reaches
   when creating) has a valid log-branch tree.
2. The lines of the git tree object of `d` are every line of `c` (when
   `c` exists), plus one valid log-branch line for each new observation
   (`delivered` or `progress`) with `seq` values `m + 1`, `m + 2`, and
   so on (where `m` is the number of observations in `c`, or 0 when
   creating), plus one valid log-branch line for each kept declared-item
   object and each computed identity object that it needs
   (`needed-log-identity`) whose content id is not already an envelope
   id of a line of `c`, deduplicated by envelope id (with no `seq` and
   no `by`).
3. When pushing `d` to the remote ref name of the log branch at each
   remote log-branch repository for a push (`log-branch-ref`), the
   conforming program must push only as a plain fast-forward (never
   changing the remote ref from an existing commit `r` to a commit that
   does not extend `r`).
4. When a remote refuses a fast-forward push because the remote ref
   moved to a newer commit, the conforming program must either:
   - fetch the log branch from the remote again, check that the fetched
     tip is valid and intact, drop each observation already recorded and
     each kept object whose content id the fetched tip already holds,
     assign the remaining observations the next values of `seq` (and
     matching content ids), build a new commit extending the fetched
     tip, and push again; or
   - stop after a number of refusals of its own choice, give one
     `conformance#report` stating that it stopped, and write nothing
     more.

### 5.16 Only accepted records written

@req append-only-accepted-entries=v1
@cites {
    conformance#{conforming-program=v1, input=v1},
    ontology#{
        statement=v1, job-record=v1, void-statement=v1, log-branch=v1,
    },
    #{accepted-entry=v1},
}

A conforming program must write a statement to `.sinter/` only when that
statement is accepted in the tree (`accepted-entry`), and for a `void`
statement only when the inputs hold the withdrawable object that its
`withdraws` edge names. A conforming program must append an observation
to the log branch only when that observation is accepted by the
acceptance rule of its kind.

### 5.17 Valid fields on written records

@req write-entry-fields=v1
@cites {
    rfc/3339,
    conformance#{conforming-program=v1},
    ontology#{ledger-entry=v1, object-kind=v1},
    text#{code-span=v1},
    #{entry-field=v1},
}

A conforming program must write (as a statement in `.sinter/` or as an
observation on the log branch) only records whose canonical objects meet
their row of `ontology#object-kind`, including the required string
member `by`, and in which any member `ts` that the object carries has
the RFC 3339 form of `entry-field`.

### 5.18 Recording agent writers

@req record-agent-writers=v1
@cites {
    conformance#{conforming-program=v1, input=v1},
    ontology#{statement=v1, agent=v1},
    text#{code-span=v1},
    #{entry-field=v1, entry-writer=v1, agent-marker=v1},
}

In an execution whose input says that an agent runs the execution
(`agent-marker`), a conforming program must write a statement only when
its object carries the member `agent` (so that `entry-writer` records
that agent).

### 5.19 Statements that agents may write

@req limit-agents-to-definitions=v1
@cites {
    conformance#{conforming-program=v1, input=v1, safety-obligation=v1},
    ontology#{
        agent=v1, judgment=v1, void-statement=v1, job-record=v1,
        log-branch=v1,
    },
    #{agent-marker=v1},
}

In an execution whose input says that an agent runs the execution
(`agent-marker`), a conforming program must write no judgment, no void,
and no observation, and must write nothing to the log branch.

### 5.20 Observations and kept objects only by the job

@req leave-delivered-entries-to-job=v1
@cites {
    conformance#{conforming-program=v1, input=v1, safety-obligation=v1},
    ontology#{job=v1, job-record=v1, log-branch=v1, agent=v1},
    #{job-marker=v1, agent-marker=v1},
}

A conforming program must append an observation (`delivered` or
`progress`) or a kept object to the log branch only in an execution
whose input says that the execution is the job (`job-marker`) and does
not say that an agent runs the execution (`agent-marker`).

### 5.21 No data from trackers

@req keep-tracker-data-out=v1
@cites {
    conformance#{conforming-program=v1, safety-obligation=v1},
    ontology#{external-item=v1, statement=v1, job-record=v1},
    identifiers#{external-id=v1},
}

A conforming program must write no statement in `.sinter/` and append no
observation to the log branch that holds data, other than an external
id, that the program took from a service that holds external items, such
as the title or the state of an issue. Git objects that a host adapter
reads from a host are not data of a tracker.

### 5.22 Transport safety in log-branch transfers

@req limit-programs-in-log-transfers=v1
@cites {
    conformance#{conforming-program=v1, safety-obligation=v1},
    ontology#{log-branch=v1},
    changes#{run-no-configured-programs=v1, remote-transfer=v1},
    #{log-branch-ref=v1},
}

In each fetch of the log branch from a remote log-branch repository and
each push of the log branch to a remote log-branch repository, a
conforming program must run none of the programs and commands that
`changes#run-no-configured-programs` forbids in a fetch from or push to
that remote.

### 5.23 No ledger write after a stop at a limit

@req change-no-ledger-after-stop=v1
@cites {
    conformance#{
        conforming-program=v1, safety-obligation=v1, own-limit=v1,
    },
    ontology#{statement=v1, job-record=v1, log-branch=v1},
}

When a conforming program reaches a limit of its own in a run, that
conforming program must write no further statement in `.sinter/`, must
append no further observation or kept object, and must make no further
update of the log branch in that run.

### 5.24 No ledger write after a read error

@req write-no-log-after-read-error=v1
@cites {
    conformance#{
        conforming-program=v1, safety-obligation=v1, input=v1,
    },
    ontology#{statement=v1, job-record=v1, log-branch=v1},
}

In a run in which content of a file, a folder, or a git object is a part
that an input lacks under `conformance#input` because a conforming
program could not take that content, that conforming program must write
no statement in `.sinter/`, must append no observation or kept object,
and must make no update of the log branch.

## 6. Conformance

A program, or a part of a program, conforms to this design when it is a
[conforming program](sinter:conformance#conforming-program=v1) of this
design.

The conformance vectors of this design are in the file
[`ledger.test-vectors.jsonl`](ledger.test-vectors.jsonl), in the same
folder as this design. The vectors are in four groups — `ledgers`,
`histories`, `store-entries`, and `store-checks` — and each group has a
schema below that gives the forms of the group
(`data-forms#group-form-list`). No group of this design uses a need, so
the forms of each group give no need names. These requirements have no
vectors: `give-states-only-from-valid-ledgers`,
`report-missing-log-branch`, `report-missing-ledger-objects`,
`report-uncommitted-statements`, `append-only-to-valid-ledgers`,
`append-entries-at-end`, `append-only-accepted-entries`,
`write-entry-fields`, `record-agent-writers`,
`limit-agents-to-definitions`, `leave-delivered-entries-to-job`,
`keep-tracker-data-out`, `limit-programs-in-log-transfers`,
`change-no-ledger-after-stop`, and `write-no-log-after-read-error`.

Each requirement from which vectors follow applies only when a program
gives the thing that the requirement names. The vector file is a
test-vector set in the form of
[`data-forms#test-vectors`](sinter:data-forms#test-vectors=v1), and by
`data-forms#vector-meaning` each vector line states one vector of this
design.

### 6.1 Log branches

@schema ledger-vector=v1
@cites {
    rfc/8259,
    conformance#{conforming-program=v1, input=v1},
    changes#{commit=v1, ref-commit=v1, commit-file=v1},
    data-forms#{
        json-value=v1, canonical-byte-sequence=v1, hex-text=v1,
        vector-line=v1, group-form-list=v1, vector-meaning=v1,
    },
    ontology#{object=v1, content-id=v1, job-record=v1, log-branch=v1},
    text#{
        result=v1, text=v1, character=v1, byte-sequence=v1,
        utf-8-encoding=v1, sequence=v1, code-point-order=v1,
        code-span=v1,
    },
    #{
        give-stored-ledgers=v1, validate-ledgers=v1, log-branch-ref=v1,
        ledger-object=v1, ledger-validity=v1, stored-ledger=v1,
        chunk=v1, log-branch-line=v1, needed-log-identity=v1,
    },
}

The group `ledgers` holds the vectors of the requirements
`give-stored-ledgers` and `validate-ledgers`. Each vector gives the
remote-tracking ref of the log branch of a git repository, whether the
log branch is valid, broken, newer, or missing, and (when valid) the
stored observations, kept objects, and unclosed kept-object pairs. The
input of each vector stands for a git repository that holds its ledger
objects and its history objects and is read in an undisturbed repository
read (and whose log branch, when valid, is assumed intact for
`give-stored-ledgers`).

- `input`: a JSON object. When the remote-tracking ref of the log branch
  exists, the member `ref` is a JSON object with one member: `entries`
  (the git tree object of the log-branch commit) when the ref has a
  commit, or `other` (the name of the non-commit git object, a text)
  when it resolves to a non-commit. When the log branch is missing (no
  mapped ref or ref does not exist), `input` has no member `ref`.
- `result`: when the log branch is not missing, `"valid"`, `"broken"`,
  or `"newer"`. When the log branch is missing, the vector has no member
  `result`.
- `values`: when the log branch is valid, a JSON object with three
  members: `observations` (the envelope ids of the stored observations,
  as a sequence in increasing order of `seq`), `kept` (the envelope ids
  of the kept objects, sorted in code point order), and `unclosed` (a
  JSON array of `{"missing":<identity-id>,"object":<kept-id>}` objects
  for each unclosed `(kept-object, identity-id)` pair under
  `needed-log-identity`, sorted in code point order of `object` and then
  `missing`). When the log branch is missing, broken, or newer, `{}`.

When `result` is present and a conforming program gives a result for
whether the log branch is valid, it gives the result that `result`
holds, once, and no other result; when `result` is absent, it gives no
result. When it gives the observations and kept objects of the log
branch, it gives those named by `observations` (in order) and `kept`,
once each and no others, and gives none when `values` is `{}`. The
member `unclosed` states no obligation in this group; the group
`histories` holds the vectors of the closure reports of the check
"Growth of the log branch".

Inside `input`, `result`, and `values`, a text is a JSON string; a byte
sequence is a JSON string when it is valid UTF-8, or
`{"bytes":"<hex-text>"}` otherwise; a git tree object is a JSON array of
entry objects holding `name` (byte sequence), `mode` (octal text such as
`"100644"` or `"40000"`), `entries` (for tree entries), and optionally
`content` (byte sequence) or `lines` (JSON array of envelope JSON
objects serialized as canonical byte sequences each followed by `0x0A`)
for regular-file entries; and a sequence is a JSON array in order.

```
{"form":"#ledger-vector=v1","group":"ledgers","input":{"ref":{"entries":[{"entries":[{"entries":[{"lines":[{"id":"progress:f457e35a60af035247dce0814e5ebe1c","object":{"by":"ci-bot","head":"1111111111111111111111111111111111111111","kind":"progress","seq":1,"ts":"2026-10-31T14:05:09Z","v":1}}],"mode":"100644","name":"f457e35a60af035247dce0814e5ebe1c.jsonl"}],"mode":"40000","name":"f4"}],"mode":"40000","name":"entries"}]}},"note":"one chunk with one progress observation","result":"valid","values":{"kept":[],"observations":["progress:f457e35a60af035247dce0814e5ebe1c"],"unclosed":[]}}
```

### 6.2 Histories of the log branch

@schema history-vector=v1
@cites {
    rfc/8259,
    conformance#{conforming-program=v1, input=v1},
    changes#{commit=v1, commit-file=v1, ancestry=v1, reflog-commit=v1},
    data-forms#{
        json-value=v1, vector-line=v1, group-form-list=v1,
        vector-meaning=v1,
    },
    text#{
        result=v1, text=v1, byte-sequence=v1, sequence=v1,
        code-point-order=v1, code-span=v1,
    },
    #{
        ledger-vector=v1, validate-histories=v1, log-branch-ref=v1,
        ledger-object=v1, ledger-validity=v1, intact-history=v1,
        needed-log-identity=v1,
    },
}

The group `histories` holds the vectors of the requirement
`validate-histories`. Each vector gives the log-branch commit, its
reachable commits, optional reflog commits of the remote-tracking ref,
whether the history is intact, and (when intact) any unclosed kept
objects on the tip. Each vector stands for a git repository whose log
branch is not missing, that holds its history objects, and that is read
in an undisturbed repository read.

Inside `input`, `result`, and `values`, texts, byte sequences, git tree
objects, and sequences use the forms of `ledger-vector`.

- `input`: a JSON object with `commit` (the log-branch commit name, a
  text), `commits` (a JSON object mapping each commit name to
  `{"entries":<git tree object>,"parents":<sequence of commit names>}`),
  and optional `reflog` (a sequence of reflog commit names of the
  remote-tracking ref, defaulting to `[]` when absent).
- `result`: `"valid"` when the history is intact, `"invalid"` when it is
  not intact, and absent when the tip commit's tree is newer.
- `values`: when `result` is `"valid"`, `{"unclosed":[...]}` in the form
  of `ledger-vector` (each pair that receives a `conformance#report`
  from "Growth of the log branch"); when the tip commit's tree is newer,
  `{}`; when `result` is `"invalid"`, absent.

When `result` is present and a conforming program gives a result for
whether the history is intact, it gives `result`, once, and no other
result; when `result` is absent, it gives neither result. When `result`
is `"valid"` and it checks growth of the log branch, it gives one
`conformance#report` for each entry of `unclosed` and no other closure
report.

```
{"form":"#history-vector=v1","group":"histories","input":{"commit":"a","commits":{"a":{"entries":[{"entries":[{"entries":[{"lines":[{"id":"progress:f457e35a60af035247dce0814e5ebe1c","object":{"by":"ci-bot","head":"1111111111111111111111111111111111111111","kind":"progress","seq":1,"ts":"2026-10-31T14:05:09Z","v":1}}],"mode":"100644","name":"f457e35a60af035247dce0814e5ebe1c.jsonl"}],"mode":"40000","name":"f4"}],"mode":"40000","name":"entries"}],"parents":[]}},"reflog":["a"]},"note":"one root commit with matching reflog commit","result":"valid","values":{"unclosed":[]}}
```

### 6.3 Git entries at or inside `.sinter/`

@schema store-entry-vector=v1
@cites {
    rfc/8259,
    conformance#{conforming-program=v1, input=v1},
    changes#{commit=v1, commit-file=v1},
    data-forms#{
        json-value=v1, hex-text=v1, vector-line=v1,
        group-form-list=v1, vector-meaning=v1,
    },
    findings#{finding-part=v1},
    text#{text=v1, byte-sequence=v1, code-point-order=v1, code-span=v1},
    #{
        ledger-vector=v1, invalid-store-entry-finding=v1,
        give-store-entry-findings=v1,
    },
}

The group `store-entries` holds the vectors of the requirement
`give-store-entry-findings`. Each vector gives the git tree object of a
commit and the `invalid-store-entry` findings that the commit has.
Inside `input` and `values`, texts, byte sequences, and git tree objects
use the forms of `ledger-vector`.

- `input`: a JSON object with one member, `entries`, the git tree object
  of the checked commit.
- `result`: no question; no vector of the group has the member `result`.
- `values`: a JSON object with one member, `findings`, a JSON array of
  `{"class":"invalid-store-entry","subject":<text>}` objects sorted in
  code point order of `subject`.

When a conforming program gives the `invalid-store-entry` findings of
that commit, it gives once each finding in `findings` (each with no
spot, no mark, no fix, and not ackable), and no other finding of that
class.

```
{"form":"#store-entry-vector=v1","group":"store-entries","input":{"entries":[{"entries":[{"mode":"120000","name":"bad-link"}],"mode":"40000","name":".sinter"}]},"note":"symbolic link inside .sinter/ is reported","values":{"findings":[{"class":"invalid-store-entry","subject":".sinter/bad-link"}]}}
```

### 6.4 Checks of `.sinter/` stores and statements

@schema store-check-vector=v1
@cites {
    rfc/8259,
    conformance#{conforming-program=v1, input=v1},
    files#{path=v1},
    data-forms#{
        json-value=v1, hex-text=v1, vector-line=v1,
        group-form-list=v1, vector-meaning=v1,
    },
    ontology#{tree=v1, object=v1, content-id=v1, finding-class=v1},
    findings#{finding-part=v1, spot=v1},
    text#{text=v1, byte-sequence=v1, code-point-order=v1, code-span=v1},
    #{
        ledger-vector=v1,
        altered-store-file-finding=v1,
        withdrawn-store-file-finding=v1,
        agent-writer-finding=v1,
        unaccepted-statement-finding=v1,
        non-latest-target-finding=v1,
        give-only-added-findings=v1,
        give-withdrawn-file-findings=v1,
        give-agent-writer-findings=v1,
        give-void-acceptance-findings=v1,
        give-latest-target-findings=v1,
    },
}

The group `store-checks` holds the vectors of the requirements
`give-only-added-findings`, `give-withdrawn-file-findings`,
`give-agent-writer-findings`, `give-void-acceptance-findings`, and
`give-latest-target-findings`. Each vector gives a base tree `B`, a head
tree `H`, and optionally the canonical objects held on a valid, intact
log branch (with no list of persons bound, and every non-void statement
assumed accepted by its own design's acceptance rule when its cross-object
rules hold), and gives the findings of the five classes
`altered-store-file`, `withdrawn-store-file`, `agent-writer`,
`unaccepted-statement` (for `void` statements), and `non-latest-target`.

Inside `input`, a tree is a JSON object mapping each valid path to its
content byte sequence in the byte-sequence form of `ledger-vector`.

- `input`: a JSON object with `base` (the base tree `B`), `head` (the
  head tree `H`), and optional `log` (a JSON object mapping each content
  id on the log branch to its canonical JSON object, defaulting to `{}`
  when absent).
- `result`: no question; no vector of the group has the member `result`.
- `values`: a JSON object with one member, `findings`, a JSON array of
  finding objects sorted in code point order of `class` and then
  `subject`. Each element has `class` (one of the five slugs),
  `subject` (string), and optional `spot` (`{"path":<valid path>}` when
  the finding has a spot, absent when it has no spot).

When a conforming program runs any of those five checks on `(B, H)` (with
those log-branch objects), it gives once each finding of that class in
`findings` (each with no mark, no fix, and not ackable), and no other
finding of that class.

```
{"form":"#store-check-vector=v1","group":"store-checks","input":{"base":{".sinter/0f/0f17c8dd86ac60f052972d0be8ace0c2.json":"{\"kind\":\"name\",\"name\":\"billing#cap\",\"v\":1}"},"head":{}},"note":"deleting an unneeded computed identity file in a valid store is allowed","values":{"findings":[]}}
```
