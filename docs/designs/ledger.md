<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Ledger
@design ledger=v1
@cites {
    conformance=v1, text=v1, identifiers=v1, files=v1, data-forms=v1,
    ontology=v1, findings=v1, object-store=v1, changes=v1,
    rfc/3339, rfc/5234, rfc/7405, gitdoc/git-config,
}
The ledger of a repository pairs statements in `.sinter/` with job
observations and kept objects on a dedicated log branch, and conforming
programs validate the log branch and its append-only history, run store
and statement checks, and meet record-writing and safety obligations.

Programs read the log branch through the remote-tracking ref of a
configured remote and validate its tree layout and append-only commit
history against git's reflog. Statements in `.sinter/` carry common
record fields and include voids that withdraw objects in `.sinter/` or
on the log branch. Store and statement checks inspect git tree entries
under `.sinter/`, compare store files against a base tree, check record
writers, void acceptance, and latest targets, and return a notice for
uncommitted store files in a working tree.

When a program writes statements or updates the log branch, process
environment markers distinguish agent executions from job executions.
Safety obligations keep tracker data out of records, forbid configured
programs during log-branch transfers, and stop writes after a
resource-limit stop or a read error. What a conforming program returns
while another process changes an input repository or working tree is a
matter of quality of implementation; safety obligations still hold.

## The log branch

@spec log-branch=v1

The log branch of a repository is a dedicated append-only git branch
holding job observations and kept copies of merged declared items and
their referenced computed identity objects in chunks of canonical JSON
envelope lines. A program reads the log branch through the
remote-tracking ref of a configured remote, and validates its tree
layout and its append-only commit history against git's reflog.
Together with the statements stored in `.sinter/` of a tree, a valid,
intact log branch supplies the repository's stored ledger.

### Parameters

#### Ledger remote

@schema ledger-remote=v1
@cites {ontology#{log-branch=v1, parameter=v1}, text#text=v1}

The `parameter` `ledger-remote` names the git remote through which a
program reads and transfers the `log-branch`. A binding of
`ledger-remote` meets `ledger-remote` when the binding is a `text`,
such as `origin`. Otherwise, the binding is invalid.

#### Log-branch name

@schema log-branch-name=v1
@cites {
    ontology#{log-branch=v1, parameter=v1},
    changes#branch-name=v1,
    text#text=v1,
}

The `parameter` `log-branch-name` names the `log-branch` of a
repository. A binding of `log-branch-name` is a `text`. A binding meets
`log-branch-name` when the binding is a `branch-name`, such as
`sinter-log`. Otherwise, the binding is invalid.

### Definitions

#### Log-branch ref

@term log-branch-ref=v1
@cites {
    gitdoc/git-config,
    conformance#input=v1,
    ontology#{log-branch=v1, parameter=v1},
    changes#{
        branch-name=v1, commit=v1, mapped-ref=v1, ref-commit=v1,
        ref-name=v1, remote-transfer=v1,
    },
    text#text=v1,
    #{ledger-remote=v1, log-branch-name=v1},
}

Under a valid binding `b` (a `branch-name`) of the `parameter`
`log-branch-name` and a valid binding `r` (a `text`) of the `parameter`
`ledger-remote`:

- The **remote ref name of the log branch** is the `ref-name`
  `refs/heads/` followed by `b`.
- The **remote-tracking ref of the log branch** of a git repository is
  the `mapped-ref` of `refs/heads/` followed by `b` for remote `r` in
  that git repository, when `refs/heads/` followed by `b` has a mapped
  ref for `r`. Otherwise, the git repository has no remote-tracking ref
  of the log branch.
- The **log-branch commit** of a git repository is the `commit` of its
  remote-tracking ref of the log branch (`ref-commit`), when that git
  repository has a remote-tracking ref of the log branch and that ref
  has a commit.
- The `log-branch` of a git repository is **missing** when the git
  repository has no remote-tracking ref of the log branch, or when that
  remote-tracking ref does not exist (`ref-commit`). A missing log
  branch is a part that a valid git repository can lack under
  `conformance#input`, and is never a valid empty log branch.
- The **remote log-branch repository** of a git repository for a fetch
  is the git repository at the address of remote `r` for a fetch
  (`git-config`, `remote-transfer`); for a push, it is each git
  repository at an address of remote `r` for a push.

#### Chunk path

@term chunk-path=v1
@cites {
    rfc/5234, rfc/7405,
    text#{hex-digit=v1, production=v1, text=v1},
}

A **chunk path** is a `text` that matches the `production` `chunk-path`
and whose two characters matched by `2hex-digit` after `entries/` equal
the first two characters matched by `32hex-digit` after the second `/`:

```abnf
chunk-path  = %s"entries/" 2hex-digit "/" 32hex-digit %s".jsonl"
```

#### Chunk

@term chunk=v1
@cites {
    changes#commit-file=v1,
    text#{byte-sequence=v1, utf-8-encoding=v1},
    #chunk-path=v1,
}

A **chunk** of a git tree object is a regular-file entry among the
entries of that git tree object (`commit-file`) whose byte path is the
`utf-8-encoding` of a `chunk-path`. The **chunk path** of the chunk is
that chunk path. The **content** of a chunk is the content
(`byte-sequence`) of the blob that the chunk names.

The **lines of a chunk** are the byte sequences produced by splitting
its content right after each byte `0x0A`, omitting any trailing empty
byte sequence after a final `0x0A`. Each line of a chunk other than the
last ends with `0x0A` and holds no other `0x0A`; an empty content has
zero lines. The **lines of a git tree object** are the lines of its
chunks. A line counts once for each occurrence in a chunk, so identical
byte sequences in two chunks, or twice in one chunk, are two lines.

#### Log-branch line

@schema log-branch-line=v1
@cites {
    data-forms#{
        canonical-byte-sequence=v1, json-value=v1, line-object=v1,
    },
    ontology#{
        content-id=v1, log-branch=v1, object=v1, object-kind=v1,
    },
    text#byte-sequence=v1,
}

A `byte-sequence` meets `log-branch-line` (is a **valid log-branch
line**) when all four of these conditions hold:

1. It ends with the byte `0x0A`, and the `byte-sequence` before that
   final `0x0A` is the `canonical-byte-sequence` of a `json-value`
   object holding exactly two members: `id`, whose value is a string,
   and `object`, whose value is a `line-object`.
2. That `line-object` meets its row of `ontology#object-kind`.
3. The value of the member `kind` of that `line-object` is an object
   kind that `ontology#object-kind` marks as `yes` in its `on log
   branch` column (`log-branch`).
4. The value of `id` equals the `content-id` of that canonical `object`.

For a valid log-branch line, its **envelope ID** is the value of its
member `id`, and its **canonical object** is the `line-object` held by
its member `object`.

@example This
[canonical byte sequence](sinter:data-forms#canonical-byte-sequence=v1)
followed by `0x0A` meets `log-branch-line`, holding a `progress`
[observation](sinter:ontology#observation=v1) whose
[content ID](sinter:ontology#content-id=v1) matches `id` and whose
`kind` is allowed on the log branch under
[object-kind](sinter:ontology#object-kind=v1):

```json
{"id":"progress:f457e35a60af035247dce0814e5ebe1c","object":{"by":"ci-bot","head":"1111111111111111111111111111111111111111","kind":"progress","seq":1,"ts":"2026-10-31T14:05:09Z","v":1}}
```

Omitting the trailing `0x0A`, placing `object` before `id`, adding an
extra member to the envelope, or holding a kind marked `no` in the
`on log branch` column of [object-kind](sinter:ontology#object-kind=v1)
(such as `"task"`) fails `log-branch-line`.

#### Ledger objects

@term ledger-object=v1
@cites {
    changes#{commit=v1, commit-file=v1, reach=v1, ref-commit=v1},
    #{chunk=v1, log-branch-ref=v1},
}

For a `commit` `c` whose git tree object is `t`, the **ledger objects**
of `c` are `c`, `t`, each git tree object that a tree entry among the
entries of `t` (`commit-file`) names, and each blob that a `chunk` of
`t` names.

For a git repository whose remote-tracking ref of the log branch exists
(`log-branch-ref`, `ref-commit`), the **ledger objects** of that git
repository are: when that ref resolves to a git object, that git
object; and when that git object is a `commit`, the ledger objects of
that commit. The **history objects** of that git repository are its
ledger objects and, when that ref has a log-branch commit `c`, the
ledger objects of each commit that `c` reaches (`reach`).

A git repository does not hold the ledger objects of a commit when any
of those git objects is absent (`commit`), when a tree entry among the
entries of its git tree object names a git object that is not a git
tree object, or when a chunk of its git tree object names a git object
that is not a blob. A git repository does not hold its ledger objects
when its remote-tracking ref resolves to a git object that is absent or
when that git object is a commit whose ledger objects the git
repository does not hold. A git repository does not hold its history
objects when it does not hold its ledger objects, when any commit
reached by its log-branch commit names a parent commit that the git
repository does not hold, or when it does not hold the ledger objects
of any commit reached by its log-branch commit.

#### Valid log-branch tree

@schema valid-ledger-tree=v1
@cites {
    changes#commit-file=v1,
    data-forms#{
        canonical-byte-sequence=v1, decoded-json=v1, hash-id=v1,
        id-prefix=v1, json-value=v1,
    },
    ontology#{content-hash=v1, observation=v1},
    text#{byte-sequence=v1, character=v1, utf-8-encoding=v1},
    #{chunk=v1, chunk-path=v1, log-branch-line=v1},
}

A line of a `chunk` is a **newer line** when all three of these
conditions hold:

1. It ends with the byte `0x0A`, and the `byte-sequence` before that
   final `0x0A` has a `decoded-json` value that is a `json-value`
   object holding a member `id` whose value is a string and a member
   `object` whose value is a `json-value` object `o`.
2. `o` holds a member `v` whose value is an integer greater than `1`,
   and a member `kind` whose value is a string `k` such that `k`
   followed by `:` is an `id-prefix`.
3. The value of `id` equals the `hash-id` of the
   `canonical-byte-sequence` of `o` with ID prefix `k:` and length `32`.

A git tree object is **newer** when at least one of its lines (`chunk`)
is a newer line. A git tree object that is not newer meets
`valid-ledger-tree` (is a **valid log-branch tree**) when all five of
these conditions hold:

1. Its entries at any depth (`commit-file`) are exactly these, with no
   two entries sharing a byte path:
   - its `chunk`s, each with mode `100644`;
   - for each chunk, the tree entry whose byte path is the
     `utf-8-encoding` of the first 10 `character`s of that chunk's
     `chunk-path`; and
   - when the git tree object has at least one chunk, the tree entry
     whose byte path is the `utf-8-encoding` of `entries`.
2. Each chunk has at least one line, and every line of every chunk
   meets `log-branch-line`.
3. For each chunk, the 32 hex digits matched by `32hex-digit` in its
   `chunk-path` equal the first 32 hex digits of the `content-hash` of
   the canonical object of the first line of that chunk.
4. No two lines of the git tree object have the same envelope ID.
5. For the number `m` of lines of the git tree object whose canonical
   object is an `observation` (`kind` equal to `"delivered"` or
   `"progress"`), the `seq` values of those `m` canonical objects are
   the integers from `1` to `m`, each once.

#### Needed log-branch identity

@term needed-log-identity=v1
@cites {
    conformance#{dependence=v1, design=v1, input=v1, own-store=v1},
    ontology#{
        computed-identity=v1, content-id=v1, declared-item=v1, edge=v1,
        log-branch=v1, object=v1,
    },
    object-store#tree-object-store=v1,
    #{log-branch-line=v1, valid-ledger-tree=v1},
}

Let `O` be the canonical `object` of a valid `log-branch-line`, and let
`c` be a `content-id` whose object kind word is a `computed-identity`
kind (`name`, `pin`, `ext`, `vector-set`, or `vector-group`).

`O` **holds the key of `c` itself** when `O` is a `declared-item`
object and `c` is the content ID of the `name` computed identity object
whose member `name` equals the member `name` of `O`.

`O` **needs the computed identity object `c`** when `O` holds at least
one `edge` in its member `edges` whose member `to` equals `c`, and `O`
does not hold the key of `c` itself.

On a `valid-ledger-tree` `t`, a canonical object `O` of a line of `t`
is **unclosed for `c`** when `O` needs `c` and no line of `t` has
envelope ID `c`. An unclosed kept object does not make `t` invalid.
Such an absent computed identity object is a part that a valid
`log-branch` can lack under `conformance#input`: when no valid input of
a run (neither the log branch, nor a declared-item object holding its
own `name` key, nor any valid encoding input, nor a valid `own-store`)
provides that computed identity object or its key (as
`tree-object-store` defines "provides" and "provides the key"), that
computed identity object is a missing part of the run, and a thing that
a requirement (`design`) obliges needs (`dependence`) that missing part
when that thing needs its key. When another valid input of the run
provides that computed identity object or its key, the run does not
lack that part.

@example Suppose a [valid log-branch tree](sinter:#valid-ledger-tree=v1)
holds a kept `req` [declared item](sinter:ontology#declared-item=v1)
line with envelope ID `req:e24c49b7d08a4e9545fb0fccc8743761`,
`"name":"billing#cap"`, an `about` [edge](sinter:ontology#edge=v1) to
`name:0f17c8dd86ac60f052972d0be8ace0c2` (`billing#cap`), and a `cites`
edge to `name:5bf08b8c6eb65e796933fb330e48a007` (`billing#fee`). The
`req` object holds its own `name` key (`billing#cap`), so it needs no
line for `name:0f17c8dd86ac60f052972d0be8ace0c2`. It needs
`name:5bf08b8c6eb65e796933fb330e48a007`. If the tree also holds a
[log-branch line](sinter:#log-branch-line=v1) with envelope ID
`name:5bf08b8c6eb65e796933fb330e48a007` for the
[computed identity](sinter:ontology#computed-identity=v1) object
`{"kind":"name","name":"billing#fee","v":1}`, the `req` object is not
unclosed for `name:5bf08b8c6eb65e796933fb330e48a007`; if that `name`
line is absent, the `req` object is unclosed for
`name:5bf08b8c6eb65e796933fb330e48a007` while the tree remains valid.

#### Log-branch validity

@atom ledger-validity=v1
@cites {
    changes#{commit=v1, ref-commit=v1},
    #{ledger-object=v1, log-branch-ref=v1, valid-ledger-tree=v1},
}

For a git repository whose log branch is not missing (`log-branch-ref`)
and that holds its ledger objects (`ledger-object`), the log branch has
one of three validity outcomes:

- **`"newer"`:** the remote-tracking ref of the log branch has a
  `commit` (`ref-commit`) whose git tree object is newer
  (`valid-ledger-tree`).
- **`"valid"`:** the remote-tracking ref of the log branch has a
  `commit` whose git tree object meets `valid-ledger-tree`.
- **`"broken"`:** the log branch is neither `"newer"` nor `"valid"`
  (its remote-tracking ref exists and has no commit, or the git tree
  object of its log-branch commit is neither newer nor a valid
  log-branch tree).

A log branch is **newer**, **valid**, or **broken** when its validity
outcome is `"newer"`, `"valid"`, or `"broken"`.

#### Stored ledger

@term stored-ledger=v1
@cites {
    conformance#own-store=v1,
    ontology#{
        computed-identity=v1, declared-item=v1, ledger=v1,
        log-branch=v1, object=v1, observation=v1, statement=v1,
        tree=v1,
    },
    object-store#tree-object-store=v1,
    #{
        chunk=v1, ledger-object=v1, ledger-validity=v1,
        log-branch-line=v1, log-branch-ref=v1, valid-ledger-tree=v1,
    },
}

For a `tree` `T` whose `tree-object-store` is valid, the **stored
statements** of `T` are the set of all canonical `object`s of the
`statement` kinds that the object store of `T` holds.

For a `valid-ledger-tree` `t`:

- The **stored observations** of `t` are the canonical objects of the
  lines (`chunk`, `log-branch-line`) of `t` whose `kind` is an
  `observation` kind (`"delivered"` or `"progress"`), in increasing
  order of `seq`.
- The **kept objects** of `t` are the set of canonical objects of the
  lines of `t` whose `kind` is a `declared-item` kind or a
  `computed-identity` kind.

For a git repository that holds its ledger objects (`ledger-object`)
and whose `log-branch` is not missing (`log-branch-ref`) and is valid
(`ledger-validity`), its **stored observations** and **kept objects**
are those of the git tree object of its log-branch commit. Together
with the stored statements of a `tree` (or the same canonical objects
from a valid `own-store`), they form the **stored ledger** for that
tree and git repository (`ontology#ledger`).

#### Ledger extension

@term ledger-extension=v1
@cites {changes#commit=v1, #chunk=v1}

**Extension** is the smallest relation between `commit`s in which each
commit `d` extends `d`, and a commit `d` extends a commit `c` when `d`
has exactly one parent, that parent extends `c`, and every line
(`chunk`) of the git tree object of that parent is a line of the git
tree object of `d`.

#### Intact histories

@atom intact-history=v1
@cites {
    changes#{commit=v1, reach=v1, ref-commit=v1, reflog-commit=v1},
    #{
        ledger-extension=v1, ledger-object=v1, log-branch-ref=v1,
        valid-ledger-tree=v1,
    },
}

For a git repository whose log branch is not missing (`log-branch-ref`),
whose log-branch commit's git tree object is not newer
(`valid-ledger-tree`) when its remote-tracking ref has a commit, and
that holds its history objects (`ledger-object`), the history of the
log branch is **intact** when all three of these conditions hold:

1. Its remote-tracking ref `R` of the log branch has a `commit` `c`
   (`ref-commit`), and `c` extends (`ledger-extension`) a commit that
   has no parent.
2. The git tree object of every commit that `c` reaches (`reach`) meets
   `valid-ledger-tree`.
3. `c` reaches every `reflog-commit` of `R`.

When `R` exists and has no commit, the history of the log branch is not
intact. For a git repository whose log branch is not missing, is not
newer, and holds its history objects, the history-validity outcome is
`"valid"` when the history is intact and `"invalid"` when the history
is not intact.

### Returning stored ledgers

@req give-stored-ledgers=v1
@cites {
    conformance#{conforming-program=v1, dependence=v1},
    ontology#{log-branch=v1, observation=v1, statement=v1, tree=v1},
    changes#{repository-read=v1, undisturbed-read=v1},
    object-store#tree-object-store=v1,
    #{
        intact-history=v1, ledger-object=v1, ledger-validity=v1,
        log-branch-ref=v1, stored-ledger=v1,
    },
}

When returning the stored statements (`stored-ledger`) of a `tree` `T`,
a conforming program must return each stored statement of `T` once,
with no extra `statement`, when the `tree-object-store` of `T` is
valid, and must return no stored statement of `T` when the
`tree-object-store` of `T` is invalid.

When returning the stored observations or kept objects (`stored-ledger`)
of the `log-branch` of a git repository in an undisturbed
`repository-read` (`undisturbed-read`), a conforming program must
return each stored `observation` (in increasing order of `seq` when
ordered) and each kept object once, with no extra observation or kept
object, when the log branch is not missing (`log-branch-ref`), the git
repository holds its ledger objects and history objects
(`ledger-object`), the log branch is valid (`ledger-validity`), and its
history is intact (`intact-history`). The program must return no
observation and no kept object when the log branch is missing, broken,
newer, or not intact, or when the git repository does not hold its
ledger objects or history objects.

A conforming program must return no result that depends (`dependence`)
on observations or kept objects of the log branch of a git repository
in an undisturbed `repository-read` when the log branch is missing,
broken, newer, or not intact, or when the git repository does not hold
its ledger objects or history objects. A conforming program must return
no result that depends on the stored statements of a `tree` when the
`tree-object-store` of that tree is invalid.

### Validating log branches

@req validate-ledgers=v1
@cites {
    conformance#conforming-program=v1,
    changes#{repository-read=v1, undisturbed-read=v1},
    #{ledger-object=v1, ledger-validity=v1, log-branch-ref=v1},
}

When validating the log branch of a git repository in an undisturbed
`repository-read` (`undisturbed-read`), and the log branch is not
missing (`log-branch-ref`) and the git repository holds its ledger
objects (`ledger-object`), a conforming program must return the
validity outcome of `ledger-validity` (`"valid"`, `"broken"`, or
`"newer"`), once, with no other result. The program must return no
validity result when the log branch is missing or when the git
repository does not hold its ledger objects.

### Validating log-branch histories

@req validate-histories=v1
@cites {
    conformance#{
        conforming-program=v1, report=v1, report-missing-parts=v1,
    },
    changes#{repository-read=v1, undisturbed-read=v1},
    #{
        intact-history=v1, ledger-object=v1, ledger-validity=v1,
        log-branch-ref=v1, needed-log-identity=v1, stored-ledger=v1,
    },
}

When validating whether the history of the log branch of a git
repository is intact in an undisturbed `repository-read`
(`undisturbed-read`), and the log branch is not missing
(`log-branch-ref`), the git repository holds its history objects
(`ledger-object`), and the log branch is not newer (`ledger-validity`),
a conforming program must return the history-validity outcome of
`intact-history` (`"valid"` when intact, `"invalid"` when not intact),
once, with no other result. The program must return neither result when
the log branch is missing, when the log branch is newer, or when the
git repository does not hold its history objects.

When validating whether the history of the log branch is intact, and
the log branch is valid and its history is intact, for each pair of a
kept object `O` (`stored-ledger`) of the log-branch commit and a
computed identity content ID `c` such that `O` is unclosed for `c`
(`needed-log-identity`), a conforming program must return one
`conformance#report` identifying `O` and `c`, and must return no such
report when `O` is not unclosed for `c`. When no valid input of the run
provides that computed identity object or its key, that report is the
report of this design for that missing part under
`report-missing-parts`.

### Reporting a missing log branch

@req report-missing-log-branch=v1
@cites {
    conformance#{
        conforming-program=v1, report=v1, report-missing-parts=v1,
    },
    changes#{repository-read=v1, undisturbed-read=v1},
    #log-branch-ref=v1,
}

When running an operation on a git repository in an undisturbed
`repository-read` (`undisturbed-read`) that needs the log branch of
that git repository, and the log branch is missing (`log-branch-ref`),
a conforming program must return one `conformance#report` stating that
the log branch is missing, as the report for that missing part under
`report-missing-parts`, and must return no such report when the log
branch is not missing.

### Fetching no ref during reads

@req fetch-no-ref-in-reads=v1
@cites {
    conformance#{conforming-program=v1, safety-obligation=v1},
    ontology#{job=v1, log-branch=v1},
    changes#{remote-transfer=v1, repository-read=v1},
}

In a read operation—any check other than a `job` run updating the
`log-branch`—a conforming program must fetch no ref (`remote-transfer`)
and must call no host, except for an object-only fetch of git objects
that a partial clone leaves out as part of a `repository-read`.

### Reporting missing ledger objects

@req report-missing-ledger-objects=v1
@cites {
    conformance#{
        conforming-program=v1, report=v1, report-missing-parts=v1,
    },
    changes#{repository-read=v1, undisturbed-read=v1},
    #{ledger-object=v1, log-branch-ref=v1},
}

When running an operation on a git repository in an undisturbed
`repository-read` (`undisturbed-read`) that needs the ledger objects
(`ledger-object`) of the log branch, the log branch is not missing
(`log-branch-ref`), and the git repository does not hold its ledger
objects after any object-only fetch permitted as part of that
`repository-read`, a conforming program must return one
`conformance#report` stating that the git repository does not hold its
ledger objects, as the report for that missing part under
`report-missing-parts`, and must return no such report when the git
repository holds them.

When running an operation on a git repository in an undisturbed
`repository-read` that needs the history objects (`ledger-object`) of
the log branch, the log branch is not missing, and the git repository
does not hold its history objects after any object-only fetch permitted
as part of that `repository-read`, a conforming program must return one
`conformance#report` stating that the git repository does not hold its
history objects, as the report for that missing part under
`report-missing-parts`, and must return no such report when the git
repository holds them.

### Test vectors

Test vectors for `log-branch` live in
[ledger.test-vectors.jsonl](ledger.test-vectors.jsonl) as a test-vector
set under [test-vectors](sinter:data-forms#test-vectors=v1). Neither
group uses `needs`.

#### Log-branch vectors

@schema ledger-vector=v1
@cites {
    changes#{
        commit=v1, commit-file=v1, ref-commit=v1, repository-read=v1,
        undisturbed-read=v1,
    },
    data-forms#{
        canonical-byte-sequence=v1, group-schema=v1, hex-text=v1,
        json-value=v1, vector-line=v1, vector-meaning=v1,
    },
    text#{byte-sequence=v1, code-point-order=v1, valid-utf-8=v1},
    #{
        give-stored-ledgers=v1, intact-history=v1, ledger-object=v1,
        ledger-validity=v1, log-branch-line=v1, log-branch-ref=v1,
        needed-log-identity=v1, stored-ledger=v1, validate-ledgers=v1,
    },
}

`ledger-vector` is a `group-schema` for group `ledgers` and tests
`give-stored-ledgers` and `validate-ledgers`. Each line is a
`vector-line` whose meaning follows `vector-meaning`. Each vector
stands for an undisturbed `repository-read` (`undisturbed-read`) of a
git repository holding its ledger objects and history objects
(`ledger-object`), whose log branch (when valid) is intact
(`intact-history`) for `give-stored-ledgers`.

| field | type | meaning |
|---|---|---|
| `input.ref` | object (optional) | present when the remote-tracking ref of the log branch exists (`log-branch-ref`, `ref-commit`), holding either `entries` or `other`; absent (`input` is `{}`) when the log branch is missing |
| `input.ref.entries[]` | array of objects (optional) | git tree object entries (`commit-file`) of the log-branch `commit`, each holding `name` (`byte-sequence`: UTF-8 string, or `{"bytes": <hex-text>}` when not `valid-utf-8`), `mode` (octal mode string such as `"100644"` or `"40000"`), `entries` (nested entries in the same form on `"40000"` tree entries), and optionally `content` (`byte-sequence` in the same form) or `lines` (array of `json-value` objects, each serialized as its `canonical-byte-sequence` followed by `0x0A`) on regular-file entries (empty content when both are absent) |
| `input.ref.other` | string (optional) | short name of the non-commit git object to which the remote-tracking ref resolves |
| `result` | string (optional) | `"valid"`, `"broken"`, or `"newer"` (`ledger-validity`) when the log branch is not missing; absent when the log branch is missing (no validity result returned under `validate-ledgers`) |
| `values.observations` | array of strings (optional) | envelope IDs (`log-branch-line`) of the stored observations (`stored-ledger`) in increasing order of `seq` when `result` is `"valid"`; absent (`values` is `{}`) otherwise (no observation returned under `give-stored-ledgers`) |
| `values.kept` | array of strings (optional) | envelope IDs (`log-branch-line`) of the kept objects (`stored-ledger`) in `code-point-order` when `result` is `"valid"`; absent (`values` is `{}`) otherwise (no kept object returned) |
| `values.unclosed[]` | array of objects (optional) | `{"missing": <identity-id>, "object": <kept-id>}` pairs for each unclosed pair under `needed-log-identity`, sorted in `code-point-order` of `object` then `missing`, when `result` is `"valid"`; absent (`values` is `{}`) otherwise. This member states no obligation in this group. |

@example Sample lines testing
[validate-ledgers](sinter:#validate-ledgers=v1) and
[give-stored-ledgers](sinter:#give-stored-ledgers=v1) on a valid
[log-branch line](sinter:#log-branch-line=v1) and on a newer
[log-branch tree](sinter:#valid-ledger-tree=v1)
([ledger-validity](sinter:#ledger-validity=v1)):

```json
{"form":"#ledger-vector=v1","group":"ledgers","input":{"ref":{"entries":[{"entries":[{"entries":[{"lines":[{"id":"progress:f457e35a60af035247dce0814e5ebe1c","object":{"by":"ci-bot","head":"1111111111111111111111111111111111111111","kind":"progress","seq":1,"ts":"2026-10-31T14:05:09Z","v":1}}],"mode":"100644","name":"f457e35a60af035247dce0814e5ebe1c.jsonl"}],"mode":"40000","name":"f4"}],"mode":"40000","name":"entries"}]}},"note":"one chunk with one progress observation","result":"valid","values":{"kept":[],"observations":["progress:f457e35a60af035247dce0814e5ebe1c"],"unclosed":[]}}
{"form":"#ledger-vector=v1","group":"ledgers","input":{"ref":{"entries":[{"entries":[{"entries":[{"lines":[{"id":"progress:f457e35a60af035247dce0814e5ebe1c","object":{"by":"ci-bot","head":"1111111111111111111111111111111111111111","kind":"progress","seq":1,"ts":"2026-10-31T14:05:09Z","v":1}},{"id":"progress:0c83cf12bd7463d917f1feb1c0483947","object":{"by":"ci-bot","head":"1111111111111111111111111111111111111111","kind":"progress","seq":2,"v":2}}],"mode":"100644","name":"f457e35a60af035247dce0814e5ebe1c.jsonl"}],"mode":"40000","name":"f4"}],"mode":"40000","name":"entries"}]}},"note":"v2 line with matching id makes log branch newer","result":"newer","values":{}}
```

#### Log-branch histories vectors

@schema history-vector=v1
@cites {
    conformance#report=v1,
    changes#{
        commit=v1, commit-file=v1, reflog-commit=v1,
        repository-read=v1, undisturbed-read=v1,
    },
    data-forms#{
        canonical-byte-sequence=v1, group-schema=v1, hex-text=v1,
        json-value=v1, vector-line=v1, vector-meaning=v1,
    },
    text#{byte-sequence=v1, code-point-order=v1, valid-utf-8=v1},
    #{
        intact-history=v1, ledger-object=v1, log-branch-ref=v1,
        needed-log-identity=v1, valid-ledger-tree=v1,
        validate-histories=v1,
    },
}

`history-vector` is a `group-schema` for group `histories` and tests
`validate-histories`. Each line is a `vector-line` whose meaning
follows `vector-meaning`. Each vector stands for an undisturbed
`repository-read` (`undisturbed-read`) of a git repository holding its
history objects (`ledger-object`), whose remote-tracking ref of the log
branch exists and has a log-branch commit (`log-branch-ref`).

| field | type | meaning |
|---|---|---|
| `input.commit` | string | short commit name of the log-branch commit (`log-branch-ref`) |
| `input.commits` | object | map from each short commit name to `{"entries": <entries>, "parents": <parents>}` (`commit`) |
| `input.commits.<name>.entries[]` | array of objects | git tree object entries (`commit-file`) of that commit, each holding `name` (`byte-sequence`: UTF-8 string, or `{"bytes": <hex-text>}` when not `valid-utf-8`), `mode` (octal mode string such as `"100644"` or `"40000"`), `entries` (nested entries in the same form on `"40000"` tree entries), and optionally `content` (`byte-sequence` in the same form) or `lines` (array of `json-value` objects, each serialized as its `canonical-byte-sequence` followed by `0x0A`) on regular-file entries (empty content when both are absent) |
| `input.commits.<name>.parents[]` | array of strings | short commit names of that commit's parents in order (`[]` for a root commit) |
| `input.reflog` | array of strings (optional) | short commit names of the `reflog-commit`s of the remote-tracking ref (defaults to `[]` when absent) |
| `result` | string (optional) | `"valid"` when the history is intact (`intact-history`), `"invalid"` when not intact; absent when the log-branch commit's git tree object is newer (`valid-ledger-tree`, no result returned under `validate-histories`) |
| `values.unclosed[]` | array of objects (optional) | `{"missing": <identity-id>, "object": <kept-id>}` pairs sorted in `code-point-order` of `object` then `missing`, one for each closure `conformance#report` required under `validate-histories` and `needed-log-identity` when `result` is `"valid"`; absent (`values` is `{}`) when `result` is absent (newer tip tree); `values` itself is absent when `result` is `"invalid"` |

@example Sample lines testing
[validate-histories](sinter:#validate-histories=v1) under
[intact-history](sinter:#intact-history=v1) for a
[reflog commit](sinter:changes#reflog-commit=v1) rollback and for an
intact history with an unclosed kept object
([needed-log-identity](sinter:#needed-log-identity=v1)):

```json
{"form":"#history-vector=v1","group":"histories","input":{"commit":"a","commits":{"a":{"entries":[{"entries":[{"entries":[{"lines":[{"id":"progress:f457e35a60af035247dce0814e5ebe1c","object":{"by":"ci-bot","head":"1111111111111111111111111111111111111111","kind":"progress","seq":1,"ts":"2026-10-31T14:05:09Z","v":1}}],"mode":"100644","name":"f457e35a60af035247dce0814e5ebe1c.jsonl"}],"mode":"40000","name":"f4"}],"mode":"40000","name":"entries"}],"parents":[]},"b":{"entries":[{"entries":[{"entries":[{"lines":[{"id":"progress:f457e35a60af035247dce0814e5ebe1c","object":{"by":"ci-bot","head":"1111111111111111111111111111111111111111","kind":"progress","seq":1,"ts":"2026-10-31T14:05:09Z","v":1}},{"id":"progress:e30ec2bb80f974cd56606b113a2e8ac5","object":{"by":"ci-bot","head":"2222222222222222222222222222222222222222","kind":"progress","seq":2,"v":1}}],"mode":"100644","name":"f457e35a60af035247dce0814e5ebe1c.jsonl"}],"mode":"40000","name":"f4"}],"mode":"40000","name":"entries"}],"parents":["a"]}},"reflog":["b","a"]},"note":"tip rolled back before earlier reflog commit is invalid","result":"invalid"}
{"form":"#history-vector=v1","group":"histories","input":{"commit":"b","commits":{"a":{"entries":[{"entries":[{"entries":[{"lines":[{"id":"progress:f457e35a60af035247dce0814e5ebe1c","object":{"by":"ci-bot","head":"1111111111111111111111111111111111111111","kind":"progress","seq":1,"ts":"2026-10-31T14:05:09Z","v":1}}],"mode":"100644","name":"f457e35a60af035247dce0814e5ebe1c.jsonl"}],"mode":"40000","name":"f4"}],"mode":"40000","name":"entries"}],"parents":[]},"b":{"entries":[{"entries":[{"entries":[{"lines":[{"id":"progress:f457e35a60af035247dce0814e5ebe1c","object":{"by":"ci-bot","head":"1111111111111111111111111111111111111111","kind":"progress","seq":1,"ts":"2026-10-31T14:05:09Z","v":1}},{"id":"req:e24c49b7d08a4e9545fb0fccc8743761","object":{"edges":[{"kind":"about","to":"name:0f17c8dd86ac60f052972d0be8ace0c2"},{"kind":"cites","to":"name:5bf08b8c6eb65e796933fb330e48a007"}],"kind":"req","label":"v1","name":"billing#cap","text":"Limit amounts with fee.","v":1}}],"mode":"100644","name":"f457e35a60af035247dce0814e5ebe1c.jsonl"}],"mode":"40000","name":"f4"}],"mode":"40000","name":"entries"}],"parents":["a"]}},"reflog":["a","b"]},"note":"intact history with unclosed kept object stays valid and reports unclosed pair","result":"valid","values":{"unclosed":[{"missing":"name:5bf08b8c6eb65e796933fb330e48a007","object":"req:e24c49b7d08a4e9545fb0fccc8743761"}]}}
```

## Statements, voids, and store checks

@spec store-checks=v1

Statements live as content-addressed object files in `.sinter/` of a
tree. Common fields identify each record's kind, writer, timestamp, and
edges, and a void statement withdraws one withdrawable object in
`.sinter/` or on the log branch while carrying copies of its edges.
Store and statement checks inspect git tree entries under `.sinter/`,
compare store files against a base tree, check record writers, void
acceptance, latest targets, and conflicts, and return a notice for
uncommitted store files in a working tree.

### Definitions

#### Record field

@schema record-field=v1
@cites {
    rfc/3339,
    ontology#{
        record=v1, statement=v1, observation=v1, void-statement=v1,
        object-kind=v1, person=v1, agent=v1, job=v1, edge=v1,
    },
    data-forms#json-value=v1,
    text#text=v1,
}

A **field** of a `record` is a member of its canonical object
(`json-value`) that `ontology#object-kind` or another design names for
records of its kind. The **common fields** of records follow
`ontology#object-kind`:

| field | type | meaning |
|---|---|---|
| `kind` | string (required) | record kind word |
| `v` | integer (required) | integer `1` |
| `by` | string (required) | `person` who wrote the `statement`, `person` for whom the `agent` acts, or `job` |
| `agent` | string (optional on `statement`) | `agent` that wrote the statement; omitted on `observation`s |
| `seq` | integer `>= 1` (required on `observation`) | sequence number of the `observation` on the log branch; omitted on `statement`s |
| `ts` | string (optional) | time at which the record was written; its **RFC 3339 form** is a `text` matching the `date-time` rule of RFC 3339 with uppercase `T` and `Z`, time offset `Z`, and no fraction of a second, such as `2026-10-31T14:05:09Z` |
| `edges` | array of flat objects (optional) | set of `edge` objects as `ontology#object-kind` and `ontology#edge` define it; absent when empty and absent on `"progress"` |

Beyond the common fields, the fields of `"void"` (`void-statement`) are
`withdrawn-kind` (a required string matching the object kind word of the
target of its `withdraws` edge) and `reason` (a required string stating
the reason for the withdrawal). The fields of any other kind of record
are the members listed by its row of `ontology#object-kind` and defined
by the design that owns that kind.

#### Record writer

@term record-writer=v1
@cites {
    ontology#{record=v1, person=v1, agent=v1, job=v1},
    #record-field=v1,
}

When a `record` carries the field `agent` (`record-field`), **the writer
of the record** is the `agent` that its field `agent` names. When a
`record` carries no field `agent`, **the writer of the record** is the
`person` or `job` that its field `by` names.

#### Accepted record

@term accepted-record=v1
@cites {
    conformance#{design=v1, input=v1},
    ontology#{
        record=v1, statement=v1, observation=v1, void-statement=v1,
        object-withdrawal=v1, object-kind=v1, declared-item=v1,
        computed-identity=v1, content-id=v1, edge=v1, topic=v1,
        tree=v1,
    },
    object-store#tree-object-store=v1,
    #{
        log-branch-ref=v1, ledger-object=v1, ledger-validity=v1,
        intact-history=v1,
    },
}

The **acceptance rule** of a kind of `statement` or `observation` is the
condition, defined by a `design` for that kind, under which a `record`
of that kind is accepted in a `tree` (for a statement) or on the log
branch (for an observation). A record of a kind for which no design
defines an acceptance rule is not accepted.

The acceptance rule of the kind `"void"` (`void-statement`) is as
follows. For a `tree` `T` whose object store (`tree-object-store`) is
valid, let `V` be a `"void"` object in `T`, and let `U` be the set of
canonical objects held by the valid `input`s of the operation:

- the object store of `T`;
- the object store of any base tree `B` when a change is checked and the
  object store of `B` is valid; and
- the log branch when the git repository holds its `ledger-object`s and
  history objects, and the log branch is not missing (`log-branch-ref`),
  is `"valid"` (`ledger-validity`), and has an intact history
  (`intact-history`).

When the object store of `T` is invalid, no `"void"` is accepted in `T`
(an invalid object store yields no result over its objects and no
finding under this rule). `V` is accepted in `T` when, and only when,
all three of these conditions hold:

1. `V` meets its row of `ontology#object-kind`: its one `withdraws`
   `edge` names a `content-id` `w` of a withdrawable kind
   (`object-kind`), its `withdrawn-kind` equals the object kind word of
   `w`, and no edge of `V` targets a `computed-identity` kind.
2. Every `edge` of `V` other than its `withdraws` edge is permitted for
   `withdrawn-kind`: when `withdrawn-kind` is one of the seven
   `declared-item` kinds, every such edge has `kind` equal to `revises`
   and targets a declared-item kind; when `withdrawn-kind` is another
   withdrawable kind, every such edge has an edge kind and a
   non-identity target kind permitted by the row of `withdrawn-kind` in
   `ontology#object-kind`.
3. When `U` holds an object `X` whose `content-id` equals `w`, the set
   of edges of `V` other than its `withdraws` edge equals: for a
   `declared-item` kind, the set of `revises` edges of `X`; for any
   other withdrawable kind, the set of edges of `X` whose target is not
   of one of the five `computed-identity` kinds.

Whether a `"void"` counts in `T` (is a counting void in `T`), and its
effect on objects in `.sinter/`, kept objects on the log branch,
observations, replaced objects, and latest statements (including
withholding under an invalid binding of a list of persons), follow
`ontology#object-withdrawal`, `ontology#void-statement`, and
`ontology#topic`.

@example Suppose a valid
[object store](sinter:object-store#tree-object-store=v1) of base tree
`B` holds the `"approval"` object
`approval:eb7c19392daf9123c7fc2506385dc3e4`, whose
[edges](sinter:ontology#edge=v1) are `about` and `judges` both targeting
`req:f6259f147d032738f64394a0796087a3`. In a valid head tree `T`, a
`"void"` ([void-statement](sinter:ontology#void-statement=v1)) with
`withdrawn-kind` `"approval"` and `edges` holding those two copied edges
plus `withdraws` targeting `approval:eb7c19392daf9123c7fc2506385dc3e4`
satisfies all three conditions and is accepted in `T`:

```json
{"by":"Ada Lovelace <ada@example.com>","edges":[{"kind":"about","to":"req:f6259f147d032738f64394a0796087a3"},{"kind":"judges","to":"req:f6259f147d032738f64394a0796087a3"},{"kind":"withdraws","to":"approval:eb7c19392daf9123c7fc2506385dc3e4"}],"kind":"void","reason":"mistake","v":1,"withdrawn-kind":"approval"}
```

A `"void"` withdrawing that same approval with only the `withdraws` edge
omits the copied `about` and `judges` edges while `U` holds the
approval, so condition 3 fails and that `"void"` is not accepted in `T`.
When `U` does not hold the withdrawn approval, the `"void"` carrying
`about`, `judges`, and `withdraws` still satisfies condition 2 under
[object-kind](sinter:ontology#object-kind=v1) and is accepted in `T`.
For a withdrawn `"req"`, only its `revises` edges are copied, so its
`about` edge and its citation edges are omitted.

#### Base comparison

@term base-comparison=v1
@cites {
    conformance#input=v1,
    ontology#{tree=v1, default-branch=v1},
    changes#{
        commit=v1, commit-change=v1, change-base=v1, shallow-commit=v1,
        working-tree=v1, head-commit=v1,
    },
}

For a check that compares a head `tree` `H` with a base `tree` `B`:

- For a change on a branch, `H` is the checked tree of the change (such
  as the tree of a merge result `commit`, or a `working-tree`), and `h`
  is the commit of that tree (for a working tree, its `head-commit`).
  `B` is the tree of the base commit named by the caller or, when the
  caller names none, the tree of the `change-base` of `h` (the base of
  its `commit-change`).
- On the `default-branch`, for a head commit `h`, `H` is the tree of
  `h`, and `B` is the tree of the base commit named by the caller or,
  when the caller names none, the tree of the first parent of `h`, or
  the empty tree with zero files when `h` has no parent and is not a
  `shallow-commit`.

When the caller names no base commit, and either (for a change) the
working tree has no head commit or `h` has no `change-base`, or (on the
default branch) `h` is a `shallow-commit`, `B` is a part that the git
repository lacks under `conformance#input`, and each finding of a check
that compares `H` with `B` needs that part. The choice of `B` never
reads the log branch.

#### Invalid-store-entry finding

@atom invalid-store-entry-finding=v1
@cites {
    findings#{
        finding-part=v1, finding-subject=v1, path-finding-subject=v1,
        message=v1, location=v1, mark=v1, related-message=v1, fix=v1,
        ackable-finding=v1,
    },
    files#path=v1,
    changes#{commit=v1, commit-file=v1},
    data-forms#hex-text=v1,
    ontology#{finding-class=v1, tree=v1},
    text#{
        byte-sequence=v1, valid-utf-8=v1, utf-8-encoding=v1,
        utf-8-text=v1,
    },
}

For a `commit` `c` whose git tree object is `T`, an entry `E` among the
entries of `T` (`commit-file`), with byte path `bp` (`byte-sequence`),
lies **at `.sinter` or inside `.sinter/` and outside `.sinter/local/`**
when both of these conditions hold:

1. `bp` equals the `utf-8-encoding` of `.sinter`, or `bp` starts with
   the `utf-8-encoding` of `.sinter/`.
2. `bp` does not start with the `utf-8-encoding` of `.sinter/local/`.

`c` has one finding of the `finding-class` `invalid-store-entry` for
each entry `E` of `T` at `.sinter` or inside `.sinter/` and outside
`.sinter/local/` that meets at least one of these three conditions:

- `E` is a symbolic-link entry (mode `120000`);
- `E` is a submodule entry (mode `160000`); or
- the name of `E` is not `valid-utf-8`.

Each finding has the `tree` of `c`, finding class `invalid-store-entry`,
subject (`finding-subject`) equal to the `path-finding-subject` of the
`utf-8-text` of `bp` when `bp` is the `utf-8-encoding` of a valid `path`
and otherwise `bytes:` followed by the lowercase `hex-text` of `bp`, no
`location`, no `mark`, no `fix`, is not ackable (`ackable-finding`), a
`message` stating what is wrong, and any `related-message` values that
the program returns (`finding-part`).

#### Altered-store-file finding

@atom altered-store-file-finding=v1
@cites {
    findings#{
        finding-part=v1, finding-subject=v1, path-finding-subject=v1,
        message=v1, location=v1, mark=v1, related-message=v1, fix=v1,
        ackable-finding=v1,
    },
    files#path=v1,
    ontology#{
        finding-class=v1, tree=v1, object-withdrawal=v1,
        computed-identity=v1,
    },
    object-store#{
        store-file=v1, valid-object-file=v1, tree-object-store=v1,
        needed-identity-file=v1,
    },
    #base-comparison=v1,
}

For a base `tree` `B` and a head `tree` `H` (`base-comparison`), `H` has
one tree finding of the `finding-class` `altered-store-file` for each
`store-file` `F` of `B` (with valid `path` `p` and content `b`) such
that `H` does not hold a `store-file` at `p` with content `b`, except
when `H` holds no file at `p` and at least one of these two exceptions
holds:

1. Every `store-file` of `H` is a `valid-object-file`, and `F` is a
   `valid-object-file` whose canonical object is withdrawn by a counting
   void (`object-withdrawal`) in `H`.
2. Every `store-file` of `H` is a `valid-object-file`, `F` is a
   `valid-object-file` whose canonical object is a `computed-identity`
   object, and no canonical object of the `tree-object-store` of `H`
   needs the identity file of that computed identity object
   (`needed-identity-file`).

When `H` holds no file at `p`, every `store-file` of `H` is a
`valid-object-file`, `F` is a `valid-object-file`, exception 2 does not
hold, and whether a `"void"` in `H` naming `F`'s canonical object counts
is withheld under `ontology#object-withdrawal`, whether `H` has an
`altered-store-file` finding for `F` is withheld.

Each finding has tree `H`, finding class `altered-store-file`, subject
(`finding-subject`) equal to the `path-finding-subject` of `p`,
`location` equal to `p` alone (with no span) in `H` when `H` holds a
file at `p` and none when `H` holds no file at `p`, no `mark`, no `fix`,
is not ackable (`ackable-finding`), a `message` stating what is wrong,
and any `related-message` values that the program returns
(`finding-part`).

#### Withdrawn-store-file finding

@atom withdrawn-store-file-finding=v1
@cites {
    findings#{
        finding-part=v1, finding-subject=v1, path-finding-subject=v1,
        message=v1, location=v1, mark=v1, related-message=v1, fix=v1,
        ackable-finding=v1,
    },
    files#path=v1,
    ontology#{finding-class=v1, tree=v1, object-withdrawal=v1},
    object-store#{
        store-file=v1, valid-object-file=v1, tree-object-store=v1,
    },
    #base-comparison=v1,
}

For a base `tree` `B` and a head `tree` `H` (`base-comparison`) whose
`tree-object-store` is valid, `H` has one tree finding of the
`finding-class` `withdrawn-store-file` for each `valid-object-file` `F`
of `H` (with valid `path` `p` and content `b`) such that `B` does not
hold a `store-file` at `p` with content `b` and the canonical object of
`F` is withdrawn by a counting void (`object-withdrawal`) in `H`. When
whether a `"void"` in `H` naming `F`'s canonical object counts is
withheld under `ontology#object-withdrawal`, whether `H` has a
`withdrawn-store-file` finding for `F` is withheld.

Each finding has tree `H`, finding class `withdrawn-store-file`, subject
(`finding-subject`) equal to the `path-finding-subject` of `p`,
`location` equal to `p` alone (with no span) in `H`, no `mark`, no
`fix`, is not ackable (`ackable-finding`), a `message` stating what is
wrong, and any `related-message` values that the program returns
(`finding-part`).

#### Agent-writer finding

@atom agent-writer-finding=v1
@cites {
    conformance#own-store=v1,
    findings#{
        finding-part=v1, finding-subject=v1, message=v1, location=v1,
        mark=v1, related-message=v1, fix=v1, ackable-finding=v1,
    },
    ontology#{
        finding-class=v1, tree=v1, judgment=v1, void-statement=v1,
        agent=v1, content-id=v1,
    },
    object-store#{object-path=v1, tree-object-store=v1},
    #{stored-ledger=v1, record-writer=v1},
}

A `tree` `T` whose `tree-object-store` is valid has one tree finding of
the `finding-class` `agent-writer` for each stored statement `S`
(`stored-ledger`) of `T` that is a `judgment` or a `"void"`
(`void-statement`) and whose writer (`record-writer`) is an `agent`
(that is, `S` carries the field `agent`).

Each finding has tree `T`, finding class `agent-writer`, subject
(`finding-subject`) equal to the `content-id` of `S`, `location` equal
to the `object-path` of `S` alone (with no span) in `T` when read from
`.sinter/` and none when read from a program's own store (`own-store`),
no `mark`, no `fix`, is not ackable (`ackable-finding`), a `message`
stating what is wrong, and any `related-message` values that the program
returns (`finding-part`).

#### Unaccepted-statement finding

@atom unaccepted-statement-finding=v1
@cites {
    conformance#own-store=v1,
    findings#{
        finding-part=v1, finding-subject=v1, message=v1, location=v1,
        mark=v1, related-message=v1, fix=v1, ackable-finding=v1,
    },
    ontology#{
        finding-class=v1, tree=v1, statement=v1, void-statement=v1,
        topic=v1, object-kind=v1, content-id=v1,
    },
    object-store#{object-path=v1, tree-object-store=v1},
    #{stored-ledger=v1, accepted-record=v1},
}

A `tree` `T` whose `tree-object-store` is valid has one tree finding of
the `finding-class` `unaccepted-statement` for each stored `statement`
`S` (`stored-ledger`) of `T` that is not accepted in `T` under `topic`
(it fails a cross-object rule of `ontology#object-kind` or the
acceptance rule of its kind under `accepted-record`). For statements of
the kind `"void"` (`void-statement`), `accepted-record` defines the
acceptance rule.

Each finding has tree `T`, finding class `unaccepted-statement`, subject
(`finding-subject`) equal to the `content-id` of `S`, `location` equal
to the `object-path` of `S` alone (with no span) in `T` when read from
`.sinter/` and none when read from a program's own store (`own-store`),
no `mark`, no `fix`, is not ackable (`ackable-finding`), a `message`
stating what is wrong, and any `related-message` values that the program
returns (`finding-part`).

#### Non-latest-target finding

@atom non-latest-target-finding=v1
@cites {
    conformance#own-store=v1,
    findings#{
        finding-part=v1, finding-subject=v1, message=v1, location=v1,
        mark=v1, related-message=v1, fix=v1, ackable-finding=v1,
    },
    ontology#{
        finding-class=v1, tree=v1, statement=v1, void-statement=v1,
        judgment=v1, topic=v1, object-kind=v1, object-withdrawal=v1,
        edge=v1, content-id=v1, log-branch=v1,
    },
    object-store#{
        object-path=v1, store-file=v1, valid-object-file=v1,
        tree-object-store=v1,
    },
    text#{character=v1, text=v1},
    #{stored-ledger=v1, base-comparison=v1},
}

For a base `tree` `B` and a head `tree` `H` (`base-comparison`) whose
`tree-object-store` is valid, a stored statement `S` (`stored-ledger`)
of `H` is **new relative to `B`** when `B` does not hold a
`valid-object-file` whose canonical object has the `content-id` of `S`.

For a new stored statement `S` of `H` whose `kind` is not `"void"`
(`void-statement`) and that no counting void (`object-withdrawal`) in
`H` withdraws, let the **reduced tree `H_S`** be the tree `H` without
the `store-file`s whose canonical objects are `S` and every new stored
statement of `H` (relative to `B`) that replaces `S` (directly or
through a chain of `revises` `edge`s, including copied `revises` edges
of counting voids in `H` that are new relative to `B`).

For each new stored statement `S` of `H` whose `kind` is not `"void"`
and that no counting void in `H` withdraws, and each `content-id` `t`
that `S` names with a `revises` edge or (when `S` is a `"done"` or
`"abandoned"` `judgment`) with a `judges` edge, `H` has one tree finding
of the `finding-class` `non-latest-target` for the pair `(S, t)` when
`t` is not the content ID of a latest statement of its group (`topic`)
in `H_S`. In `H_S`, each cross-object rule of `ontology#object-kind`
reads only the objects of `H_S` (using the copied edges of a counting
void in `H_S` when `H_S` does not hold the target object, as
`ontology#topic` states), and reads neither `B` nor the `log-branch`.
When whether a `"void"` in `H` naming `S` counts, or whether `t` is a
latest statement in `H_S`, is withheld under an invalid binding of a
list of persons (`topic`, `object-withdrawal`), whether `H` has that
finding is withheld.

Each finding has tree `H`, finding class `non-latest-target`, subject
(`finding-subject`) equal to the `text` formed by the `content-id` of
`S`, then a space (`U+0020`, `character`), then `t`, `location` equal to
the `object-path` of `S` alone (with no span) in `H` when read from
`.sinter/` and none when read from a program's own store (`own-store`),
no `mark`, no `fix`, is not ackable (`ackable-finding`), a `message`
stating that the writer did not see a newer statement, and any
`related-message` values that the program returns (`finding-part`).

#### Statement-conflict finding

@atom statement-conflict-finding=v1
@cites {
    findings#{
        finding-part=v1, finding-subject=v1, message=v1, location=v1,
        mark=v1, related-message=v1, fix=v1, ackable-finding=v1,
    },
    ontology#{
        finding-class=v1, tree=v1, conflict=v1, topic=v1, content-id=v1,
        declared-item=v1, work-item=v1, work-item-definition=v1,
        definition-statement=v1, judgment=v1, observation=v1,
    },
    object-store#tree-object-store=v1,
    #stored-ledger=v1,
}

A `tree` `T` whose `tree-object-store` is valid has one tree finding of
the `finding-class` `statement-conflict` for each `conflict` that exists
in `T` (over `stored-ledger` records). When whether a conflict exists is
withheld under `ontology#conflict` or `ontology#topic`, whether `T` has
that finding is withheld.

Each finding has tree `T`, finding class `statement-conflict`, subject
(`finding-subject`) equal to the `content-id` of the conflicted unit —
for a conflict of `judgment`s of a `declared-item` object `O`, the
content ID of `O`; for a conflict of `definition-statement`s of a
`work-item` `W`, the content ID of `W`; and for a conflict of `"done"`
and `"abandoned"` judgments of a task definition `D`
(`work-item-definition`), or of a completing `"delivered"` `observation`
of `D` and one or more latest `"abandoned"` judgments of `D`, the
content ID of `D` — no `location`, no `mark`, no `fix`, is not ackable
(`ackable-finding`), a `message` stating what is in conflict, and any
`related-message` values that the program returns (`finding-part`).

### Returning store-entry findings

@req give-store-entry-findings=v1
@cites {
    conformance#conforming-program=v1,
    changes#{commit=v1, commit-file=v1},
    findings#finding-part=v1,
    #invalid-store-entry-finding=v1,
}

When a conforming program checks the git entries (`commit-file`) at
`.sinter` or inside `.sinter/` of a `commit` `c`, the program must
return each `invalid-store-entry-finding` (`finding-part`) that `c` has
once, and must return no other finding of that class.

### Returning store and statement check findings

@req give-store-check-findings=v1
@cites {
    conformance#{
        conforming-program=v1, reject-invalid-inputs=v1,
        report-missing-parts=v1,
    },
    ontology#{tree=v1, void-statement=v1},
    object-store#tree-object-store=v1,
    findings#finding-part=v1,
    #{
        accepted-record=v1, base-comparison=v1,
        altered-store-file-finding=v1, withdrawn-store-file-finding=v1,
        agent-writer-finding=v1, unaccepted-statement-finding=v1,
        non-latest-target-finding=v1,
    },
}

When a conforming program runs any of these five checks, the program
must return each finding (`finding-part`) that the bullet of that check
names once, and must return no other such finding:

- **Only added:** comparing a base `tree` `B` and a head `tree` `H`
  (`base-comparison`), each `altered-store-file-finding` that `H` has
  relative to `B`.
- **Withdrawn files:** comparing a base `tree` `B` and a head `tree` `H`
  (`base-comparison`) whose `tree-object-store` is valid, each
  `withdrawn-store-file-finding` that `H` has relative to `B`.
- **Writers for `agent`:** on a `tree` `T` whose `tree-object-store` is
  valid, each `agent-writer-finding` that `T` has.
- **Kind rules for `"void"`:** on a `tree` `T` whose `tree-object-store`
  is valid, for statements of the kind `"void"` (`void-statement`,
  `accepted-record`), each `unaccepted-statement-finding` that `T` has
  for a `"void"` statement, and no other finding of that class for a
  `"void"` statement.
- **Latest targets:** for a change comparing a base `tree` `B` and a
  head `tree` `H` (`base-comparison`) whose `tree-object-store` is
  valid, each `non-latest-target-finding` that `H` has relative to `B`.

For any check that compares a base tree `B` and a head tree `H`, when
`B` is a missing part under `base-comparison`, the program must withhold
each finding of that check (`report-missing-parts`). For any check that
requires a valid `tree-object-store`, when that object store is invalid,
the program must return no finding of that check
(`reject-invalid-inputs`). Whenever whether a tree has a finding of one
of these classes is withheld by that finding's definition, the program
must withhold that finding.

### Reporting uncommitted store files

@req report-uncommitted-statements=v1
@cites {
    conformance#conforming-program=v1,
    changes#{
        working-tree=v1, head-commit=v1, commit-file=v1,
        working-tree-file=v1, repository-read=v1, undisturbed-read=v1,
    },
    object-store#store-file=v1,
}

When a conforming program checks a `working-tree` of a git repository in
an undisturbed `repository-read` (`undisturbed-read`), and the tree of
the working tree (`working-tree-file`) holds at least one `store-file`
that is absent from or has content different from the tree of the
`head-commit` of that working tree (`commit-file`) — or the working tree
has no head commit and holds at least one store file — the program must
return one notice (in any form that identifies the fact) stating that it
read uncommitted store files. When every store file of the working tree
matches the tree of its head commit byte for byte, the program must
return no such notice.

### Test vectors

Test vectors for `store-checks` live in
[ledger.test-vectors.jsonl](ledger.test-vectors.jsonl) as a test-vector
set under [test-vectors](sinter:data-forms#test-vectors=v1). Neither
group uses `needs`, and neither group uses `result`.

#### Store-entry vectors

@schema store-entry-vector=v1
@cites {
    conformance#conforming-program=v1,
    changes#{commit=v1, commit-file=v1},
    data-forms#{
        json-value=v1, hex-text=v1, vector-line=v1, group-schema=v1,
        vector-meaning=v1,
    },
    findings#{finding-part=v1, finding-subject=v1},
    text#{
        byte-sequence=v1, valid-utf-8=v1, utf-8-encoding=v1,
        code-point-order=v1,
    },
    #{invalid-store-entry-finding=v1, give-store-entry-findings=v1},
}

`store-entry-vector` is a `group-schema` for group `store-entries` and
tests `give-store-entry-findings`. Each line is a `vector-line` whose
meaning follows `vector-meaning`.

| field | type | meaning |
|---|---|---|
| `input.entries[]` | array of objects | entries listed by the git tree object of the checked `commit` (`commit-file`) |
| `input.entries[].name` | string or `{"bytes": string}` | entry name `byte-sequence`: a JSON string when it is `valid-utf-8` (representing its `utf-8-encoding`), or `{"bytes": <hex-text>}` otherwise |
| `input.entries[].mode` | string | octal entry mode: `"40000"` for a tree entry, `"100644"`, `"100664"`, or `"100755"` for a regular-file entry, `"120000"` for a symbolic-link entry, or `"160000"` for a submodule entry |
| `input.entries[].entries` | array of objects (tree entries only) | nested entries of the named git tree object in the same form; present on `"40000"` entries and absent on other entries |
| `values.findings[]` | array of objects | all `invalid-store-entry-finding` findings of the commit, sorted in `code-point-order` of `subject` |
| `values.findings[].class` | string | `"invalid-store-entry"` |
| `values.findings[].subject` | string | `finding-subject` text |

Each `json-value` object in `input` and `values` holds only the members
listed in this table, and each `{"bytes": <hex-text>}` object holds only
`bytes`. When a `conforming-program` returns the `invalid-store-entry`
findings of that commit, it returns each finding in `values.findings`
once (each with no location, no mark, no fix, and not ackable under
`finding-part`), and no other finding of that class.

@example Sample lines testing
[give-store-entry-findings](sinter:#give-store-entry-findings=v1) and
[invalid-store-entry-finding](sinter:#invalid-store-entry-finding=v1)
for a symbolic link and a non-UTF-8 entry name encoded as
[hex-text](sinter:data-forms#hex-text=v1)
([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#store-entry-vector=v1","group":"store-entries","input":{"entries":[{"entries":[{"mode":"120000","name":"bad-link"}],"mode":"40000","name":".sinter"}]},"note":"symbolic link inside .sinter/ is reported","values":{"findings":[{"class":"invalid-store-entry","subject":".sinter/bad-link"}]}}
{"form":"#store-entry-vector=v1","group":"store-entries","input":{"entries":[{"entries":[{"mode":"100644","name":{"bytes":"ff"}}],"mode":"40000","name":".sinter"}]},"note":"non-UTF-8 entry name inside .sinter/ uses bytes:<hex> subject","values":{"findings":[{"class":"invalid-store-entry","subject":"bytes:2e73696e7465722fff"}]}}
```

#### Store-check vectors

@schema store-check-vector=v1
@cites {
    conformance#conforming-program=v1,
    files#path=v1,
    data-forms#{
        json-value=v1, line-object=v1, hex-text=v1, vector-line=v1,
        group-schema=v1, vector-meaning=v1,
    },
    ontology#{
        tree=v1, object=v1, content-id=v1, finding-class=v1,
        statement=v1,
    },
    findings#{finding-part=v1, finding-subject=v1, location=v1},
    text#{
        byte-sequence=v1, valid-utf-8=v1, utf-8-encoding=v1,
        code-point-order=v1,
    },
    #{
        altered-store-file-finding=v1, withdrawn-store-file-finding=v1,
        agent-writer-finding=v1, unaccepted-statement-finding=v1,
        non-latest-target-finding=v1, give-store-check-findings=v1,
    },
}

`store-check-vector` is a `group-schema` for group `store-checks` and
tests `give-store-check-findings`. Each line is a `vector-line` whose
meaning follows `vector-meaning`. Each vector provides a base `tree`
`B`, a head `tree` `H`, and optionally the canonical `object`s held on a
valid, intact log branch, with no list of persons bound and every
non-void `statement` assumed accepted by its own design's acceptance
rule when its cross-object rules hold.

| field | type | meaning |
|---|---|---|
| `input.base` | object | base `tree` `B`, mapping each valid `path` to its content `byte-sequence` (a JSON string representing its `utf-8-encoding` when `valid-utf-8`, or `{"bytes": <hex-text>}` otherwise) |
| `input.head` | object | head `tree` `H`, in the same path-to-content map form as `input.base` |
| `input.log` | object (optional) | canonical `object`s (`line-object`) held on a valid, intact log branch, keyed by `content-id`; defaults to `{}` when absent |
| `values.findings[]` | array of objects | all findings of the five checked classes (`altered-store-file-finding`, `withdrawn-store-file-finding`, `agent-writer-finding`, `unaccepted-statement-finding` for `"void"`, and `non-latest-target-finding`), sorted in `code-point-order` of `class` then `subject` |
| `values.findings[].class` | string | `finding-class`: `"altered-store-file"`, `"withdrawn-store-file"`, `"agent-writer"`, `"unaccepted-statement"`, or `"non-latest-target"` |
| `values.findings[].subject` | string | `finding-subject` text |
| `values.findings[].location.path` | string (optional) | present when the finding has a `location` (`values.findings[].location` is `{"path": <valid path>}`, a location with no span); `location` is absent when the finding has no location |

Each `json-value` object in `input` and `values` holds only the members
listed in this table, and each `{"bytes": <hex-text>}` object holds only
`bytes`. When a `conforming-program` runs any of the five checks of
`give-store-check-findings` on `(B, H)` with those log-branch objects,
it returns each finding of that class in `values.findings` once (each
with no mark, no fix, and not ackable under `finding-part`), and no
other finding of that class (for `unaccepted-statement`, no other
finding for a `"void"` statement).

@example Sample lines testing
[give-store-check-findings](sinter:#give-store-check-findings=v1) for
[altered-store-file-finding](sinter:#altered-store-file-finding=v1)
(allowed deletion of an unneeded computed identity file) and
[agent-writer-finding](sinter:#agent-writer-finding=v1) with a
[location](sinter:findings#location=v1)
([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#store-check-vector=v1","group":"store-checks","input":{"base":{".sinter/0f/0f17c8dd86ac60f052972d0be8ace0c2.json":"{\"kind\":\"name\",\"name\":\"billing#cap\",\"v\":1}"},"head":{}},"note":"deleting an unneeded computed identity file in a valid store is allowed","values":{"findings":[]}}
{"form":"#store-check-vector=v1","group":"store-checks","input":{"base":{},"head":{".sinter/6d/6dd62beeaec48302f3f0db41ec8de0be.json":"{\"agent\":\"helper-bot\",\"by\":\"Ada Lovelace <ada@example.com>\",\"edges\":[{\"kind\":\"about\",\"to\":\"req:f6259f147d032738f64394a0796087a3\"},{\"kind\":\"judges\",\"to\":\"req:f6259f147d032738f64394a0796087a3\"}],\"kind\":\"approval\",\"v\":1}"}},"note":"approval carrying agent is reported by agent-writer","values":{"findings":[{"class":"agent-writer","location":{"path":".sinter/6d/6dd62beeaec48302f3f0db41ec8de0be.json"},"subject":"approval:6dd62beeaec48302f3f0db41ec8de0be"}]}}
```

## Writing statements and updating the log branch

@spec writing=v1

Writing to the ledger of a repository adds canonical statement files to
`.sinter/` and appends new observations and kept objects to the log
branch through commits that extend the tip and fast-forward pushes.
Process environment markers distinguish agent executions from job
executions. Safety boundaries protect the ledger from tracker data,
untrusted transfer commands, and further writes after a resource-limit
stop or a read error.

### Parameters

#### Agent markers

@schema agent-markers=v1
@cites {ontology#parameter=v1, text#text=v1}

A binding of the `parameter` `agent-markers` is a finite set of `text`s.

#### Job markers

@schema job-markers=v1
@cites {ontology#parameter=v1, text#text=v1}

A binding of the `parameter` `job-markers` is a finite set of `text`s.

### Definitions

#### Agent marker

@term agent-marker=v1
@cites {
    conformance#input=v1,
    ontology#{parameter=v1, agent=v1},
    text#text=v1,
    #agent-markers=v1,
}

Under a binding of the `parameter` `agent-markers`, an **agent marker**
of a process is an environment variable of that process whose name is a
`text` of that binding, regardless of the value of that variable. An
execution of a program is an **agent execution** (its `input` states
that an `agent` runs the execution) when, and only when, the
environment of a process of that execution holds an agent marker.

#### Job marker

@term job-marker=v1
@cites {
    conformance#input=v1,
    ontology#{parameter=v1, job=v1},
    text#text=v1,
    #job-markers=v1,
}

Under a binding of the `parameter` `job-markers`, a **job marker** of a
process is an environment variable of that process whose name is a
`text` of that binding, regardless of the value of that variable. An
execution of a program is a **job execution** (its `input` states that
the execution is the `job`) when, and only when, the environment of a
process of that execution holds a job marker.

### Restricting log-branch updates to the job and valid ledgers

@req append-only-to-valid-ledgers=v1
@cites {
    conformance#{conforming-program=v1, safety-obligation=v1},
    ontology#{log-branch=v1, observation=v1},
    #{
        log-branch-ref=v1, ledger-object=v1, ledger-validity=v1,
        intact-history=v1, job-marker=v1, agent-marker=v1,
    },
}

A conforming program must create or update the `log-branch` (including
appending an `observation` or a kept object) only in a job execution
(`job-marker`) that is not an agent execution (`agent-marker`). When
the log branch already exists on a remote log-branch repository
(`log-branch-ref`), a conforming program must update or append to the
log branch only when the git repository of the run holds its ledger
objects and history objects (`ledger-object`), the log branch is valid
(`ledger-validity`), and its history is intact (`intact-history`).

### Appending to and pushing the log branch

@req append-to-log-branch=v1
@cites {
    conformance#{conforming-program=v1, report=v1},
    ontology#{
        log-branch=v1, job=v1, observation=v1, declared-item=v1,
        computed-identity=v1, content-id=v1,
    },
    changes#{commit=v1, reach=v1, remote-transfer=v1},
    #{
        log-branch-ref=v1, chunk=v1, log-branch-line=v1,
        valid-ledger-tree=v1, needed-log-identity=v1,
        ledger-validity=v1, ledger-extension=v1, intact-history=v1,
    },
}

When a conforming program creates or updates the `log-branch` in a run
of the `job`, the program must meet these conditions:

1. When creating the log branch (no commit exists on the remote), the
   new `commit` `d` extends (`ledger-extension`) a commit with no
   parent. When updating an existing tip commit `c`, `d` extends `c`.
   Every commit that `d` reaches (`reach`) and that `c` does not reach
   (or every commit that `d` reaches when creating) has a valid
   log-branch tree (`valid-ledger-tree`).
2. The lines (`chunk`) of the git tree object of `d` consist of:
   - every line of `c`, when `c` exists;
   - one valid log-branch line (`log-branch-line`) for each new
     `observation` (`"delivered"` or `"progress"`), with `seq` values
     `m + 1`, `m + 2`, and so on, where `m` is the number of
     observations in `c` (or `0` when creating); and
   - one valid log-branch line, deduplicated by envelope ID and
     carrying no `seq` and no `by`, for each kept `declared-item`
     object and each `computed-identity` object that it needs
     (`needed-log-identity`) whose `content-id` is not already an
     envelope ID of a line of `c`.
3. When pushing `d` (`remote-transfer`) to the remote ref name of the
   log branch at each remote log-branch repository for a push
   (`log-branch-ref`), the program must push only as a plain
   fast-forward, never changing the remote ref from an existing `commit`
   `r` to a commit that does not extend `r`.
4. When a remote refuses the push of `d` as not a fast-forward (the
   remote ref names a `commit` that `d` does not extend), the program
   must either:
   - fetch the log branch from the remote again, check that the fetched
     tip is valid (`ledger-validity`) and intact (`intact-history`),
     drop each observation already recorded and each kept object whose
     `content-id` the fetched tip already holds, assign the remaining
     observations the next values of `seq` (and matching content IDs),
     build a new commit extending the fetched tip, and push again; or
   - stop after a number of refusals of its own choice, return one
     `report` stating that it stopped, and write nothing more.

### Writing only accepted records

@req write-only-accepted-records=v1
@cites {
    rfc/3339,
    conformance#{conforming-program=v1, input=v1},
    ontology#{
        tree=v1, object-kind=v1, record=v1, statement=v1,
        void-statement=v1, observation=v1, log-branch=v1,
    },
    #{record-field=v1, accepted-record=v1},
}

A conforming program must write a `record` (as a `statement` in
`.sinter/` or as an `observation` on the `log-branch`) only when its
canonical object meets its row of `object-kind`, including the required
string member `by`, and any member `ts` that the object carries has the
RFC 3339 form of `record-field` (`rfc/3339`).

A conforming program must write a `statement` to `.sinter/` only when
that statement is accepted in the `tree` (`accepted-record`), and for a
`void-statement` only when the `input`s hold the withdrawable object
that its `withdraws` edge names. A conforming program must append an
`observation` to the `log-branch` only when that observation is accepted
by the acceptance rule of its kind (`accepted-record`).

### Writing the agent field

@req write-agent-field=v1
@cites {
    conformance#conforming-program=v1,
    ontology#{statement=v1, agent=v1},
    #{record-field=v1, record-writer=v1, agent-marker=v1},
}

In an agent execution (`agent-marker`), a conforming program must write
a `statement` only when its canonical object carries the member `agent`
(`record-field`) naming the `agent` that runs the execution, making
that agent the writer of the record (`record-writer`).

### Limiting agents to definition statements

@req limit-agents-to-definitions=v1
@cites {
    conformance#{conforming-program=v1, safety-obligation=v1},
    ontology#{
        judgment=v1, void-statement=v1, observation=v1, log-branch=v1,
    },
    #agent-marker=v1,
}

In an agent execution (`agent-marker`), a conforming program must never
write a `judgment`, a `void-statement`, or an `observation`, and must
never write anything to the `log-branch`.

### Keeping tracker data out of the ledger

@req keep-tracker-data-out=v1
@cites {
    conformance#{conforming-program=v1, safety-obligation=v1},
    identifiers#external-id=v1,
    ontology#{
        external-item=v1, statement=v1, observation=v1, log-branch=v1,
    },
}

A conforming program must never write a `statement` in `.sinter/`, or
append an `observation` to the `log-branch`, that holds data read from
a service that holds `external-item`s (such as the title or the status
of an issue), other than an `external-id` or data from git objects read
from a host.

### Limiting programs in log-branch transfers

@req limit-programs-in-log-transfers=v1
@cites {
    conformance#{conforming-program=v1, safety-obligation=v1},
    ontology#log-branch=v1,
    changes#{remote-transfer=v1, run-no-configured-programs=v1},
    #log-branch-ref=v1,
}

In each fetch (`remote-transfer`) of the `log-branch` from a remote
log-branch repository and each push of the log branch to a remote
log-branch repository (`log-branch-ref`), a conforming program must
never run any program or command that `run-no-configured-programs`
forbids in a fetch from or push to that remote.

### Making no ledger write after a resource-limit stop

@req change-no-ledger-after-stop=v1
@cites {
    conformance#{
        conforming-program=v1, safety-obligation=v1, resource-limit=v1,
    },
    ontology#{statement=v1, observation=v1, log-branch=v1},
}

When a conforming program reaches a `resource-limit` in a run, the
program must write no further `statement` in `.sinter/`, append no
further `observation` or kept object, and make no further update to the
`log-branch` in that run.

### Making no ledger write after a read error

@req write-no-log-after-read-error=v1
@cites {
    conformance#{
        conforming-program=v1, safety-obligation=v1, input=v1,
    },
    files#directory=v1,
    ontology#{statement=v1, observation=v1, log-branch=v1},
}

In a run in which content of a file, a `directory`, or a git object
that a conforming program could not read is a part that an `input`
lacks, the program must write no `statement` in `.sinter/`, append no
`observation` or kept object, and make no update to the `log-branch`.
