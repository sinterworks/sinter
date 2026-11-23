<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Object store
@design object-store=v1
@cites conformance=v1
@cites text=v1
@cites files=v1
@cites data-forms=v1
@cites ontology=v1
@cites findings=v1
@cites rfc/5234
@cites rfc/7405
Specifies the `.sinter/` object store encoding: object paths, store paths, store files, and the skip of `.sinter/local/`; store object files, newer object files, valid object files, broken store files, and needed identity files; the object store of a tree; the finding classes `invalid-object-file` and `missing-identity-file`; and requirements for conforming programs on object-path and store-file validation, the canonical objects and findings of the object store of a tree, writing object files, and the safety of writes and deletions in `.sinter/`.

The object store of a tree holds Sinter objects as fixed files in the
folder `.sinter/`, one object in each file. Each file holds the
canonical byte sequence of its object, with no member `id` and no final
line feed, at a path computed from the SHA-256 hash of those bytes.
Files inside `.sinter/local/` are local files of one machine and stay
outside the object store. Rules in ABNF follow RFC 5234 with the
case-sensitive quoted strings of RFC 7405.

From Conformance (`conformance`), the Object store takes requirements,
conforming programs, inputs, dependence, limits of a program's own,
reports, safety obligations, objects, encodings, valid program's own
stores, and the general requirements that bind every conforming program.
From Text and notation (`text`), it takes texts, spaces, whole numbers,
hex digits, code point order, byte sequences, valid UTF-8, the texts of
byte sequences, UTF-8 encodings of texts, code spans, productions, rule
names, and results. From Files and paths (`files`), it takes the system,
folders, regular files, symbolic links, files of another kind, folder
trees, valid paths with their numbered file names, and the files of a
path in a folder tree. From Data forms (`data-forms`), it takes hex
texts, JSON values, canonical byte sequences, hashes, line objects, and
the JSON values of byte sequences; and from its specification
`test-vectors`, test-vector sets, vector lines, the forms of a group,
and the meaning of a vector. From the Ontology (`ontology`), it takes
trees (including working trees and their folder trees), files of
`.sinter/` of a tree, encodings, objects, the schema table of object
kinds (`object-kind`), content hashes, content ids, computed identity
objects, declared items, edges, object withdrawal and counting voids,
and finding classes. From Findings (`findings`), it takes the parts of a
finding, finding subjects, messages, spots, marks, related messages,
fixes, and ackable findings.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [conforming program](sinter:conformance#conforming-program=v1) | a program, or a part of a program, that meets every requirement of a design together with the general requirements of Conformance |
| [safety obligation](sinter:conformance#safety-obligation=v1) | an obligation of a requirement that states that a program reads, alters, writes, follows, or runs no thing other than the things that the requirement allows, or gains no permission; that a program never gives an answer that permits an action to proceed; or that a program ends code or an operation that the program runs |
| [input](sinter:conformance#input=v1) | a thing that a conforming program takes; content that the program could not take under the rules of `input` (for example because of a refused permission or an input or output error) is a part that a valid input lacks |
| [limit of a program's own](sinter:conformance#own-limit=v1) | a bound of a program, of its run, or of its machine on a resource that the program uses, such as size, memory, time, or depth; a feature that a program lacks, code that never ends, and any condition that makes content a part that an input lacks under [input](sinter:conformance#input=v1) are not limits of a program's own |
| [report](sinter:conformance#report=v1) | a thing that a conforming program gives to identify a stop at a limit of its own, an input that is not valid, or a missing part of a valid input |
| [encoding](sinter:conformance#encoding=v1) | a form in which objects are stored in an input; the design that defines it says what constitutes one input, when it is valid, and which canonical objects it holds |
| [valid path](sinter:files#path=v1) | a text of one or more file names, numbered from 1, with `/` between each two of them, such as `.sinter/0f/0f17c8dd86ac60f052972d0be8ace0c2.json` |
| [folder tree](sinter:files#folder-tree=v1), [folder](sinter:files#folder=v1), [regular file](sinter:files#regular-file=v1), [symbolic link](sinter:files#symbolic-link=v1), [file of another kind](sinter:files#file-of-another-kind=v1) | a root folder together with the files of its folder entries recursively; a folder holds folder entries, a regular file holds a byte sequence, a symbolic link holds a reference, and a file of another kind is none of those three |
| [hex digit](sinter:text#hex-digit=v1) | one of the lowercase characters `0` to `9` and `a` to `f` |
| [byte sequence](sinter:text#byte-sequence=v1), [valid UTF-8](sinter:text#valid-utf-8=v1) | a finite sequence of bytes; a byte sequence is valid UTF-8 when it is the UTF-8 encoding of a text |
| [JSON value](sinter:data-forms#json-value=v1), [line object](sinter:data-forms#line-object=v1), [canonical byte sequence](sinter:data-forms#canonical-byte-sequence=v1), [hash](sinter:data-forms#hash=v1) | a string, an integer, a boolean, an array, or an object; an object whose member values are scalars, arrays of scalars, or arrays of flat objects; the UTF-8 encoding of the canonical form of a JSON value, with no final line feed; the 64 lowercase hex digits of SHA-256 |
| [tree](sinter:ontology#tree=v1) | a set of files, each a valid path with a content byte sequence and with no two files sharing a valid path; a working tree also has a folder tree |
| [object](sinter:ontology#object=v1), [object kind](sinter:ontology#object-kind=v1) | an entity of one of the twenty-five kinds in the Ontology's schema table `object-kind`, with one canonical form as a line object without an `id` member |
| [content hash](sinter:ontology#content-hash=v1), [content id](sinter:ontology#content-id=v1) | the SHA-256 hash of the canonical byte sequence of an object (no `id`, no final line feed); the object kind word of the object, `:`, and the first 32 hex digits of its content hash |
| [computed identity](sinter:ontology#computed-identity=v1) | an object of one of the five kinds `name`, `pin`, `ext`, `vector-set`, and `vector-group`, holding only `kind`, `v` (1), and its key |
| [counting void](sinter:ontology#object-withdrawal=v1), [withdrawn](sinter:ontology#object-withdrawal=v1) | a `void` object in a valid file of `.sinter/` that meets its acceptance rule, carries no `agent`, has a writer in the bound list of persons when a list is bound (when no list is bound, every person's voids count), and meets the copy rule when its withdrawn object is present; an object named by a counting void's `withdraws` edge |
| [finding](sinter:ontology#finding-class=v1), [finding class](sinter:ontology#finding-class=v1), [parts of a finding](sinter:findings#finding-part=v1) | a report of one condition at one part of a repository; a kind of finding named by a slug; its tree, class, subject, message, spot, mark, related messages, fix, and ackability |
| [object path](sinter:#object-path=v1) | a valid path of the form `.sinter/<2 hex>/<32 hex>.json` whose two-digit folder matches the first two of the 32 lowercase hex digits |
| [local path](sinter:#store-file=v1), [local file](sinter:#store-file=v1) | a valid path with three or more file names starting with `.sinter` and `local` (inside `.sinter/local/`); a file of a tree at a local path |
| [store path](sinter:#store-file=v1), [store file](sinter:#store-file=v1), [existing store file](sinter:#store-file=v1) | a valid path with two or more file names whose file name 1 is `.sinter` and that is not a local path; a file of a tree at a store path; a regular file at a store path in a folder tree |
| [store object file](sinter:#store-object-file=v1) | a store file at an object path whose content is the canonical byte sequence of a line object without `id`, with `v` equal to 1 and `kind` allowed in `.sinter/`, and whose SHA-256 hash matches its path |
| [newer object file](sinter:#newer-object-file=v1) | a store file at an object path whose SHA-256 hash matches its path and whose JSON value is an object with an integer member `v` greater than 1 |
| [valid object file](sinter:#valid-object-file=v1), [broken store file](sinter:#valid-object-file=v1) | a store object file whose line object meets its row of `ontology#object-kind`; a store file that is neither a valid object file nor a newer object file |
| [identity file](sinter:#needed-identity-file=v1), [needed identity file](sinter:#needed-identity-file=v1) | a valid object file whose canonical object is a computed identity object; an identity file for a content id that an edge of a stored object names, when that object does not hold the key of that computed identity object itself |
| [object store of a tree](sinter:#tree-object-store=v1) | the set of all store files of a tree, forming one input in the `.sinter/` encoding |
| [`invalid-object-file`](sinter:#invalid-object-file-finding=v1) | the non-ackable tree finding class that reports a store file that is not a valid object file |
| [`missing-identity-file`](sinter:#missing-identity-file-finding=v1) | the non-ackable tree finding class that reports a valid object file whose needed identity file is absent from the store |
| notice | a thing that a conforming program gives to identify that it could not write an object, in any form that identifies that fact, such as a text, a structured output, an exit status, or an error value |

## 2. The `.sinter/` object store

### 2.1 Object paths and store files

Each object stored in `.sinter/` lives in its own file at the object
path of its content hash (term `object-path`). For example,
`.sinter/0f/req:0f17c8dd86ac60f052972d0be8ace0c2.json` is not an object
path. The file holds the canonical byte sequence of its canonical
object, with no member `id` and no final line feed. Therefore, hashing
the raw bytes of the file with SHA-256 gives the content hash and the
object path directly.

For example, the `name` computed identity object
`{"kind":"name","name":"billing#cap","v":1}` has the content id
`name:0f17c8dd86ac60f052972d0be8ace0c2` and the object path
`.sinter/0f/0f17c8dd86ac60f052972d0be8ace0c2.json`. The `task` object
`{"kind":"task","nonce":"0123456789abcdef0123456789abcdef","v":1}` has
the content id `task:41fd2571f81b80ea2872200fdcead62b` and the object
path `.sinter/41/41fd2571f81b80ea2872200fdcead62b.json`.

Files inside the folder `.sinter/local/` (paths with three or more file
names starting with `.sinter` and `local`) are local files and stay
outside the object store (term `store-file`). A conforming program never
reads a local file as an object of the store and never reports a local
file as an invalid store file. Every other file of a tree whose valid
path has two or more file names and whose file name 1 is `.sinter` is a
store file. In particular, a regular file at
the two-segment path `.sinter/local` is not inside the folder
`.sinter/local/`; it is a store file and fails validation.

Because the object store consists of files of a tree (`ontology#tree`),
only files in that tree enter the store, and executable file permissions
(such as mode 100755) change neither a file's path nor its content.

### 2.2 Valid, newer, and broken store files

Every store file of a tree falls into one of three disjoint classes
(schema `store-object-file`, terms `newer-object-file` and
`valid-object-file`):

- A **valid object file** meets `store-object-file` and its line object
  meets its row of `ontology#object-kind`. For example, the `req` file
  at `.sinter/f6/f6259f147d032738f64394a0796087a3.json` holding
  `{"edges":[{"kind":"about","to":"name:0f17c8dd86ac60f052972d0be8ace0c2"}],"kind":"req","label":"v1","name":"billing#cap","text":"Limit amounts.","v":1}`
  is a valid object file.
- A **newer object file** stands at an object path, hashes with SHA-256
  to that path, and decodes through
  `data-forms#json-value-of-a-byte-sequence` to a JSON object whose
  member `v` is an integer greater than 1. For example,
  `{"kind":"req","label":"v1","name":"billing#x","v":2}` at
  `.sinter/08/08295f28ae2397ddfc7feada4b032086.json` is a newer object
  file, and a `v: 2` JSON object with a nested object at its matching
  hash path is also a newer object file.
- A **broken store file** is any other store file. A damaged `v: 2` file
  whose hash does not match its path, a `v: 2` file at
  `.sinter/notes.txt`, a file with a trailing line feed, a file with a
  stray member `id`, a file whose `kind` is not allowed in `.sinter/`,
  and a file whose object fails its row of `ontology#object-kind` (such
  as a `task-def` without `by`) are all broken store files.

### 2.3 The object store of a tree and its identity files

The object store of a tree is the set of all store files of that tree
and constitutes one input in the `.sinter/` encoding (term
`tree-object-store`). An empty object store, with zero store files, is
valid. When every store file of a tree is a valid object file, the
object store of that tree is valid and gives the canonical object of
each store file once, and no other object (requirement
`give-store-objects`).

When any store file of a tree is not a valid object file (whether broken
or newer), the object store of that tree is not valid. Under
`conformance#reject-invalid-inputs`, a conforming program gives no
canonical object of that store and no result over the objects of that
tree that depends on that store, while still giving each finding of the
classes `invalid-object-file` and `missing-identity-file` that the tree
has, once, and no other finding of those classes (requirement
`give-store-findings`).

Each store file that is not a valid object file gets one non-ackable
tree finding of the class `invalid-object-file` (atom
`invalid-object-file-finding`). For a newer object file, the message of
the finding states that the file has a newer form; for a broken store
file, the message does not state that the file has a newer form.

A valid object file whose canonical object holds an edge naming a
computed identity content id needs the corresponding identity file
unless that canonical object holds the key itself (term
`needed-identity-file`). A declared-item object already holds its own
member `name`, so it needs no `name` identity file for its own name.
Every other edge of a valid object file that names a computed identity
content id needs the corresponding identity file in `.sinter/`. For
example, the `scope` object
`{"edges":[{"kind":"about","to":"task:41fd2571f81b80ea2872200fdcead62b"},{"kind":"promises-satisfies","to":"name:0f17c8dd86ac60f052972d0be8ace0c2"}],"kind":"scope","paths":["lib/billing/"],"v":1}`
at `.sinter/b6/b6fb908fc2b3fc68e2b2eee6779af867.json` does not hold the
key `billing#cap` itself, so it needs the identity file
`.sinter/0f/0f17c8dd86ac60f052972d0be8ace0c2.json`.

When a valid object file needs an identity file that the store lacks,
that need does not make the store not valid. The tree gets one
non-ackable tree finding of the class `missing-identity-file` for that
naming file and content id (atom `missing-identity-file-finding`). When
no valid input of the run gives that computed identity object or its
key, a result needs that missing part only when that result needs its
key, so under `conformance#report-missing-parts` a conforming program
withholds only the results that need its key and gives every result that
does not need its key. When a valid input of the run gives that computed
identity object or its key (for example, a text file that declares
`billing#cap`, or a declared-item object in the store itself), the
program still gives that `missing-identity-file` finding for `.sinter/`
once and withholds no result because of that computed identity object.

### 2.4 Writes, deletions, and safety obligations

When a conforming program writes a canonical object to `.sinter/` of a
working tree, the program writes the canonical byte sequence of that
object at its object path, creating `.sinter` and its two-hex-digit
subfolder when absent (requirement `write-object-files`). When a regular
file already stands at that object path with equal bytes, the program
leaves that file unchanged and gives no notice of a failed write. When
other bytes or a symbolic link, a folder, or a file of another kind
stand in the way, the program changes nothing at that path, writes no
file for that object, and gives one notice that it could not write the
object, and no other notice for that failed write. When the system
refuses the write or does not complete it, the program gives one notice
that it could not write the object, and no other notice for that failed
write. When a conforming program writes one or more objects to
`.sinter/` in one run, whether the write succeeds or fails part of the
way, the program leaves no newly written store file in `.sinter/` whose
canonical object needs an identity file that is absent from `.sinter/`
at the end of that run. When that rule or another requirement of the
Object store forbids a write that would otherwise occur, the program
writes no file for that object and gives one notice that it could not
write the object, and no other notice for that failed write.

Five safety obligations bind every conforming program, including under
invalid inputs and missing parts; after the program reaches a limit of
its own in a run, the program writes no further file in `.sinter/`
(`.sinter/local/` included) and deletes no further store file in that
run, as the third and fifth obligations state:

- When a conforming program writes a file in the folder `.sinter/` of a
  working tree (a store file or a local file inside `.sinter/local/`),
  the program writes and alters nothing outside that folder by that
  write, other than creating the folder `.sinter` in the root when it is
  absent, and follows no symbolic link in that write (requirement
  `limit-store-writes`).
- A conforming program never changes the content of an existing store
  file, whether or not the file is valid; files inside `.sinter/local/`
  stand outside this rule (requirement `keep-store-files-unchanged`).
- When a conforming program reaches a limit of its own in a run, the
  program writes no further file in `.sinter/` in that run,
  `.sinter/local/` included (requirement `write-no-file-after-stop`).
- In a run in which the program could not read a file or a folder under
  `conformance#input`, the program writes no file in `.sinter/`,
  `.sinter/local/` included (requirement
  `write-no-file-after-read-error`).
- When a conforming program deletes a file in the folder `.sinter/` of a
  working tree (a store file or a local file inside `.sinter/local/`),
  the program deletes nothing outside that folder by that deletion and
  follows no symbolic link in that deletion. No requirement obliges a
  conforming program to delete any store file; the program deletes a
  store file only when the file is a valid object file holding a
  withdrawn object or an unneeded identity file of a valid object store,
  deletes no store file in a run with a read error, and deletes no
  further store file in a run after the program reaches a limit of its
  own (requirement `limit-store-deletions`).

What a conforming program gives while another process changes an input
tree or folder tree is a matter of the quality of an implementation.

## 3. Definitions

### 3.1 Object paths

@term object-path=v1
@cites {
    rfc/5234,
    rfc/7405,
    text#{
        production=v1, rule-name=v1, hex-digit=v1, code-span=v1,
        text=v1, whole-number=v1,
    },
    files#{path=v1},
    data-forms#{hash=v1},
    ontology#{content-hash=v1, object=v1},
}

An object path is a text that matches the production `object-path` and
in which the two characters matched by `2hex-digit` after `.sinter/`
equal the first two characters matched by `32hex-digit` after the second
`/`:

```abnf
object-path = %s".sinter/" 2hex-digit "/" 32hex-digit %s".json"
```

Every object path is a valid path. For a hash h (64 hex digits, as
`data-forms#hash` gives), the object path of h is the text `.sinter/`,
then the first two characters of h, then `/`, then the first 32
characters of h, then `.json`. The object path of an object is the
object path of its content hash.

### 3.2 Store paths and store files

@term store-file=v1
@cites {
    files#{path=v1, folder-tree=v1, regular-file=v1, path-file=v1},
    ontology#{tree=v1},
    text#{code-span=v1, text=v1, whole-number=v1},
}

A valid path is a local path (a path inside `.sinter/local/`) when, and
only when, it has three or more file names, file name 1 is `.sinter`,
and file name 2 is `local`. A valid path is a store path when, and only
when, it has two or more file names, file name 1 is `.sinter`, and it is
not a local path.

A local file of a tree is a file of that tree whose valid path is a
local path. A store file of a tree is a file of that tree whose valid
path is a store path (that is, a file of `.sinter/` of that tree in the
sense of `ontology#tree`).

In a folder tree, an existing store file is a regular file that the last
file name of a store path names in that folder tree (`files#path-file`).

### 3.3 Store object files

@schema store-object-file=v1
@cites {
    files#{path=v1},
    text#{byte-sequence=v1, code-span=v1, whole-number=v1},
    data-forms#{
        canonical-byte-sequence=v1, line-object=v1, json-value=v1,
        hash=v1,
    },
    ontology#{object-kind=v1, tree=v1},
    #{object-path=v1, store-file=v1},
}

A store file (a valid path that is a store path, together with a content
byte sequence) meets `store-object-file` (is a store object file) when,
and only when, all four of these conditions hold:

1. Its valid path is an object path.
2. Its content is the canonical byte sequence of a line object (with no
   final line feed).
3. The object path of the hash of its content equals its valid path.
4. That line object has no member `id`, has the member `v` whose value
   is the integer 1, and has the member `kind` whose value is a string
   naming an object kind that `ontology#object-kind` marks as allowed in
   `.sinter/`.

The line object of a store object file is the one line object whose
canonical byte sequence is the content of that store object file.

### 3.4 Newer object files

@term newer-object-file=v1
@cites {
    data-forms#{
        hash=v1, json-value=v1, json-value-of-a-byte-sequence=v1,
    },
    text#{code-span=v1, whole-number=v1},
    #{object-path=v1, store-file=v1},
}

A store file is a newer object file (a store file of a newer form) when,
and only when, all three of these conditions hold:

1. Its valid path is an object path.
2. The object path of the hash of its content equals its valid path.
3. The JSON value of its content is an object that has the member `v`
   whose value is an integer greater than 1.

### 3.5 Valid object files and broken store files

@term valid-object-file=v1
@cites {
    ontology#{
        encoding=v1, object-kind=v1, object=v1, content-hash=v1,
        content-id=v1,
    },
    data-forms#{line-object=v1, hash=v1},
    #{store-file=v1, store-object-file=v1, newer-object-file=v1},
}

A store file is a valid object file when, and only when, it meets
`store-object-file` and its line object meets its row of
`ontology#object-kind`. The canonical object of a valid object file is
its line object, which is a canonical object of the kind that its member
`kind` names. The content hash of that canonical object is the hash of
the content of that valid object file, and its content id is its object
kind word, `:`, and the first 32 characters of that content hash. A
valid object file is a valid file of `.sinter/` in the sense of
`ontology#encoding`, and the canonical object that it holds is its
canonical object. A store file that is not a valid object file is not a
valid file of `.sinter/`.

A store file is a broken store file when, and only when, it is neither a
valid object file nor a newer object file.

### 3.6 Needed identity files

@term needed-identity-file=v1
@cites {
    ontology#{
        object=v1, object-kind=v1, computed-identity=v1,
        declared-item=v1, content-id=v1, edge=v1,
    },
    data-forms#{json-value=v1},
    text#{code-span=v1, text=v1},
    #{object-path=v1, valid-object-file=v1},
}

Let O be a canonical object of an object kind that
`ontology#object-kind` marks as allowed in `.sinter/`, and let c be a
content id whose object kind word is one of the five computed identity
kinds (`name`, `pin`, `ext`, `vector-set`, and `vector-group`).

An identity file is a valid object file whose canonical object is a
computed identity object. The identity file for c (and, when I is the
computed identity object with content id c, the identity file of I) is a
valid object file whose canonical object is the computed identity object
with content id c.

O holds the key of c itself when, and only when, O is a declared-item
object (its member `kind` is one of `design`, `spec`, `schema`, `req`,
`atom`, `term`, and `decision`) and c is the content id of the `name`
computed identity object whose member `name` equals the member `name` of
O.

O needs the identity file for c (and needs the computed identity object
c) when, and only when, O holds at least one edge in its member `edges`
whose member `to` equals c, and O does not hold the key of c itself.
When I is a computed identity object whose content id is c, O needs I
(and needs the identity file of I) when, and only when, O needs the
identity file for c.

### 3.7 The object store of a tree

@term tree-object-store=v1
@cites {
    conformance#{
        requirement=v1, encoding=v1, input=v1, dependence=v1,
        object=v1, own-store=v1,
    },
    ontology#{
        tree=v1, encoding=v1, object=v1, object-kind=v1,
        computed-identity=v1, content-id=v1, declared-item=v1,
    },
    text#{code-span=v1},
    #{store-file=v1, valid-object-file=v1, needed-identity-file=v1},
}

The object store of a tree is the set of all store files of that tree.
Local files of that tree and files outside `.sinter/` are not members of
the object store of that tree.

In the sense of `conformance#encoding` and `ontology#encoding`, the
object store of a tree is one input in the `.sinter/` encoding for
objects of the twenty-two kinds that `ontology#object-kind` marks as
allowed in `.sinter/`. The object store of a tree is valid when, and
only when, every store file of that tree is a valid object file. A tree
with zero store files has a valid object store. When the object store of
a tree is valid, the canonical objects that the object store of that
tree holds are the canonical objects of its store files, each once, and
no other object.

When the object store of a tree is valid, a computed identity object
with content id c is missing from the object store of that tree when at
least one valid object file of that tree has a canonical object that
needs the identity file for c and no valid object file of that tree has
a canonical object whose content id is c. Such an absent computed
identity object does not make the object store of that tree not valid;
it is a part that a valid object store of a tree can lack under
`conformance#input`. An input gives a computed identity object I when it
holds I. An input gives the key of I when it holds, in the text
encoding, a key from which I derives (`ontology#encoding`), or when I is
a `name` object and the input holds a declared-item object whose member
`name` equals the member `name` of I; no other member, such as the
member `name` of a `plan-def` or of a `pin` object, gives a key. A thing
that a requirement obliges needs such an absent computed identity object
I, as a part of the object store of that tree, when, and only when, that
thing needs the key of I and no valid input of the run (neither the
object store of that tree, nor any other valid encoding input, nor a
valid program's own store) gives I or its key.

### 3.8 Findings of the class `invalid-object-file`

@atom invalid-object-file-finding=v1
@cites {
    findings#{
        finding-part=v1, finding-subject=v1, spot=v1, message=v1,
        mark=v1, related-message=v1, fix=v1, ackable-finding=v1,
        path-finding-subject=v1,
    },
    files#{path=v1},
    ontology#{finding-class=v1, tree=v1},
    #{store-file=v1, valid-object-file=v1, newer-object-file=v1},
}

A tree has one tree finding of the class `invalid-object-file` for each
store file of the tree that is not a valid object file, and no other
finding of that class. The finding has these parts:

- its tree is that tree;
- its finding class is `invalid-object-file`;
- its subject is the path-finding subject (term `path-finding-subject`
  of Findings) of the valid path of that store file;
- its spot is the valid path of that store file alone, with no span;
- it has no mark and no fix, and it is not ackable;
- its message says what is wrong (stating that the file has a newer form
  when that store file is a newer object file, and not stating that the
  file has a newer form when that store file is a broken store file);
- its related messages are those that the program gives.

### 3.9 Findings of the class `missing-identity-file`

@atom missing-identity-file-finding=v1
@cites {
    findings#{
        finding-part=v1, finding-subject=v1, spot=v1, message=v1,
        mark=v1, related-message=v1, fix=v1, ackable-finding=v1,
        path-finding-subject=v1,
    },
    files#{path=v1},
    text#{space=v1, code-span=v1},
    ontology#{
        finding-class=v1, tree=v1, content-id=v1, computed-identity=v1,
    },
    #{valid-object-file=v1, needed-identity-file=v1},
}

A tree has one tree finding of the class `missing-identity-file` for
each pair of a valid object file F of the tree and a content id c of one
of the five computed identity kinds such that the canonical object of F
needs the identity file for c and no valid object file of the tree has a
canonical object whose content id is c, and no other finding of that
class. The finding has these parts:

- its tree is that tree;
- its finding class is `missing-identity-file`;
- its subject is the path-finding subject (term `path-finding-subject`
  of Findings) of the valid path of F, then a space, then c;
- its spot is the valid path of F alone, with no span;
- it has no mark and no fix, and it is not ackable;
- its message says what is wrong;
- its related messages are those that the program gives.

## 4. Requirements

### 4.1 Validation of object paths

@req validate-object-paths=v1
@cites {
    conformance#{conforming-program=v1},
    text#{text=v1, result=v1},
    #{object-path=v1},
}

For each text, when a conforming program gives a result for whether that
text is an object path, the conforming program must give exactly one
result: "valid" when that text is an object path, and "invalid" when
that text is not an object path.

### 4.2 Validation of store object files

@req validate-store-object-files=v1
@cites {
    conformance#{conforming-program=v1},
    files#{path=v1},
    text#{byte-sequence=v1, result=v1},
    #{store-file=v1, store-object-file=v1},
}

For each store file (a store path and a byte sequence), when a
conforming program gives a result for whether that store file meets
`store-object-file`, the conforming program must give exactly one
result: "valid" when that store file meets `store-object-file`, and
"invalid" when that store file does not meet `store-object-file`.

### 4.3 The canonical objects of a tree's object store

@req give-store-objects=v1
@cites {
    conformance#{
        conforming-program=v1, input=v1, reject-invalid-inputs=v1,
        encoding=v1,
    },
    ontology#{tree=v1, object=v1, content-id=v1},
    #{store-file=v1, valid-object-file=v1, tree-object-store=v1},
}

When the object store of a tree is valid, and a conforming program gives
the canonical objects of the object store of that tree, the conforming
program must give once the canonical object of each store file of that
tree, and no other object, and must give no object from any local file
inside `.sinter/local/`. When a conforming program gives a text as the
content id of a canonical object of the object store of a tree, the
conforming program must give the content id of that canonical object,
and no other text.

When the object store of a tree is not valid, a conforming program must
give no canonical object of the object store of that tree.

### 4.4 The findings of a tree's object store

@req give-store-findings=v1
@cites {
    conformance#{
        requirement=v1, conforming-program=v1, input=v1, dependence=v1,
        report=v1, reject-invalid-inputs=v1, report-missing-parts=v1,
    },
    ontology#{finding-class=v1, tree=v1},
    findings#{finding-part=v1, message=v1},
    #{
        tree-object-store=v1, store-file=v1, valid-object-file=v1,
        newer-object-file=v1, invalid-object-file-finding=v1,
        missing-identity-file-finding=v1,
    },
}

Whether or not the object store of a tree is valid, when a conforming
program gives the findings of that tree of the class
`invalid-object-file`, the conforming program must give once each tree
finding of the class `invalid-object-file` that the tree has, and no
other finding of that class. For each such finding whose store file is a
newer object file, the message of that finding must state that the file
has a newer form; for each such finding whose store file is a broken
store file, the message of that finding must not state that the file has
a newer form. When the object store of a tree is not valid, these
findings are the report of the invalid object store under
`conformance#reject-invalid-inputs`.

Whether or not the object store of a tree is valid, when a conforming
program gives the findings of that tree of the class
`missing-identity-file`, the conforming program must give once each tree
finding of the class `missing-identity-file` that the tree has, and no
other finding of that class. When a thing that a requirement obliges
needs a computed identity object that a valid object store of a tree
lacks, these findings are the report of this design for that missing
part under `conformance#report-missing-parts`.

### 4.5 Writing object files

@req write-object-files=v1
@cites {
    conformance#{requirement=v1, conforming-program=v1, input=v1},
    files#{
        system=v1, folder=v1, folder-tree=v1, regular-file=v1,
        symbolic-link=v1, file-of-another-kind=v1, path=v1, path-file=v1,
    },
    data-forms#{canonical-byte-sequence=v1},
    ontology#{
        tree=v1, object=v1, object-kind=v1, computed-identity=v1,
        content-id=v1,
    },
    text#{byte-sequence=v1, code-span=v1, whole-number=v1},
    #{
        object-path=v1, store-file=v1, valid-object-file=v1,
        tree-object-store=v1, needed-identity-file=v1,
    },
}

Whether or not the object store of a working tree is valid, when a
conforming program writes a canonical object O of an object kind that
`ontology#object-kind` marks as allowed in `.sinter/` to the object
store of that working tree, the conforming program must satisfy these
conditions in the folder tree of that working tree, where the
two-hex-digit subfolder of the object path of O is the file that file
name 2 of the object path of O names (`files#path-file`):

1. When neither `.sinter` nor the two-hex-digit subfolder of the object
   path of O is a regular file, a symbolic link, or a file of another
   kind, no folder entry stands at the object path of O, and neither
   condition 4 nor another requirement of this design forbids writing a
   file for O, the conforming program must write the canonical byte
   sequence of O (with no member `id` and no final line feed) as a
   regular file at the object path of O, creating `.sinter` and that
   two-hex-digit subfolder when absent. When the system refuses that
   write or does not complete it (for example for a missing write
   permission, a read-only file system, a full disk, or an input or
   output error), the conforming program must instead give one notice
   identifying that it could not write O (in any form that identifies
   that fact, such as a text, a structured output, an exit status, or an
   error value), and no other notice for that failed write.
2. When `.sinter` and the two-hex-digit subfolder of the object path of
   O are folders, and a regular file already stands at the object path
   of O whose content equals the canonical byte sequence of O, the
   conforming program must leave that regular file unchanged and must
   give no notice that it could not write O.
3. When `.sinter` or the two-hex-digit subfolder of the object path of O
   is a regular file, a symbolic link, or a file of another kind, or
   when `.sinter` and that subfolder are folders and either a regular
   file holding a byte sequence different from the canonical byte
   sequence of O or a symbolic link, a folder, or a file of another kind
   stands at the object path of O, the conforming program must change
   nothing at that blocking path, must write no file for O, and must
   give one notice identifying that it could not write O, and no other
   notice for that failed write.
4. When a conforming program writes one or more objects to the object
   store of a working tree in one run, whether the write succeeds or
   fails part of the way, the conforming program must leave no newly
   written store file in `.sinter/` of that working tree whose canonical
   object needs an identity file for which no valid object file exists
   in the folder tree of that working tree at the end of that run. When
   condition 4 or another requirement of this design forbids a write of
   O that condition 1 would otherwise require, the conforming program
   must write no file for O and must give one notice identifying that it
   could not write O, and no other notice for that failed write.

### 4.6 Write boundary in `.sinter/`

@req limit-store-writes=v1
@cites {
    conformance#{conforming-program=v1, safety-obligation=v1},
    files#{folder=v1, folder-tree=v1, symbolic-link=v1},
    ontology#{tree=v1},
    text#{utf-8-encoding=v1, code-span=v1},
    #{store-file=v1},
}

When a conforming program writes a file in the folder `.sinter/` of the
folder tree of a working tree (a store file or a local file inside
`.sinter/local/`), the conforming program must write and alter nothing
outside that folder by that write, other than creating the folder
`.sinter` in the root of that folder tree when that root holds no folder
entry whose entry name is the UTF-8 encoding of `.sinter`, and must
follow no symbolic link in that write.

### 4.7 Existing store files stay unchanged

@req keep-store-files-unchanged=v1
@cites {
    conformance#{conforming-program=v1, safety-obligation=v1},
    files#{folder-tree=v1, regular-file=v1},
    ontology#{tree=v1},
    #{store-file=v1, valid-object-file=v1},
}

A conforming program must never change the content of an existing store
file in the folder tree of a working tree, whether or not the store file
formed by its store path and its content is a valid object file.

### 4.8 No write in `.sinter/` after a stop

@req write-no-file-after-stop=v1
@cites {
    conformance#{
        conforming-program=v1, safety-obligation=v1, own-limit=v1,
    },
    files#{folder=v1, folder-tree=v1},
    ontology#{tree=v1},
    text#{code-span=v1},
}

When a conforming program reaches a limit of its own in a run, that
conforming program must write no further file in the folder `.sinter/`
of any working tree in that run, the folder `.sinter/local/` included.

### 4.9 No write in `.sinter/` in a run with a read error

@req write-no-file-after-read-error=v1
@cites {
    conformance#{conforming-program=v1, safety-obligation=v1, input=v1},
    files#{folder=v1, folder-tree=v1},
    ontology#{tree=v1},
    text#{code-span=v1},
}

In a run in which content of a file or a folder is a part that an input
lacks under the term `input` of Conformance because a conforming program
could not take that content, that conforming program must write no file
in the folder `.sinter/` of any working tree, the folder
`.sinter/local/` included.

### 4.10 Deleting files in `.sinter/`

@req limit-store-deletions=v1
@cites {
    conformance#{
        conforming-program=v1, safety-obligation=v1, input=v1,
        own-limit=v1,
    },
    files#{folder=v1, folder-tree=v1, symbolic-link=v1},
    ontology#{tree=v1, object-withdrawal=v1, computed-identity=v1},
    text#{code-span=v1},
    #{
        store-file=v1, valid-object-file=v1, tree-object-store=v1,
        needed-identity-file=v1,
    },
}

When a conforming program deletes a file in the folder `.sinter/` of the
folder tree of a working tree (a store file or a local file inside
`.sinter/local/`), the conforming program must delete nothing outside
that folder by that deletion and must follow no symbolic link in that
deletion. A conforming program must delete a store file only when one of
these two conditions holds:

1. the store file is a valid object file that holds an object that a
   counting void in that tree withdraws (`ontology#object-withdrawal`);
2. every store file of that tree is a valid object file and the store
   file holds a computed identity object that no object of the object
   store of that tree needs.

A conforming program must delete no store file in a run in which content
of a file or a folder is a part that an input lacks under the term
`input` of Conformance because the conforming program could not take
that content. When a conforming program reaches a limit of its own in a
run, that conforming program must delete no further store file in that
run.

## 5. Conformance

A program, or a part of a program, conforms to this design when it is a
[conforming program](sinter:conformance#conforming-program=v1) of this
design: when it meets every requirement of section 4 together with the
general requirements of Conformance.

The conformance vectors of this design are in the file
[`object-store.test-vectors.jsonl`](object-store.test-vectors.jsonl), in
the same folder as this design. The file is a test-vector set, as the
specification [`test-vectors`](sinter:data-forms#test-vectors=v1) of
Data forms defines a test-vector set. Each vector follows from the
requirements and adds nothing to them. The vectors are in three groups,
and each group has a schema below that gives the forms of the group: the
requirements of the group, the inputs, the results, and the values. No
group of this design uses a need, so the forms of each group give no
need names. These operational and safety requirements have no vectors:
`write-object-files`, `limit-store-writes`,
`keep-store-files-unchanged`, `write-no-file-after-stop`,
`write-no-file-after-read-error`, and `limit-store-deletions`.

### 5.1 Object paths

@schema object-path-vector=v1
@cites {
    conformance#{conforming-program=v1},
    text#{text=v1, result=v1, code-span=v1},
    data-forms#{
        json-value=v1, vector-line=v1, group-form-list=v1,
        vector-meaning=v1,
    },
    #{object-path=v1, validate-object-paths=v1},
}

The group `object-paths` holds the vectors of the requirement
`validate-object-paths`. Each vector gives a text and the result for
whether that text is an object path. Inside `input` and `result`, a text
is a JSON string whose characters are the characters of that text, in
order.

- `input`: a JSON object with one member, `path`, the text to test as an
  object path, as a JSON string.
- `result`: the result for whether `path` is an object path, when a
  conforming program gives a result for whether that text is an object
  path: `"valid"` when it is an object path, and `"invalid"` when it is
  not.
- `values`: no fixed form; no vector of the group has the member
  `values`.

When a conforming program gives a result for whether `path` is an object
path, the conforming program gives the result that `result` holds, and
no other result.

```
{"form":"#object-path-vector=v1","group":"object-paths","input":{"path":".sinter/0d/0d000000000000000000000000000000.json"},"note":"valid object path with matching two-digit folder prefix","result":"valid"}
```

### 5.2 Store object files

@schema store-object-file-vector=v1
@cites {
    conformance#{conforming-program=v1},
    files#{path=v1},
    text#{
        text=v1, byte-sequence=v1, valid-utf-8=v1,
        text-of-a-byte-sequence=v1, result=v1, code-span=v1,
    },
    data-forms#{
        json-value=v1, hex-text=v1, vector-line=v1,
        group-form-list=v1, vector-meaning=v1,
    },
    #{
        store-file=v1, store-object-file=v1,
        validate-store-object-files=v1,
    },
}

The group `store-object-files` holds the vectors of the requirement
`validate-store-object-files`. Each vector gives a store file (a store
path and a content byte sequence) and the result for whether that store
file meets `store-object-file`.

Inside `input`, a byte sequence has this form: when the byte sequence is
valid UTF-8, it is the text of that byte sequence, as a JSON string;
when the byte sequence is not valid UTF-8, it is a JSON object with one
member, `bytes`, holding the [hex text](sinter:data-forms#hex-text=v1)
of that byte sequence, as a JSON string, such as `{"bytes":"ff"}`.

- `input`: a JSON object with two members: `path`, the store path of the
  store file, as a JSON string; and `content`, the content byte sequence
  of the store file.
- `result`: the result for whether the store file meets
  `store-object-file`, when a conforming program gives a result for
  whether that store file meets `store-object-file`: `"valid"` when it
  meets `store-object-file`, and `"invalid"` when it does not.
- `values`: no fixed form; no vector of the group has the member
  `values`.

When a conforming program gives a result for whether the store file
meets `store-object-file`, the conforming program gives the result that
`result` holds, and no other result.

```
{"form":"#store-object-file-vector=v1","group":"store-object-files","input":{"content":"{\"kind\":\"req\",\"v\":1}","path":".sinter/3f/3fc66a77d784ac3747f1b6371d9f30cd.json"},"note":"minimal store object file passes store-object-file even without req members","result":"valid"}
```

### 5.3 The object store of a tree

@schema tree-store-vector=v1
@cites {
    conformance#{conforming-program=v1},
    files#{path=v1},
    text#{
        text=v1, byte-sequence=v1, valid-utf-8=v1,
        text-of-a-byte-sequence=v1, code-point-order=v1, code-span=v1,
    },
    data-forms#{
        json-value=v1, hex-text=v1, line-object=v1, vector-line=v1,
        group-form-list=v1, vector-meaning=v1,
    },
    ontology#{tree=v1, object=v1, content-id=v1, finding-class=v1},
    findings#{
        finding-part=v1, finding-subject=v1, spot=v1, message=v1,
        mark=v1, fix=v1, ackable-finding=v1,
    },
    #{
        store-object-file-vector=v1, tree-object-store=v1,
        newer-object-file=v1, invalid-object-file-finding=v1,
        missing-identity-file-finding=v1, give-store-objects=v1,
        give-store-findings=v1,
    },
}

The group `tree-stores` holds the vectors of the requirements
`give-store-objects` and `give-store-findings`. Each vector gives a tree
and what a conforming program gives for the canonical objects and
findings of the classes `invalid-object-file` and
`missing-identity-file` of that tree.

Inside `input`, a tree is a JSON object with one member for each file of
the tree: the key is the valid path of the file, and the value is the
content byte sequence of that file in the byte-sequence form that
`store-object-file-vector` gives.

- `input`: a JSON object with one member, `files`, the tree.
- `result`: no question; no vector of the group has the member `result`.
- `values`: a JSON object with the member `findings` and, when the
  object store of the tree is valid, the member `objects` (and no other
  member).
  - `findings` is a JSON array holding one JSON object for each tree
    finding of the classes `invalid-object-file` and
    `missing-identity-file` that the tree has, sorted in code point
    order of `class` and then in code point order of `subject`. Each
    element has `class` (`"invalid-object-file"` or
    `"missing-identity-file"`), `subject` (the subject text, as a JSON
    string), and `spot` (a JSON object `{"path":<valid path>}`, standing
    for that valid path alone with no span). Each element whose `class`
    is `"invalid-object-file"` also has the boolean member `newer-form`:
    `true` when the store file is a newer object file, and `false` when
    it is a broken store file. Each element whose `class` is
    `"missing-identity-file"` has no `newer-form` member.
  - `objects`, present when and only when the object store of the tree
    is valid, is a JSON object with one member for each canonical object
    of the object store of the tree: the key is the content id of that
    object, and the value is that canonical object as a JSON object.

When `objects` is present in `values`, a conforming program that gives
the canonical objects of the object store of the tree gives once each
canonical object in `objects` with its key as its content id, and no
other object. When `objects` is absent from `values`, the object store
of the tree is not valid, and a conforming program gives no canonical
object of the object store of the tree. When a conforming program gives
the findings of the tree of the class `invalid-object-file` or
`missing-identity-file`, it gives once each finding of that class in
`findings`, and no other finding of that class; each such finding is not
ackable and has no mark and no fix; and for each `invalid-object-file`
finding, the message states that the file has a newer form when and only
when `newer-form` is `true`.

```
{"form":"#tree-store-vector=v1","group":"tree-stores","input":{"files":{".sinter/f6/f6259f147d032738f64394a0796087a3.json":"{\"edges\":[{\"kind\":\"about\",\"to\":\"name:0f17c8dd86ac60f052972d0be8ace0c2\"}],\"kind\":\"req\",\"label\":\"v1\",\"name\":\"billing#cap\",\"text\":\"Limit amounts.\",\"v\":1}"}},"note":"declared item in .sinter/ holds its own name key and needs no name identity file","values":{"findings":[],"objects":{"req:f6259f147d032738f64394a0796087a3":{"edges":[{"kind":"about","to":"name:0f17c8dd86ac60f052972d0be8ace0c2"}],"kind":"req","label":"v1","name":"billing#cap","text":"Limit amounts.","v":1}}}}
```
