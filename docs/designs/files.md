<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Files and paths
@design files=v1
@cites {
    conformance=v1, text=v1, rfc/5234, rfc/7405, rfc/8259, posix/2024,
}
Valid paths name files in directory trees, globs and path sets match and select valid paths, and safe file reads resolve valid paths in directory trees to UTF-8 text without following symbolic links or modifying the directory tree.

A directory tree holds a root directory and the files under that root,
and valid paths name files in that tree. Globs, such as `docs/**/*.md`,
and path sets, such as `docs/` followed by `!docs/old/`, select valid
paths. Reading a valid path in a directory tree resolves its path
segments from the root directory and decodes a regular file's content as
UTF-8 text.

## Valid paths

@spec paths=v1

A valid path, such as `docs/guide/a.md`, names a file in a directory
tree as a sequence of path segments joined by `/`.

### Definitions

#### Valid path

@term path=v1
@cites text#{text=v1, production=v1}

A **valid path** is a `text` that matches the `production` `path`:

```
path          = path-segment *( "/" path-segment )
path-segment  = *"." non-dot *name-char / 3*"."
name-char     = %x1-2E / %x30-D7FF / %xE000-10FFFF
non-dot       = %x1-2D / %x30-D7FF / %xE000-10FFFF
```

A valid path consists of a sequence of **path segments**: the `text`
values that its `path-segment` elements match, in order. Each path
segment has a 1-based number. Path segment 1 is the first element of
that sequence, and each later path segment has a number 1 greater than
the preceding path segment.

@example Valid and invalid [text](sinter:text#text=v1) values under this
definition:

| text | valid path | reason |
|---|---|---|
| `docs/guide/a.md` | yes | three path segments: `docs` (1), `guide` (2), and `a.md` (3) |
| `.github/workflows/ci.yml` | yes | a path segment can start with `.` |
| `...` | yes | three or more dots form a valid path segment |
| `..a` | yes | dots followed by a non-dot character form a valid path segment |
| `a b/c\d.md` | yes | space and `\` are ordinary characters; `/` is the only separator |
| `a/a` | yes | two path segments can hold the same text (`a` at 1 and `a` at 2) |
| empty text | no | a valid path holds at least one path segment |
| `/a.md`, `docs/`, `docs//a.md` | no | a leading, trailing, or doubled `/` leaves an empty text where a path segment stands |
| `.`, `./a.md`, `docs/../a.md` | no | `.` and `..` are not path segments |
| the text of `a`, U+0000, and `.md` | no | a path segment holds no U+0000 |

Because a valid path is a [text](sinter:text#text=v1), `Docs/A.MD` and
`docs/a.md` are distinct valid paths. For the same reason, a path that
holds U+00E9 is distinct from a path that holds `e` followed by U+0301.

### Validating paths

@req validate-paths=v1
@cites {conformance#conforming-program=v1, text#text=v1, #{path=v1}}

When a conforming program validates a `text` as a path, the program must
return `"valid"` when the text is a valid `path`, and must return
`"invalid"` otherwise.

### Test vectors

@schema path-vector=v1
@cites {#{vector-line=v1, validate-paths=v1, path=v1}, text#text=v1}

Group `paths` in [files.test-vectors.jsonl](files.test-vectors.jsonl)
tests `validate-paths`. Each line conforms to `vector-line` and omits
`needs` and `values`.

| field | type | meaning |
|---|---|---|
| `input` | string | `text` to validate as a path |
| `result` | string | `"valid"` when `input` is a valid `path`, `"invalid"` otherwise |

@example Sample lines testing [validate-paths](sinter:#validate-paths=v1)
on valid and invalid [path](sinter:#path=v1) inputs
([vector-line](sinter:#vector-line=v1)):

```
{"form":"#path-vector=v1","group":"paths","input":"docs/guide/a.md","result":"valid"}
{"form":"#path-vector=v1","group":"paths","input":"docs/../a.md","note":"`..` is not a path segment","result":"invalid"}
```

## Globs

@spec globs=v1

A glob, such as `docs/**/*.md`, is a pattern for valid paths. The
wildcard `*` matches characters within one path segment. The wildcard
`**` matches whole path segments.

### Definitions

#### Valid glob

@term glob=v1
@cites text#{character=v1, text=v1, production=v1}

A **valid glob** is a text that matches the production `glob`:

```
glob           = glob-segment *( "/" glob-segment ) [ "/" ]
glob-segment   = "**" / star-segment / plain-segment
star-segment   = *glob-char "*" *( 1*glob-char "*" ) *glob-char
plain-segment  = *"." glob-non-dot *glob-char / 3*"."
glob-char      = %x0-29 / %x2B-2E / %x30-3E / %x40-5A / %x5E-7A / %x7C
               / %x7E-D7FF / %xE000-10FFFF
glob-non-dot   = %x0-29 / %x2B-2D / %x30-3E / %x40-5A / %x5E-7A / %x7C
               / %x7E-D7FF / %xE000-10FFFF
```

The production `glob-char` matches every character except `*`, `/`, `?`,
`[`, `\`, `]`, `{`, and `}`. Both U+0000 and `!` match `glob-char`. The
production `glob-non-dot` matches every `glob-char` except `.`.

The **glob segments** of a valid glob are the texts that its `glob-segment`
elements match, in order, with one additional glob segment `**` at the end
when the valid glob ends with `/`. The glob segments of a valid glob have
1-based numbers from 1 to `m` in that order, where `m` is the number of
glob segments.

@example Valid and invalid [texts](sinter:text#text=v1) as globs:

- Valid: `docs/**/*.md` (glob segments 1: `docs`, 2: `**`, 3: `*.md`);
  `docs/` (glob segments 1: `docs`, 2: `**`); `**/` (glob segments 1:
  `**`, 2: `**`); `a*b*c`; `...`; `!x`; and the text of `a`, U+0000,
  and `.md` (the JSON string `"a\u0000.md"`).
- Invalid: the empty text; `/docs`; `docs//a.md`; `./a.md`; `docs/..`;
  `src/**.ts`; `***`; `a?.md`; `[ab].md`; `{a,b}.md`; and `a\b`.

#### Glob match

@atom glob-match=v1
@cites {
    text#{character=v1, text=v1, slice=v1},
    #{path=v1, glob=v1},
}

Let a valid glob have `m` glob segments, numbered from 1 to `m`. A valid
path **matches** the valid glob when its path segments divide into `m`
contiguous groups (group 1 through group `m`, whose path segments in order
form the path segments of the valid path) such that each group `i`
satisfies the rule for glob segment `i`:

- When glob segment `i` is `**` and `i = m` (the last glob segment), group
  `i` holds one or more path segments.
- When glob segment `i` is `**` and `i < m` (not the last glob segment),
  group `i` holds zero or more path segments.
- When glob segment `i` is not `**`, group `i` holds one path segment, and
  that path segment matches glob segment `i`.

Let a glob segment `g` other than `**` have `k` characters, at 1-based
character indices 1 to `k`. A path segment `s` of `n` characters
**matches** `g` when `s` divides into `k` slices (slice 1 through slice
`k`, one slice for each 1-based character index `j` of `g`) that meet all
of these conditions:

- Slice 1 starts at boundary 0. For each `j` from 2 to `k`, slice `j`
  starts at the end boundary of slice `j - 1`. Slice `k` ends at boundary
  `n`.
- When the character at 1-based character index `j` of `g` is `*`, slice
  `j` holds zero or more characters.
- When the character at 1-based character index `j` of `g` is a character
  `c` other than `*`, slice `j` holds one character, and that character
  equals `c`.

Character comparison is exact: letter case matters, and no Unicode
normalization applies. A leading `.` in a path segment has no special
treatment under `*` or `**`.

For a valid path and a valid glob, the `glob-match` outcome is `"matches"`
when the valid path matches the valid glob, and `"does not match"`
otherwise.

@example Matches of [valid paths](sinter:#path=v1) against
[valid globs](sinter:#glob=v1), including trailing `/` expansion, non-final
`**` with zero path segments, final `**` with one or more path segments,
leading `.` under `*`, and exact letter case:

| valid glob | matching valid paths | non-matching valid paths |
|---|---|---|
| `docs/` | `docs/a.md`; `docs/a/b.md` | `docs` |
| `docs/**` | `docs/a.md`; `docs/a/b.md` | `docs` |
| `a/**/b` | `a/b`; `a/x/y/b` | `b`; `a/b/c` |
| `**/x/**` | `x/a`; `a/x/b` | `x`; `a/x` |
| `*.md` | `a.md`; `.md` | `a/b.md` |
| `Docs/*` | `Docs/a.md` | `docs/a.md` |

### Validating globs

@req validate-globs=v1
@cites {
    conformance#conforming-program=v1,
    text#text=v1,
    #{glob=v1},
}

When a conforming program validates a text as a glob, the program must
return `"valid"` when the text is a valid glob, and must return `"invalid"`
otherwise.

### Matching globs

@req match-globs=v1
@cites {
    conformance#conforming-program=v1,
    #{path=v1, glob=v1, glob-match=v1},
}

When a conforming program matches a valid path against a valid glob, the
program must return the `glob-match` outcome for that valid path and
that valid glob.

### Test vectors

Test vectors for `globs` live in
[files.test-vectors.jsonl](files.test-vectors.jsonl).

#### Valid globs

@schema glob-vector=v1
@cites {text#text=v1, #{vector-line=v1, validate-globs=v1, glob=v1}}

Group `globs` tests `validate-globs`. Each line conforms to `vector-line`
and omits `needs` and `values`.

| field | type | meaning |
|---|---|---|
| `input` | string | candidate `text` to validate as a glob |
| `result` | string | `"valid"` when `input` is a valid `glob`, `"invalid"` otherwise |

@example Sample lines testing [validate-globs](sinter:#validate-globs=v1)
on valid and invalid [glob](sinter:#glob=v1) inputs
([vector-line](sinter:#vector-line=v1)):

```
{"form":"#glob-vector=v1","group":"globs","input":"docs/**/*.md","result":"valid"}
{"form":"#glob-vector=v1","group":"globs","input":"src/**.ts","note":"`**` in a glob segment that holds other characters too","result":"invalid"}
```

#### Glob matching

@schema glob-match-vector=v1
@cites #{
    vector-line=v1, match-globs=v1, path=v1, glob=v1, glob-match=v1,
}

Group `matches` tests `match-globs`. Each line conforms to `vector-line`
and omits `needs` and `values`.

| field | type | meaning |
|---|---|---|
| `input.glob` | string | valid `glob` |
| `input.path` | string | valid `path` |
| `result` | string | `glob-match` outcome: `"matches"` or `"does not match"` |

@example Sample lines testing [match-globs](sinter:#match-globs=v1) with
[glob-match](sinter:#glob-match=v1) on a [glob](sinter:#glob=v1) and two
[path](sinter:#path=v1) inputs ([vector-line](sinter:#vector-line=v1)):

```
{"form":"#glob-match-vector=v1","group":"matches","input":{"glob":"docs/**","path":"docs/a/b.md"},"result":"matches"}
{"form":"#glob-match-vector=v1","group":"matches","input":{"glob":"docs/**","path":"docs"},"result":"does not match"}
```

## Path sets

@spec path-sets=v1

A single glob cannot express exclusions on its own. A path set lists
globs that select valid paths and globs, each marked with a leading `!`,
that exclude valid paths.

### Definitions

#### Path set

@term path-set=v1
@cites {#{glob=v1}, text#{character=v1, text=v1, slice=v1}}

A **path set** is a finite sequence of texts. Each text in a path set is
a **path set member**. A path set member is a **`!` member** when its
character at 1-based character index 1 is `!` (U+0021). The **glob text**
of a `!` member of `n` characters is the text of its slice `(1, n)`.
Every other path set member is a **plain member**. The glob text of a
plain member is that plain member itself.

A path set is **valid** when all three of these conditions hold:

- The glob text of each path set member is a valid glob (`glob`).
- No two path set members are equal texts.
- When the path set holds at least one path set member, at least one
  path set member is a plain member.

Otherwise, the path set is **invalid**.

#### Set of a path set

@atom path-set-membership=v1
@cites #{path=v1, glob-match=v1, path-set=v1}

For a valid path set, a valid path is **in the set** of that path set
when the valid path meets both of these conditions:

- The valid path matches (under `glob-match`) the glob text of at least
  one plain member of that path set.
- The valid path matches (under `glob-match`) the glob text of no `!`
  member of that path set.

An invalid path set defines no set of valid paths.

For a valid path and a valid path set, the `path-set-membership` outcome
is `"in the set"` when the valid path is in the set of that path set,
and `"not in the set"` otherwise.

@example Under [glob](sinter:#glob=v1) and
[glob match](sinter:#glob-match=v1), for the valid
[path set](sinter:#path-set=v1) with members `docs/` and `!docs/old/`
(in either order), the valid [path](sinter:#path=v1) `docs/a.md` has
outcome `"in the set"`. The valid paths `docs/old/a.md` and `a.md` have
outcome `"not in the set"`.

### Validating path sets

@req validate-path-sets=v1
@cites {conformance#conforming-program=v1, #{path-set=v1}}

When a conforming program validates a path set, the program must return
`"valid"` when the path set is valid, and must return `"invalid"`
otherwise.

### Deciding path-set membership

@req decide-path-set-membership=v1
@cites {
    conformance#conforming-program=v1,
    #{path=v1, path-set=v1, path-set-membership=v1},
}

When a conforming program decides whether a valid path is in the set of
a valid path set, the program must return the `path-set-membership`
outcome for that valid path and that valid path set.

### Test vectors

Test vectors for `path-sets` live in
[files.test-vectors.jsonl](files.test-vectors.jsonl).

#### Valid path sets

@schema path-set-vector=v1
@cites {
    #{vector-line=v1, validate-path-sets=v1, path-set=v1},
    text#text=v1,
}

Group `path-sets` tests `validate-path-sets`. Each line conforms to
`vector-line` and omits `needs` and `values`.

| field | type | meaning |
|---|---|---|
| `input` | array of strings | `path-set`, holding its path set member `text` values in order (`[]` for the empty path set) |
| `result` | string | `"valid"` when `input` is a valid `path-set`, `"invalid"` otherwise |

@example Sample lines testing
[validate-path-sets](sinter:#validate-path-sets=v1) on valid and invalid
[path sets](sinter:#path-set=v1) ([vector-line](sinter:#vector-line=v1)):

```
{"form":"#path-set-vector=v1","group":"path-sets","input":["docs/","!docs/old/"],"result":"valid"}
{"form":"#path-set-vector=v1","group":"path-sets","input":["!docs/"],"note":"no plain member","result":"invalid"}
```

#### Path-set membership

@schema membership-vector=v1
@cites {
    #{
        vector-line=v1, decide-path-set-membership=v1, path=v1,
        path-set=v1, path-set-membership=v1,
    },
    text#text=v1,
}

Group `memberships` tests `decide-path-set-membership`. Each line
conforms to `vector-line` and omits `needs` and `values`.

| field | type | meaning |
|---|---|---|
| `input.path` | string | valid `path` to test |
| `input.path-set` | array of strings | valid `path-set`, holding its path set member `text` values in order (`[]` for the empty path set) |
| `result` | string | `"in the set"` when `input.path` is in the set of `input.path-set` (`path-set-membership`), `"not in the set"` otherwise |

@example Sample lines testing
[decide-path-set-membership](sinter:#decide-path-set-membership=v1) with
[path-set-membership](sinter:#path-set-membership=v1),
[path](sinter:#path=v1), and [path-set](sinter:#path-set=v1)
([vector-line](sinter:#vector-line=v1)):

```
{"form":"#membership-vector=v1","group":"memberships","input":{"path":"docs/a.md","path-set":["docs/","!docs/old/"]},"result":"in the set"}
{"form":"#membership-vector=v1","group":"memberships","input":{"path":"docs/old/a.md","path-set":["!docs/old/","docs/"]},"result":"not in the set"}
```

## Safe file reads

@spec file-reads=v1

Reading a file by a valid path inside a directory tree resolves path
segments from a root directory and decodes a regular file's bytes as
UTF-8 text. A directory tree can hold directories, regular files,
symbolic links, and files of another kind such as FIFO special files,
under varying POSIX permissions and file-system behaviors.

### Definitions

#### Directory

@term directory=v1
@cites {
    posix/2024,
    text#{byte-sequence=v1, text=v1, utf-8-encoding=v1},
}

A **directory** is a file of the POSIX.1-2024 type directory that holds
directory entries. Each **directory entry** pairs an **entry name** (a
`byte-sequence`) with a file. No two directory entries of one directory
share the same entry name. A directory **holds** a file when, and only
when, that file is the file of a directory entry of that directory.

For a program, the **listing** of a directory is the set of
directory-entry names that the file system storing that directory would
supply to the program's process if that process held POSIX.1-2024 read
permission for that directory. The directory entries of a directory are
the POSIX.1-2024 directory entries whose names appear in its listing,
excluding any entry whose name is the `utf-8-encoding` of `.` or `..`.

The **file of a directory entry** is the file that the file system finds
for that entry name in that directory, as in POSIX.1-2024 pathname
resolution that does not follow a symbolic link. Thus, the file of a
directory entry can be a symbolic link.

#### Directory tree

@term directory-tree=v1
@cites #{directory=v1}

A **directory tree** is a `directory`—its **root**—together with the
file of each directory entry of the root and, recursively, the file of
each directory entry of each directory of the directory tree.

#### File kind

@term file-kind=v1
@cites {posix/2024, #{directory=v1}, text#byte-sequence=v1}

On a POSIX.1-2024 file system, the POSIX.1-2024 file type of each file
places that file into one of four kinds:

| kind | POSIX.1-2024 file type | what the file holds |
|---|---|---|
| directory | directory | directory entries (`directory`) |
| **regular file** | regular file | a **content**, which is a `byte-sequence` |
| **symbolic link** | symbolic link | a **reference**, which can lead to a file or to no file |
| **file of another kind** | any other file type (such as a FIFO special file, character special file, block special file, or socket) | file-type-specific data rather than a content, directory entries, or a reference |

#### Bytes read from a file

@term read-byte=v1
@cites {posix/2024, #{directory=v1, file-kind=v1}, text#byte-sequence=v1}

An **attribute** of a file is a property of that file other than the
content of a regular file, the directory entries of a `directory`, the
reference of a symbolic link, and the data of a file of another kind
(for example, the POSIX.1-2024 file type, size, mode, owner, timestamps,
or extended attributes).

A **byte that a program reads from a file** is a byte that the file
holds or supplies and that the program copies into itself from any of
these sources:

- the content of a regular file;
- the directory-entry names of a directory (as POSIX.1-2024 defines
  directory entries);
- the reference of a symbolic link;
- the data of a file of another kind; or
- the value of an extended attribute of the file.

To **read bytes from a file** is to copy one or more such bytes into the
program. Copying any other attribute of a file (such as POSIX.1-2024
file type, size, mode, owner, or timestamps) reads no bytes from that
file.

#### Path resolution

@term path-resolution=v1
@cites {
    #{path=v1, directory=v1, directory-tree=v1},
    text#{byte-sequence=v1, utf-8-encoding=v1},
}

For a valid `path` in a `directory-tree`, **directory 1** is the root of
the directory tree. For each 1-based `path-segment` `k` of the path,
starting from `k = 1`:

- When directory `k` exists and holds a directory entry whose entry name
  equals the `utf-8-encoding` of path segment `k` (byte for byte), path
  segment `k` **names** the file of that directory entry.
- When path segment `k` names a file, that file is a `directory`, and
  path segment `k` is not the last path segment of the path, that
  directory is **directory `k + 1`**.

A file system that ignores letter case, Unicode normalization
differences, or trailing spaces does not cause a path segment to name a
directory entry whose entry name in the directory's listing differs in
bytes.

The **files of the path** are the root of the directory tree and each
file that a path segment of the path names in the directory tree. The
**directories of the path** are the directories `k` that exist for the
path in the directory tree.

@example Suppose the root of a
[directory tree](sinter:#directory-tree=v1) holds only a
[regular file](sinter:#file-kind=v1) whose
[directory entry](sinter:#directory=v1) has the entry name `a.md` (the
[UTF-8 encoding](sinter:text#utf-8-encoding=v1) `0x61 0x2E 0x6D 0x64`).
Even on a file system that ignores letter case, the valid
[path](sinter:#path=v1) `A.md` names no file in the root because the
listing of the root holds no entry name equal to `0x41 0x2E 0x6D 0x64`.
Therefore, the files of the path `A.md` are only the root.

#### File-read result

@atom file-read-result=v1
@cites {
    posix/2024,
    conformance#{input=v1, dependence=v1, resource-limit=v1},
    #{
        path=v1, directory=v1, directory-tree=v1, file-kind=v1,
        path-resolution=v1,
    },
    text#{valid-utf-8=v1, utf-8-text=v1, utf-8-encoding=v1},
}

For a valid `path` of `m` path segments in a `directory-tree`, the
**file-read result** for a program is one of six results: `"cannot read"`,
`"no file"`, `"symbolic link"`, `"not a regular file"`, `"not UTF-8"`,
or `"found"` (paired with a `utf-8-text`).

Evaluating each 1-based `path-segment` `k` from `1` to `m` in turn
(using directory `k` and the file named by path segment `k` from
`path-resolution`), the first matching case determines the result:

1. The program lacks POSIX.1-2024 search permission or read permission
   for directory `k`: `"cannot read"`.
2. Directory `k` holds no directory entry whose entry name equals the
   `utf-8-encoding` of path segment `k`: `"no file"`.
3. The file that path segment `k` names is a symbolic link:
   `"symbolic link"`.
4. Path segment `k` is not the last path segment (`k < m`) and the file
   that path segment `k` names is not a `directory`: `"no file"`. (When
   `k < m` and the named file is a directory, evaluation continues with
   path segment `k + 1` in directory `k + 1`.)
5. Path segment `k` is the last path segment (`k = m`) and the file that
   path segment `k` names is a directory or a file of another kind:
   `"not a regular file"`.
6. Path segment `k` is the last path segment (`k = m`) and the file that
   path segment `k` names is a regular file:
   - If the program lacks POSIX.1-2024 read permission for that regular
     file: `"cannot read"`.
   - If the program holds read permission and the content of that
     regular file is not `valid-utf-8`: `"not UTF-8"`.
   - If the program holds read permission and the content of that
     regular file is `valid-utf-8`: `"found"`, paired with the
     `utf-8-text` of that content.

In case 1, the directory entries of directory `k` are a part that the
directory tree lacks for the program (`input`). In case 6, when the
program lacks read permission for the regular file, the content of that
regular file is a part that the directory tree lacks for the program
(`input`). In addition, whenever a part of the directory tree that the
result needs—such as the directory entries of a directory, the file type
of a file, or the content of a regular file—is a part that the directory
tree lacks (`input`), the result is `"cannot read"`. A valid directory
tree can lack any such part.

A bound on the length of a whole POSIX.1-2024 pathname or on the size of
a file is a resource limit, not a missing part. By contrast, a system or
file-system bound on the length of one entry name is not a resource
limit: when the program holds POSIX.1-2024 search permission and read
permission for directory `k` and the `utf-8-encoding` of path segment
`k` exceeds that entry-name bound, directory `k` holds no directory
entry for path segment `k`, and the result is `"no file"`.

#### Directory tree object

@term directory-tree-object=v1
@cites {
    rfc/8259,
    posix/2024,
    #{directory=v1, directory-tree=v1, file-kind=v1},
    text#{
        byte-sequence=v1, decimal-numeral=v1, hex-digit=v1, text=v1,
        utf-8-encoding=v1,
    },
}

A **file object** is a JSON object (RFC 8259) that represents a file and
a program's permissions for that file. A **hex byte sequence** is a JSON
string of two `hex-digit` characters per byte of a `byte-sequence` in
order, high nibble (`byte / 16`) first and low nibble (`byte mod 16`)
second (`""` for the empty byte sequence). **Byte-sequence pieces** are
a JSON array of piece objects, each with two members: `bytes` (a hex
byte sequence) and `times` (a JSON integer `>= 1` written as a
`decimal-numeral`). The represented byte sequence concatenates each
piece's `bytes` repeated `times` times in array order (`[]` for the
empty byte sequence), and two piece arrays that expand to the same byte
sequence represent the same content.

Each file object has a required `type` member naming a POSIX.1-2024 file
type, plus the type-specific member listed for that type:

| `type` | type-specific member | constraints |
|---|---|---|
| `"directory"` | `entries` (JSON array of entry objects) | One entry object per directory entry (`[]` when empty), sorted in ascending lexicographic byte order of entry name (smaller byte first at the first differing byte; shorter prefix first) with no duplicate entry names. Each **entry object** has `name` (hex byte sequence: non-empty, no `0x00`, no `0x2F`, not the `utf-8-encoding` of `.` or `..`) and `file` (a file object). |
| `"regular file"` | `content` (byte-sequence pieces) | Represents the regular file's content byte sequence. |
| `"symbolic link"` | `reference` (hex byte sequence) | Non-empty and holds no `0x00`; resolves as in POSIX.1-2024 pathname resolution relative to the directory that holds the symbolic link. |
| `"FIFO special file"` | none | Represents a POSIX.1-2024 FIFO special file (a file of another kind). |

A file object can also hold up to four optional JSON boolean members,
each present only when its value differs from its default (when absent,
the default applies):

| member | default | allowed `type` values | meaning |
|---|---|---|---|
| `read` | `true` | `"directory"`, `"regular file"`, `"FIFO special file"` | whether the program holds POSIX.1-2024 read permission for the file |
| `search` | `true` | `"directory"` only | whether the program holds POSIX.1-2024 search permission for the directory |
| `write` | `true` | `"directory"`, `"regular file"`, `"FIFO special file"` | whether the program holds POSIX.1-2024 write permission for the file |
| `owned-by-other` | `false` | all four types | whether the POSIX.1-2024 owner user ID of the file differs from the process's effective user ID |

Each file object, entry object, and piece object holds only the members
defined for it, with no other members and no duplicate member names.

A **directory tree object** is a file object whose `type` is
`"directory"` and that is not the `file` member of any entry object. The
**directory tree of a directory tree object** is the `directory-tree`
whose root is the directory that the directory tree object represents;
its files are the files represented by that directory tree object and
the nested file objects within it, and no other files.

A file system **stores the directory tree** of a directory tree object
for a program's process (forming a **stored directory tree** for that
process) while all of these conditions hold:

1. The entire directory tree resides on that file system.
2. The listing of each directory of the directory tree, for that
   program, holds the entry name of each entry object in that
   directory's file object and no other name except `.` and `..`.
3. Each file of the directory tree has the POSIX.1-2024 file type,
   content (for regular files), and reference (for symbolic links)
   specified by its file object.
4. For each file of the directory tree, the owner's POSIX.1-2024 user ID
   differs from the process's effective user ID when, and only when,
   `owned-by-other` for that file object is `true`.
5. For each file other than a symbolic link, the process holds
   POSIX.1-2024 read permission when, and only when, `read` is `true`,
   and POSIX.1-2024 write permission when, and only when, `write` is
   `true`; for each directory, the process holds POSIX.1-2024 search
   permission when, and only when, `search` is `true`.

### Reading files

@req read-file=v1
@cites {
    conformance#{
        conforming-program=v1, input=v1, dependence=v1, report=v1,
        report-missing-parts=v1,
    },
    #{path=v1, directory-tree=v1, file-kind=v1, file-read-result=v1},
    text#text=v1,
}

When reading a `text` as a path in a `directory-tree`, a conforming
program must act as follows:

- When the text is not a valid `path`, the program must return
  `"invalid"`.
- When the text is a valid `path` and no other process modifies the
  directory tree during the read, the program must return the
  `file-read-result` of that path in that directory tree.
- When the result is `"cannot read"`, returning `"cannot read"` once for
  that read is the report under `report-missing-parts` for every part
  that the directory tree lacks and that the result needs.
- Whenever a file read returns any result other than `"found"`, the
  program must return no file content text.

@example A `"found"` [file-read result](sinter:#file-read-result=v1)
carries the [regular file](sinter:#file-kind=v1)'s
[UTF-8 text](sinter:text#utf-8-text=v1) unchanged: bytes
`0xEF 0xBB 0xBF 0x78` keep the leading U+FEFF, bytes
`0x61 0x0D 0x0A 0x62` keep the carriage return, and bytes
`0x65 0xCC 0x81` stay `e` followed by U+0301 rather than U+00E9.

### Following no symbolic links

@req follow-no-symbolic-links=v1
@cites {
    conformance#{conforming-program=v1, safety-obligation=v1},
    #{directory-tree=v1, file-kind=v1},
    text#text=v1,
}

When reading a text as a path in a directory tree, a conforming program
must never follow a symbolic link of the directory tree or resolve any
file through a symbolic link's reference.

### Reading only named files

@req read-only-named-files=v1
@cites {
    conformance#{conforming-program=v1, safety-obligation=v1},
    #{
        path=v1, directory=v1, directory-tree=v1, file-kind=v1,
        read-byte=v1, path-resolution=v1,
    },
    text#text=v1,
}

When reading a valid `path` in a directory tree, a conforming program
must read bytes only from the directories of the path and from the
regular file that the last path segment names. When reading a text that
is not a valid `path`, a conforming program must read no bytes from any
file.

### Avoiding blocking on special files

@req avoid-blocking-on-special-files=v1
@cites {
    conformance#{conforming-program=v1, safety-obligation=v1},
    #{directory-tree=v1, file-kind=v1},
    text#text=v1,
}

When reading a text as a path in a directory tree, a conforming program
must never block on a file of another kind in the directory tree to wait
for another process or a device, such as for a process to open the other
end of a FIFO special file.

### Keeping directory trees unchanged

@req keep-directory-trees-unchanged=v1
@cites {
    posix/2024,
    conformance#{conforming-program=v1, safety-obligation=v1},
    #{directory-tree=v1},
    text#text=v1,
}

When reading a text as a path in a directory tree, a conforming program
must never modify any file of the directory tree, apart from automatic
metadata updates that the file system makes on its own when the program
accesses that file, such as an update to the time of last access.

### Gaining no privileges

@req gain-no-privileges=v1
@cites {
    posix/2024,
    conformance#{conforming-program=v1, safety-obligation=v1},
    #{directory-tree=v1},
    text#text=v1,
}

When reading a text as a path in a directory tree, a conforming program
must use only the POSIX.1-2024 permissions and appropriate privileges
that its process holds without a change by the program.

### Test vectors

@schema file-read-vector=v1
@cites {
    posix/2024,
    conformance#safety-obligation=v1,
    #{
        vector-line=v1, read-file=v1, directory-tree=v1, file-kind=v1,
        file-read-result=v1, directory-tree-object=v1,
    },
    text#{text=v1, valid-utf-8=v1, decimal-numeral=v1},
}

Group `file-reads` in [files.test-vectors.jsonl](files.test-vectors.jsonl)
tests `read-file`. Each line conforms to `vector-line`.

A runner executes each non-skipped vector under these conditions:

- A file system stores the `directory-tree` of `input.tree` for the
  program's process (`directory-tree-object`) from setup through the end
  of the read.
- No other process modifies the directory tree or opens any FIFO special
  file in the directory tree during the read (if a read fails to return
  a result within the runner's time limit, the vector fails).
- During the read, including while reaching the root, the system refuses
  no permission beyond those removed by `input.tree`, reports no I/O
  error, and offers an operation that lets the program read every needed
  part while keeping every safety obligation.

| field | type | meaning |
|---|---|---|
| `input.text` | string | `text` passed as the path to read |
| `input.tree` | `directory-tree-object` | JSON representation of the stored `directory-tree` |
| `result` | string | `"invalid"`, or the `file-read-result` (`"found"`, `"no file"`, `"symbolic link"`, `"not a regular file"`, `"not UTF-8"`, or `"cannot read"`) |
| `values.text` | array (optional) | expected file content `text` encoded as text pieces when `result` is `"found"`; absent (`values` is `{}`) for every other `result` |
| `needs` | array of strings (optional) | need names from the needs table of this group |

In `values.text`, **text pieces** are a JSON array of piece objects,
each with `text` (a JSON string) and `times` (a JSON integer `>= 1`
written as a `decimal-numeral`). The represented `text` concatenates
each piece's `text` repeated `times` times in array order (`[]` for the
empty text). Two piece arrays that expand to the same text represent the
same text.

Only these four need names are valid in `needs` for group `file-reads`:

| need | environment condition | when a vector carries this need |
|---|---|---|
| `names-kept` | The file system keeps every entry name of `input.tree` byte for byte without modification (such as Unicode normalization). | An entry name in `input.tree` is `valid-utf-8` and holds a byte `>= 0x80`. |
| `no-privilege` | The program's process holds no POSIX.1-2024 appropriate privilege that grants a permission removed by `input.tree`. | A file object in `input.tree` sets `read`, `search`, or `write` to `false`. |
| `non-utf-8-names` | The file system keeps every non-UTF-8 entry name of `input.tree` byte for byte. | An entry name in `input.tree` is not `valid-utf-8`. |
| `other-owner` | Each file whose file object sets `owned-by-other` to `true` has a POSIX.1-2024 owner user ID different from the process's effective user ID. | A file object in `input.tree` sets `owned-by-other` to `true`. |

@example Sample lines testing [read-file](sinter:#read-file=v1) with
[file-read-result](sinter:#file-read-result=v1) and
[directory-tree-object](sinter:#directory-tree-object=v1)
([vector-line](sinter:#vector-line=v1)):

```
{"form":"#file-read-vector=v1","group":"file-reads","input":{"text":"a.md","tree":{"entries":[{"file":{"content":[{"bytes":"6869","times":1}],"type":"regular file"},"name":"612e6d64"}],"type":"directory"}},"result":"found","values":{"text":[{"text":"hi","times":1}]}}
{"form":"#file-read-vector=v1","group":"file-reads","input":{"text":"docs/a.md","tree":{"entries":[{"file":{"entries":[{"file":{"content":[{"bytes":"6869","times":1}],"type":"regular file"},"name":"612e6d64"}],"search":false,"type":"directory"},"name":"646f6373"}],"type":"directory"}},"needs":["no-privilege"],"note":"the program has no search permission for directory 2, `docs`","result":"cannot read","values":{}}
```

## Test vectors

@schema vector-line=v1
@cites {
    rfc/8259,
    conformance#{design=v1, conforming-program=v1, input=v1},
    text#{
        canonical-vector-line=v1, byte-sequence=v1, valid-utf-8=v1,
        utf-8-text=v1, character=v1, text=v1, line=v1,
        decimal-numeral=v1, code-point-order=v1,
    },
}

The test-vector file [files.test-vectors.jsonl](files.test-vectors.jsonl)
of this design is a `valid-utf-8` `byte-sequence` that holds zero or more
vector lines. Its `utf-8-text` does not start with a byte order mark
(U+FEFF), holds no carriage return (U+000D), and has no empty `line`.
When the file is non-empty, its `utf-8-text` ends with a single line feed
(U+000A). Only a line feed ends a line of the file; `character` values
U+0085, U+2028, and U+2029 can appear inside JSON strings and do not end
a line.

Each line of the file is a **vector line**: an RFC 8259 JSON object that
conforms to `canonical-vector-line` and holds only these members. All
vector lines in the file with the same `group` name the same
`#<schema-name>` in `form` (their revision labels can differ).

| field | type | meaning |
|---|---|---|
| `form` | string | `"#<schema-name>=v<n>"`, naming a group schema of this design, where `<n>` is the `decimal-numeral` of a positive integer (so `v<n>` is `v1`, `v2`, and so on) |
| `group` | string | name of the vector group |
| `input` | JSON value | the input handed to a conforming program, in the form defined by the group schema |
| `needs` | array of strings (optional) | one or more need names defined by the group schema, sorted in `code-point-order` with no duplicates; omitted when the vector has no needs |
| `note` | string (optional) | non-normative explanation; ignored by conforming programs |
| `result` | string | expected result string that a conforming program returns for the input |
| `values` | object (optional) | expected outputs defined by the group schema; `{}` when the program returns none of those outputs; omitted when the group defines no outputs beyond `result` |

Unless a group schema specifies a different form, a `text` appears as a
JSON string that holds its characters in order, and a sequence appears as
a JSON array of its elements in order. When a group schema defines a JSON
object, that object holds only the members that the group schema names.

A **need** is an environment condition of a vector run that a runner can
be unable to satisfy. Each group schema lists the need names that its
group uses, together with the condition that each need name identifies; a
need name identifies the same condition in every group schema of this
design. When all three of these conditions hold, a skip of a vector makes
no conformance judgment for that vector:

- the runner cannot satisfy a need that the vector's group schema defines;
- the vector's `needs` array lists that need name; and
- the runner reports that unmet need.

Every other skip of a vector counts as a failure of the program on that
vector.
