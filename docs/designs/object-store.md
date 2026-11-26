<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Object store
@design object-store=v1
@cites {
    conformance=v1, text=v1, files=v1, data-forms=v1, ontology=v1,
    findings=v1, rfc/5234, rfc/7405,
}
The `.sinter/` object store holds canonical Sinter objects as content-addressed JSON files in a tree, and conforming programs validate and read store files, report invalid store files and absent needed identity files, write object files, and obey safety limits on writes and deletions in `.sinter/`.

Each stored Sinter object lives in one content-addressed file inside
the `.sinter/` directory of a tree, while files inside `.sinter/local/`
remain machine-local outside the object store. Reading a tree's object
store separates valid object files from newer or broken store files and
checks that referenced computed identity objects are present. What a
conforming program returns while another process modifies an input tree
or directory tree is a matter of quality of implementation.

## Definitions

### Object path

@term object-path=v1
@cites {
    rfc/5234, rfc/7405,
    text#{text=v1, production=v1, hex-digit=v1},
    files#path=v1,
    data-forms#hash=v1,
    ontology#{object=v1, content-hash=v1},
}

An **object path** is a `text` that matches the `production`
`object-path` and whose two characters matched by `2hex-digit` after
`.sinter/` equal the first two characters matched by `32hex-digit`
after the second `/`:

```abnf
object-path = %s".sinter/" 2hex-digit "/" 32hex-digit %s".json"
```

Every object path is a valid `path`. For a `hash` `h` (64 `hex-digit`
characters), the **object path** of `h` is `.sinter/`, then the first
two characters of `h`, then `/`, then the first 32 characters of `h`,
then `.json`. The **object path** of an `object` is the object path of
its `content-hash`.

@example The `name`
[computed identity](sinter:ontology#computed-identity=v1) object
`{"kind":"name","name":"billing#cap","v":1}` has
[content ID](sinter:ontology#content-id=v1)
`name:0f17c8dd86ac60f052972d0be8ace0c2` and object path
`.sinter/0f/0f17c8dd86ac60f052972d0be8ace0c2.json`. By contrast,
`.sinter/0f/req:0f17c8dd86ac60f052972d0be8ace0c2.json` is not an object
path because an object path carries no kind prefix.

### Store file

@term store-file=v1
@cites {
    files#{
        path=v1, directory-tree=v1, file-kind=v1, path-resolution=v1,
    },
    ontology#tree=v1,
}

A valid `path` is a **local path** (a path inside `.sinter/local/`)
when it has three or more path segments, path segment 1 is `.sinter`,
and path segment 2 is `local`. A valid `path` is a **store path** when
it has two or more path segments, path segment 1 is `.sinter`, and it
is not a local path.

A **local file** of a `tree` is a file of that tree whose valid path is
a local path. A **store file** of a `tree` is a file of that tree whose
valid path is a store path (a file of `.sinter/` of that tree under
`ontology#tree`).

In a `directory-tree`, an **existing store file** is a regular file
(`file-kind`) that the last path segment of a store path names in that
directory tree (`path-resolution`).

@example The three-segment [valid path](sinter:files#path=v1)
`.sinter/local/ev.json` is a local path, so a file there is a local
file outside the object store. By contrast, the two-segment valid path
`.sinter/local` is not a local path and is a store path, and the
one-segment valid path `.sinter` is neither a local path nor a store
path. The paths `.sinter/LOCAL/a.json` and `.sinter/local2/a.json` are
also store paths because path comparison is exact.

### Store object file

@schema store-object-file=v1
@cites {
    files#path=v1,
    text#byte-sequence=v1,
    data-forms#{
        canonical-byte-sequence=v1, line-object=v1, json-value=v1,
        hash=v1,
    },
    ontology#object-kind=v1,
    #{object-path=v1, store-file=v1},
}

A `store-file` (a valid `path` that is a store path, together with a
content `byte-sequence`) meets `store-object-file` (is a **store object
file**) when all four of these conditions hold:

1. Its valid path is an `object-path`.
2. Its content is the `canonical-byte-sequence` of a `line-object`
   (with no trailing line feed).
3. The object path of the `hash` of its content equals its valid path.
4. That `line-object` has no member `id`, has the member `v` whose
   value is the integer `1`, and has the member `kind` whose value is a
   string naming an object kind that `ontology#object-kind` marks as
   allowed in `.sinter/`.

The **line object** of a store object file is the unique `line-object`
whose `canonical-byte-sequence` is the content of that store object
file.

### Valid object file

@term valid-object-file=v1
@cites {
    ontology#{
        encoding=v1, object-kind=v1, object=v1, content-hash=v1,
        content-id=v1,
    },
    data-forms#{
        line-object=v1, json-value=v1, decoded-json=v1, hash=v1,
    },
    #{object-path=v1, store-file=v1, store-object-file=v1},
}

Every `store-file` belongs to one of three disjoint classes:

- **Valid object file:** A `store-file` is a **valid object file** when
  it meets `store-object-file` and its `line-object` meets its row of
  `ontology#object-kind`. The **canonical object** of a valid object
  file is its `line-object`, which is a canonical `object` of the kind
  named by its member `kind`. The `content-hash` of that canonical
  object is the `hash` of the content of that valid object file, and
  its `content-id` is its object kind word, `:`, and the first 32
  characters of that content hash. A valid object file is a valid file
  of `.sinter/` under `ontology#encoding`, holding its canonical
  object; any store file that is not a valid object file is not a valid
  file of `.sinter/`.
- **Newer object file:** A `store-file` is a **newer object file** (a
  store file of a newer form) when its valid path is an `object-path`,
  the object path of the `hash` of its content equals its valid path,
  and its content has a `decoded-json` value that is a `json-value`
  object with a member `v` whose value is an integer greater than `1`.
- **Broken store file:** A `store-file` is a **broken store file** when
  it is neither a valid object file nor a newer object file.

@example A [store file](sinter:#store-file=v1) holding
`{ "kind": "req", "v": 2, "x": { "y": 1 } }` followed by a line feed at
`.sinter/07/07e2a726451964ef8a0f8132cd98a5b4.json` is a newer object
file because its hash matches its [object path](sinter:#object-path=v1)
and its [decoded JSON](sinter:data-forms#decoded-json=v1) value is an
object with integer `v` greater than `1`, even though it is not a
canonical [line object](sinter:data-forms#line-object=v1). By contrast,
a file at its matching hash path holding `{"v":2,"x":null}` or
`{"v":2.0}` has no [decoded JSON](sinter:data-forms#decoded-json=v1)
value and is a broken store file, and `{"kind":"req","v":1}` at its
matching hash path meets
[store-object-file](sinter:#store-object-file=v1) but fails its row of
[object-kind](sinter:ontology#object-kind=v1) and is a broken store
file.

### Needed identity file

@term needed-identity-file=v1
@cites {
    ontology#{
        object=v1, object-kind=v1, computed-identity=v1,
        declared-item=v1, content-id=v1, edge=v1,
    },
    #valid-object-file=v1,
}

Let `O` be a canonical `object` of an object kind that
`ontology#object-kind` marks as allowed in `.sinter/`, and let `c` be a
`content-id` whose object kind word is one of the five
`computed-identity` kinds (`name`, `pin`, `ext`, `vector-set`, or
`vector-group`).

An **identity file** is a `valid-object-file` whose canonical object is
a `computed-identity` object. The **identity file for `c`** (and, when
`I` is the computed identity object with content ID `c`, the **identity
file of `I`**) is a `valid-object-file` whose canonical object is the
computed identity object with content ID `c`.

`O` **holds the key of `c` itself** when `O` is a `declared-item`
object (its member `kind` is `design`, `spec`, `schema`, `req`, `atom`,
`term`, or `decision`) and `c` is the content ID of the `name` computed
identity object whose member `name` equals the member `name` of `O`.

`O` **needs the identity file for `c`** (and **needs the computed
identity object `c`**) when `O` holds at least one `edge` in its member
`edges` whose member `to` equals `c`, and `O` does not hold the key of
`c` itself. When `I` is the computed identity object with content ID
`c`, `O` **needs `I`** (and **needs the identity file of `I`**) when
`O` needs the identity file for `c`.

@example The `req` [declared item](sinter:ontology#declared-item=v1)
object
`{"edges":[{"kind":"about","to":"name:0f17c8dd86ac60f052972d0be8ace0c2"}],"kind":"req","label":"v1","name":"billing#cap","text":"Limit amounts.","v":1}`
holds its own `name` key (`billing#cap`), so it needs no identity file
for `name:0f17c8dd86ac60f052972d0be8ace0c2`. By contrast, the `scope`
object
`{"edges":[{"kind":"about","to":"task:41fd2571f81b80ea2872200fdcead62b"},{"kind":"promises-satisfies","to":"name:0f17c8dd86ac60f052972d0be8ace0c2"}],"kind":"scope","paths":["lib/billing/"],"v":1}`
does not hold that key and needs the identity file
`.sinter/0f/0f17c8dd86ac60f052972d0be8ace0c2.json`
([object path](sinter:#object-path=v1)). Likewise, a `plan-def`
[definition statement](sinter:ontology#definition-statement=v1) holds a
display name rather than a declared-item key, so it needs the identity
file for any `name` [content ID](sinter:ontology#content-id=v1) in its
`carries-out` edges.

### Tree object store

@term tree-object-store=v1
@cites {
    conformance#{
        design=v1, encoding=v1, input=v1, dependence=v1, object=v1,
        own-store=v1,
    },
    ontology#{
        tree=v1, encoding=v1, object=v1, object-kind=v1,
        computed-identity=v1, content-id=v1, declared-item=v1,
    },
    #{store-file=v1, valid-object-file=v1, needed-identity-file=v1},
}

The **object store** of a `tree` is the set of all store files
(`store-file`) of that tree. Local files of that tree and files outside
`.sinter/` are not members of the object store of that tree.

Under `conformance#encoding` and `ontology#encoding`, the object store
of a tree is one input in the `.sinter/` encoding for objects of the
object kinds that `ontology#object-kind` marks as allowed in `.sinter/`.
The object store of a tree is **valid** when every store file of that
tree is a `valid-object-file`, and **invalid** otherwise. A tree with
zero store files has a valid object store. When the object store of a
tree is valid, the canonical `object`s that the object store of that
tree holds are the canonical objects of its store files, each once, and
no other object.

When the object store of a tree is valid, a `computed-identity` object
with `content-id` `c` is **missing** from the object store of that tree
when at least one `valid-object-file` of that tree has a canonical
object that needs the identity file for `c` (`needed-identity-file`)
and no `valid-object-file` of that tree has a canonical object whose
`content-id` is `c`. Such an absent computed identity object does not
make the object store of that tree invalid; it is a part that a valid
object store of a tree can lack under `conformance#input`.

An input **provides** a `computed-identity` object `I` when that input
holds `I`. An input **provides the key** of `I` when that input holds,
in the text encoding (`ontology#encoding`), a key from which `I`
derives, or when `I` is a `name` object and that input holds a
`declared-item` object whose member `name` equals the member `name` of
`I`; no other member, such as the member `name` of a `plan-def` or of a
`pin` object, provides a key. A thing that a requirement (`design`)
obliges **needs** such an absent computed identity object `I`, as a
part of the object store of that tree (`dependence`), when that thing
needs the key of `I` and no valid input of the run (neither the object
store of that tree, nor any other valid encoding input, nor a valid
`own-store`) provides `I` or its key.

@example Suppose a [tree](sinter:ontology#tree=v1) has a valid object
store holding a `scope`
[valid object file](sinter:#valid-object-file=v1) whose
`promises-satisfies` edge targets
`name:0f17c8dd86ac60f052972d0be8ace0c2` (`billing#cap`), while
`.sinter/` lacks that `name`
[computed identity](sinter:ontology#computed-identity=v1) file
([needed-identity-file](sinter:#needed-identity-file=v1)). That `name`
object is missing from the object store. If a text file in the tree
declares `billing#cap` in the text
[encoding](sinter:ontology#encoding=v1), or if `.sinter/` holds a `req`
[declared item](sinter:ontology#declared-item=v1) object with member
`name` `"billing#cap"`, that input provides the key of that `name`
object. No obliged result then needs that absent `name` object
([dependence](sinter:conformance#dependence=v1)), so a
[conforming program](sinter:conformance#conforming-program=v1) withholds
no result under
[report-missing-parts](sinter:conformance#report-missing-parts=v1), even
though the `name` object remains missing from the object store.

### Invalid-object-file finding

@atom invalid-object-file-finding=v1
@cites {
    findings#{
        finding-part=v1, finding-subject=v1, location=v1, message=v1,
        mark=v1, related-message=v1, fix=v1, ackable-finding=v1,
        path-finding-subject=v1,
    },
    files#path=v1,
    ontology#{finding-class=v1, tree=v1},
    #{store-file=v1, valid-object-file=v1},
}

A `tree` has one tree finding of the `finding-class`
`invalid-object-file` for each `store-file` of the tree that is not a
`valid-object-file`. Each finding has these `finding-part` values:

- **tree:** that `tree`;
- **finding class:** `invalid-object-file`;
- **subject:** the `path-finding-subject` of the valid `path` of that
  store file (`finding-subject`);
- **location:** the valid `path` of that store file alone, with no span
  (`location`);
- **mark, fix, and ackability:** no `mark`, no `fix`, and not ackable
  (`ackable-finding`);
- **message:** a `message` stating what is wrong — stating that the
  file has a newer form when that store file is a newer object file,
  and not stating that the file has a newer form when that store file
  is a broken store file;
- **related messages:** any `related-message` values that the program
  returns.

### Missing-identity-file finding

@atom missing-identity-file-finding=v1
@cites {
    findings#{
        finding-part=v1, finding-subject=v1, location=v1, message=v1,
        mark=v1, related-message=v1, fix=v1, ackable-finding=v1,
        path-finding-subject=v1,
    },
    files#path=v1,
    text#{character=v1, text=v1},
    ontology#{
        finding-class=v1, tree=v1, content-id=v1, computed-identity=v1,
    },
    #{valid-object-file=v1, needed-identity-file=v1},
}

A `tree` has one tree finding of the `finding-class`
`missing-identity-file` for each pair of a `valid-object-file` `F` of
the tree and a `content-id` `c` of one of the five `computed-identity`
kinds such that the canonical object of `F` needs the identity file for
`c` (`needed-identity-file`) and no `valid-object-file` of the tree has
a canonical object whose `content-id` is `c`. Each finding has these
`finding-part` values:

- **tree:** that `tree`;
- **finding class:** `missing-identity-file`;
- **subject:** the `text` formed by the `path-finding-subject` of the
  valid `path` of `F`, then a space (`U+0020`, `character`), then `c`
  (`finding-subject`);
- **location:** the valid `path` of `F` alone, with no span
  (`location`);
- **mark, fix, and ackability:** no `mark`, no `fix`, and not ackable
  (`ackable-finding`);
- **message:** a `message` stating what is wrong;
- **related messages:** any `related-message` values that the program
  returns.

## Requirements

### Validating object paths

@req validate-object-paths=v1
@cites {
    conformance#conforming-program=v1,
    text#text=v1,
    #object-path=v1,
}

When a conforming program validates a `text` as an `object-path`, the
program must return `"valid"` when the text is an object path, and must
return `"invalid"` otherwise.

### Validating store object files

@req validate-store-object-files=v1
@cites {
    conformance#conforming-program=v1,
    files#path=v1,
    text#byte-sequence=v1,
    #{store-file=v1, store-object-file=v1},
}

When a conforming program validates a `store-file` (a store `path` and
a content `byte-sequence`) against `store-object-file`, the program
must return `"valid"` when that store file meets `store-object-file`,
and must return `"invalid"` otherwise.

### Returning store objects

@req give-store-objects=v1
@cites {
    conformance#{conforming-program=v1, reject-invalid-inputs=v1},
    ontology#{tree=v1, object=v1, content-id=v1},
    #{store-file=v1, valid-object-file=v1, tree-object-store=v1},
}

When the `tree-object-store` of a `tree` is valid and a conforming
program returns the canonical `object`s of that object store, the
program must return the canonical object (`valid-object-file`) of each
`store-file` of that tree once, with no extra object and no object from
any local file inside `.sinter/local/`. When a conforming program
returns a text as the `content-id` of a canonical object of the object
store of a tree, the program must return the `content-id` of that
canonical object.

When the `tree-object-store` of a `tree` is invalid, a conforming
program must return no canonical object of that object store
(`reject-invalid-inputs`).

### Returning store findings

@req give-store-findings=v1
@cites {
    conformance#{
        design=v1, conforming-program=v1, input=v1, dependence=v1,
        report=v1, reject-invalid-inputs=v1, report-missing-parts=v1,
    },
    ontology#{finding-class=v1, tree=v1},
    findings#{finding-part=v1, message=v1},
    #{
        tree-object-store=v1, store-file=v1, valid-object-file=v1,
        invalid-object-file-finding=v1,
        missing-identity-file-finding=v1,
    },
}

Whether the `tree-object-store` of a `tree` is valid or invalid, when a
conforming program returns the findings of that tree of the
`finding-class` `invalid-object-file`, the program must return each
`invalid-object-file-finding` that the tree has once, with no extra
finding of that class. For each such finding whose `store-file` is a
newer object file (`valid-object-file`), the `message` (`finding-part`)
must state that the file has a newer form; for each such finding whose
store file is a broken store file, the `message` must not state that
the file has a newer form. When the object store of a tree is invalid,
these findings are the `report` of the invalid object store under
`reject-invalid-inputs`.

Whether the `tree-object-store` of a `tree` is valid or invalid, when a
conforming program returns the findings of that tree of the
`finding-class` `missing-identity-file`, the program must return each
`missing-identity-file-finding` that the tree has once, with no extra
finding of that class. When a thing that a requirement (`design`)
obliges needs (`dependence`) a computed identity object that a valid
object store of a tree lacks (`input`), these findings are the `report`
of this design for that missing part under `report-missing-parts`.

### Writing object files

@req write-object-files=v1
@cites {
    conformance#{design=v1, conforming-program=v1, input=v1},
    files#{
        directory=v1, directory-tree=v1, file-kind=v1, path=v1,
        path-resolution=v1,
    },
    data-forms#canonical-byte-sequence=v1,
    ontology#{tree=v1, object=v1, object-kind=v1},
    text#byte-sequence=v1,
    #{
        object-path=v1, store-file=v1, valid-object-file=v1,
        tree-object-store=v1, needed-identity-file=v1,
    },
}

In this requirement, for a canonical `object` `O` of an object kind
that `ontology#object-kind` marks as allowed in `.sinter/`, the
**two-hex-digit subdirectory** of the `object-path` of `O` is the file
named by path segment 2 (`path`) of that object path
(`path-resolution`). A **failure notice** for `O` is one output that
identifies that the program could not write `O`, in any form such as a
text, a structured output, an exit status, or an error value.

Whether the `tree-object-store` of a working `tree` is valid or
invalid, when a conforming program writes such a canonical `object` `O`
to the object store of that working tree, the program must satisfy
these four conditions in the `directory-tree` of that working tree:

1. **Writing a new file:** When neither `.sinter` nor the two-hex-digit
   subdirectory of the `object-path` of `O` is a regular file, a
   symbolic link, or a file of another kind (`file-kind`), no directory
   entry (`directory`) stands at the object path of `O`, and neither
   condition 4 nor another requirement (`design`) of this design
   forbids writing a file for `O`, the program must write the
   `canonical-byte-sequence` of `O` (with no member `id` and no
   trailing line feed) as a regular file at the object path of `O`,
   creating `.sinter` and that two-hex-digit subdirectory when absent.
   When the system (`input`) refuses that write or does not complete it
   (for example, for a missing write permission, a read-only file
   system, a full disk, or an I/O error), the program must instead
   return one failure notice for `O`.
2. **Existing equal file:** When `.sinter` and the two-hex-digit
   subdirectory of the `object-path` of `O` are directories and a
   regular file already stands at the object path of `O` whose content
   `byte-sequence` equals the `canonical-byte-sequence` of `O`, the
   program must leave that regular file unchanged and must return no
   failure notice for `O`.
3. **Blocking path:** When `.sinter` or the two-hex-digit subdirectory
   of the `object-path` of `O` is a regular file, a symbolic link, or a
   file of another kind, or when `.sinter` and that subdirectory are
   directories and either a regular file whose content differs from the
   `canonical-byte-sequence` of `O` or a symbolic link, a directory, or
   a file of another kind stands at the object path of `O`, the program
   must change nothing at that blocking path, must write no file for
   `O`, and must return one failure notice for `O`.
4. **Identity-file completeness:** When a conforming program writes one
   or more objects to the object store of a working tree in one run —
   whether the write succeeds or fails partway through — the program
   must leave no newly written `store-file` in `.sinter/` of that
   working tree whose canonical object needs an identity file
   (`needed-identity-file`) for which no `valid-object-file` exists in
   the `directory-tree` of that working tree at the end of that run.
   When condition 4 or another requirement of this design forbids a
   write of `O` that condition 1 would otherwise require, the program
   must write no file for `O` and must return one failure notice for
   `O`.

### Limiting store writes

@req limit-store-writes=v1
@cites {
    conformance#{conforming-program=v1, safety-obligation=v1},
    files#{directory=v1, directory-tree=v1, file-kind=v1},
    ontology#tree=v1,
    text#utf-8-encoding=v1,
    #store-file=v1,
}

When a conforming program writes a file in the `directory` `.sinter/`
of the `directory-tree` of a working `tree` (a `store-file` or a local
file inside `.sinter/local/`), the program must write and alter nothing
outside that directory by that write, other than creating the directory
`.sinter` in the root of that directory tree when that root holds no
directory entry whose entry name is the `utf-8-encoding` of `.sinter`,
and must follow no symbolic link (`file-kind`) in that write.

### Keeping store files unchanged

@req keep-store-files-unchanged=v1
@cites {
    conformance#{conforming-program=v1, safety-obligation=v1},
    files#directory-tree=v1,
    ontology#tree=v1,
    #{store-file=v1, valid-object-file=v1},
}

A conforming program must never change the content of an existing store
file (`store-file`) in the `directory-tree` of a working `tree`,
whether or not the store file formed by its store path and its content
is a `valid-object-file`.

### Writing no file after a resource-limit stop

@req write-no-file-after-stop=v1
@cites {
    conformance#{
        conforming-program=v1, safety-obligation=v1, resource-limit=v1,
    },
    files#{directory=v1, directory-tree=v1},
    ontology#tree=v1,
}

When a conforming program reaches a `resource-limit` in a run, the
program must write no further file in the `directory` `.sinter/` of the
`directory-tree` of any working `tree` in that run, including inside
`.sinter/local/`.

### Writing no file after a read error

@req write-no-file-after-read-error=v1
@cites {
    conformance#{
        conforming-program=v1, safety-obligation=v1, input=v1,
    },
    files#{directory=v1, directory-tree=v1},
    ontology#tree=v1,
}

In a run in which content of a file or a `directory` is a part that an
`input` lacks because a conforming program could not read that content,
the program must write no file in the `directory` `.sinter/` of the
`directory-tree` of any working `tree`, including inside
`.sinter/local/`.

### Limiting store deletions

@req limit-store-deletions=v1
@cites {
    conformance#{
        conforming-program=v1, safety-obligation=v1, input=v1,
        resource-limit=v1,
    },
    files#{directory=v1, directory-tree=v1, file-kind=v1},
    ontology#{tree=v1, object-withdrawal=v1, computed-identity=v1},
    #{
        store-file=v1, valid-object-file=v1, tree-object-store=v1,
        needed-identity-file=v1,
    },
}

When a conforming program deletes a file in the `directory` `.sinter/`
of the `directory-tree` of a working `tree` (a `store-file` or a local
file inside `.sinter/local/`), the program must delete nothing outside
that directory by that deletion and must follow no symbolic link
(`file-kind`) in that deletion. A conforming program must delete a
`store-file` only when one of these two conditions holds:

1. The store file is a `valid-object-file` holding an object that a
   counting void in that tree withdraws (`object-withdrawal`).
2. Every store file of that tree is a `valid-object-file` and the store
   file holds a `computed-identity` object that no object of the
   `tree-object-store` of that tree needs (`needed-identity-file`).

A conforming program must delete no `store-file` in a run in which
content of a file or a `directory` is a part that an `input` lacks
because the program could not read that content. When a conforming
program reaches a `resource-limit` in a run, the program must delete no
further `store-file` in that run.

## Test vectors

Test vectors for this design live in
[`object-store.test-vectors.jsonl`](object-store.test-vectors.jsonl)
as a test-vector set under
[test-vectors](sinter:data-forms#test-vectors=v1). No group uses
`needs`. Groups `object-paths` and `store-object-files` omit `values`;
group `tree-stores` omits `result`.

### Object path vectors

@schema object-path-vector=v1
@cites {
    text#text=v1,
    data-forms#{vector-line=v1, group-schema=v1, vector-meaning=v1},
    #{object-path=v1, validate-object-paths=v1},
}

`object-path-vector` is a `group-schema` for group `object-paths` and
tests `validate-object-paths`. Each line is a `vector-line` whose
meaning follows `vector-meaning`.

| field | type | meaning |
|---|---|---|
| `input.path` | string | `text` to validate as an `object-path` |
| `result` | string | `"valid"` when `input.path` is an `object-path`, `"invalid"` otherwise |

@example Sample lines testing
[validate-object-paths](sinter:#validate-object-paths=v1) on valid and
invalid [object-path](sinter:#object-path=v1) inputs
([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#object-path-vector=v1","group":"object-paths","input":{"path":".sinter/0d/0d000000000000000000000000000000.json"},"note":"valid object path with matching two-digit directory prefix","result":"valid"}
{"form":"#object-path-vector=v1","group":"object-paths","input":{"path":".sinter/ab/0d000000000000000000000000000000.json"},"note":"directory prefix does not match first two hex digits of file name","result":"invalid"}
```

### Store object file vectors

@schema store-object-file-vector=v1
@cites {
    files#path=v1,
    text#{byte-sequence=v1, valid-utf-8=v1, utf-8-text=v1},
    data-forms#{
        hex-text=v1, vector-line=v1, group-schema=v1, vector-meaning=v1,
    },
    #{
        store-file=v1, store-object-file=v1,
        validate-store-object-files=v1,
    },
}

`store-object-file-vector` is a `group-schema` for group
`store-object-files` and tests `validate-store-object-files`. Each line
is a `vector-line` whose meaning follows `vector-meaning`.

| field | type | meaning |
|---|---|---|
| `input.path` | string | store `path` of the `store-file` |
| `input.content` | string or `{"bytes": string}` | content `byte-sequence` of the `store-file`: its `utf-8-text` when `valid-utf-8`, or `{"bytes": <hex-text>}` when not `valid-utf-8` |
| `result` | string | `"valid"` when the `store-file` meets `store-object-file`, `"invalid"` otherwise |

@example Sample lines testing
[validate-store-object-files](sinter:#validate-store-object-files=v1)
against [store-object-file](sinter:#store-object-file=v1), including
rejection of `kind` `"example"`
([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#store-object-file-vector=v1","group":"store-object-files","input":{"content":"{\"kind\":\"req\",\"v\":1}","path":".sinter/3f/3fc66a77d784ac3747f1b6371d9f30cd.json"},"note":"minimal store object file passes store-object-file even without req members","result":"valid"}
{"form":"#store-object-file-vector=v1","group":"store-object-files","input":{"content":"{\"edges\":[{\"kind\":\"about\",\"to\":\"name:0f17c8dd86ac60f052972d0be8ace0c2\"}],\"index\":1,\"kind\":\"example\",\"text\":\"Sample example.\",\"v\":1}","path":".sinter/ed/edd51b4cb31d14f5ac4e7b8f651311e6.json"},"note":"kind `example` is not allowed in `.sinter/`","result":"invalid"}
```

### Tree store vectors

@schema tree-store-vector=v1
@cites {
    files#path=v1,
    text#{
        byte-sequence=v1, valid-utf-8=v1, utf-8-text=v1,
        code-point-order=v1,
    },
    data-forms#{
        hex-text=v1, line-object=v1, vector-line=v1, group-schema=v1,
        vector-meaning=v1,
    },
    ontology#{tree=v1, object=v1, content-id=v1, finding-class=v1},
    findings#{
        finding-part=v1, finding-subject=v1, location=v1, message=v1,
    },
    #{
        tree-object-store=v1, valid-object-file=v1,
        invalid-object-file-finding=v1,
        missing-identity-file-finding=v1,
        give-store-objects=v1, give-store-findings=v1,
    },
}

`tree-store-vector` is a `group-schema` for group `tree-stores` and
tests `give-store-objects` and `give-store-findings`. Each line is a
`vector-line` whose meaning follows `vector-meaning`.

| field | type | meaning |
|---|---|---|
| `input.files` | object | input `tree`, mapping each file's valid `path` to its content `byte-sequence` (`utf-8-text` string when `valid-utf-8`, or `{"bytes": <hex-text>}` otherwise) |
| `values.findings[]` | array of objects | all `invalid-object-file-finding` and `missing-identity-file-finding` findings of the tree, sorted in `code-point-order` of `class` then `subject` |
| `values.findings[].class` | string | `finding-class`: `"invalid-object-file"` or `"missing-identity-file"` |
| `values.findings[].subject` | string | `finding-subject` text |
| `values.findings[].location.path` | string | valid `path` of the file (`location` with no span) |
| `values.findings[].newer-form` | boolean | present exactly when `class` is `"invalid-object-file"`: `true` for a newer object file (`valid-object-file`), `false` for a broken store file |
| `values.objects` | object (optional) | present exactly when the `tree-object-store` is valid, mapping each canonical `object`'s `content-id` to that canonical object (`line-object`); absent when the store is invalid (no canonical object returned) |

For each `invalid-object-file` finding in `values.findings`, its
`message` (`finding-part`) states that the file has a newer form when
`newer-form` is `true`, and does not state that when `newer-form` is
`false`.

@example Sample lines testing
[give-store-objects](sinter:#give-store-objects=v1) and
[give-store-findings](sinter:#give-store-findings=v1) on a valid
[tree-object-store](sinter:#tree-object-store=v1) and on an invalid
store with both an
[invalid-object-file](sinter:#invalid-object-file-finding=v1) finding
and a [missing-identity-file](sinter:#missing-identity-file-finding=v1)
finding ([vector-line](sinter:data-forms#vector-line=v1)):

```json
{"form":"#tree-store-vector=v1","group":"tree-stores","input":{"files":{".sinter/f6/f6259f147d032738f64394a0796087a3.json":"{\"edges\":[{\"kind\":\"about\",\"to\":\"name:0f17c8dd86ac60f052972d0be8ace0c2\"}],\"kind\":\"req\",\"label\":\"v1\",\"name\":\"billing#cap\",\"text\":\"Limit amounts.\",\"v\":1}"}},"note":"declared item in .sinter/ holds its own name key and needs no name identity file","values":{"findings":[],"objects":{"req:f6259f147d032738f64394a0796087a3":{"edges":[{"kind":"about","to":"name:0f17c8dd86ac60f052972d0be8ace0c2"}],"kind":"req","label":"v1","name":"billing#cap","text":"Limit amounts.","v":1}}}}
{"form":"#tree-store-vector=v1","group":"tree-stores","input":{"files":{".sinter/41/41fd2571f81b80ea2872200fdcead62b.json":"{\"kind\":\"task\",\"nonce\":\"0123456789abcdef0123456789abcdef\",\"v\":1}",".sinter/b6/b6fb908fc2b3fc68e2b2eee6779af867.json":"{\"edges\":[{\"kind\":\"about\",\"to\":\"task:41fd2571f81b80ea2872200fdcead62b\"},{\"kind\":\"promises-satisfies\",\"to\":\"name:0f17c8dd86ac60f052972d0be8ace0c2\"}],\"kind\":\"scope\",\"paths\":[\"lib/billing/\"],\"v\":1}",".sinter/bad.txt":"broken"}},"note":"tree gets both an invalid-object-file finding and a missing-identity-file finding while holding back store objects","values":{"findings":[{"class":"invalid-object-file","location":{"path":".sinter/bad.txt"},"newer-form":false,"subject":".sinter/bad.txt"},{"class":"missing-identity-file","location":{"path":".sinter/b6/b6fb908fc2b3fc68e2b2eee6779af867.json"},"subject":".sinter/b6/b6fb908fc2b3fc68e2b2eee6779af867.json name:0f17c8dd86ac60f052972d0be8ace0c2"}]}}
```
