<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Files and paths
@design files=v1
@cites text=v1
@cites rfc/5234
@cites rfc/7405
@cites rfc/8259
@cites posix/2024
Specifies folder trees and files; valid paths; file reads of texts as paths in folder trees, their results, and what conforming programs guarantee in them; valid globs, and the valid paths that fit them; path sets, and the valid paths in their sets; and requirements for conforming programs that validate texts as paths, texts as globs, and path sets, that decide whether valid paths fit valid globs and whether valid paths are in the sets of path sets, and that make file reads.

A folder tree is a folder, its root, with every file under it. A valid
path, such as `docs/guide/a.md`, is one or more file names joined by
`/`. A file read of a valid path in a folder tree gives the text of the
regular file that the valid path names, or a result that tells why it
gives no text. A valid glob, such as `docs/**/*.md`, is a pattern for
valid paths. A path set is a finite sequence of texts, its path set
members, such as `docs/` followed by `!docs/old/`. A path set can give a
set of valid paths.

The productions in the section Definitions are productions as Text and
notation defines them, in ABNF, the notation of RFC 5234, with the
case-sensitive strings of RFC 7405.

From Text and notation, the design takes characters, texts, places,
boundaries, runs, code spans, bytes, byte sequences, valid UTF-8, the
text of a byte sequence, UTF-8 encodings, the notation of productions,
requirements, conforming programs, and results. From POSIX.1-2024, the
design takes files, processes, and what a file system is; the file
types, such as a directory, a regular file, and a symbolic link; the
directory entries of a directory, and the names `.` and `..` in a
directory; hard links; pathnames and pathname resolution; the search
permission, the read permission, and the write permission of a process
for a file, the owner of a file, and the time of last access of a file;
the user IDs, the group IDs, and the appropriate privileges of a
process; and the function `openat`.

From RFC 8259, the design takes JSON texts, with their objects, members,
arrays, strings, numbers, and the literal names `true` and `false`: each
line of the file that holds the conformance vectors of the design is a
JSON text.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [system](sinter:#system=v1) | the computer that executes a program, together with the operating system of that computer, and not the program, nor the libraries and the runtime that the program uses |
| [file system](sinter:#file-system=v1) | the part of the system that stores files, as POSIX.1-2024 defines a file system, and that acts on those files when a program asks it to; a file is on the file system that stores it |
| [folder tree](sinter:#folder-tree=v1) | a folder, its root, with the file of each folder entry of the root and the file of each folder entry of each folder of the folder tree |
| [root](sinter:#folder-tree=v1) | the folder at the top of a folder tree |
| file | a file as POSIX.1-2024 defines a file: a folder, a regular file, a symbolic link, or a file of another kind |
| [file type](sinter:#file-kind=v1) | the type of a file on a file system, such as a directory or a regular file, as POSIX.1-2024 defines the file types; it gives the kind of the file |
| [folder](sinter:#folder=v1) | a file that holds folder entries; POSIX.1-2024 calls it a directory |
| [listing](sinter:#folder=v1) | the names of the directory entries of a folder that the file system would give to the process of the program if that process had the read permission for that folder |
| [folder entry](sinter:#folder=v1) | an entry name and a file, which a folder holds: a directory entry of POSIX.1-2024 whose name the listing of the folder holds, other than `.` and `..`; its file is the file that the system finds for its entry name in the folder, as in a pathname resolution of POSIX.1-2024 that does not go on from a symbolic link, so it can be a symbolic link |
| [entry name](sinter:#folder=v1) | the byte sequence that names a folder entry |
| [hold a file](sinter:#folder=v1) | a folder holds a file when, and only when, that file is the file of a folder entry of the folder |
| [regular file](sinter:#regular-file=v1) | a file that holds a content |
| [content](sinter:#regular-file=v1) | the byte sequence that a regular file holds |
| [symbolic link](sinter:#symbolic-link=v1) | a file that holds a reference, which can lead to a file or to no file, such as a link that `ln -s` makes |
| [file of another kind](sinter:#file-of-another-kind=v1) | a file that is not a folder, a regular file, or a symbolic link, such as a pipe, a character special file, a block special file, or a socket |
| [search permission](sinter:#search-permission=v1) | the permission of a program, as POSIX.1-2024 defines it, to look up names in a folder |
| [read permission](sinter:#read-permission=v1) | the permission of a program, as POSIX.1-2024 defines it, to take bytes from a regular file or the names of the directory entries of a folder |
| [attribute](sinter:#attribute=v1) | a property of a file other than the content of a regular file, the folder entries of a folder, the reference of a symbolic link, and the data of a file of another kind, such as its file type, its size, its mode, its owner, its times, or its extended attributes |
| [take bytes from a file](sinter:#taken-byte=v1) | copy into the program a byte that the file holds or gives: a byte of the content of a regular file, of the names of the directory entries of a folder, of the reference of a symbolic link, of the data of a file of another kind, or of the value of an extended attribute of the file; copying another attribute of a file takes no bytes from it |
| ignore case | treat two names that differ only in the case of their letters, such as `a.md` and `A.md`, as one name |
| Unicode normalization | a change of a text into a standard form of Unicode, such as the change of `e` and U+0301 into U+00E9; a file system that ignores differences of Unicode normalization treats two names that differ only in this way as one name |
| [valid path](sinter:#path=v1) | a text of one or more file names, with `/` between each two of them, such as `docs/a.md` |
| [file name](sinter:#path=v1) | one of the texts of which a valid path is made, such as `docs` or `a.md` in `docs/a.md`; the file names of a valid path have numbers from 1, in order: `docs` is file name 1 of `docs/a.md`; a file name is a text, and an entry name is a byte sequence |
| folder entry for a file name | the folder entry of a folder whose entry name is the UTF-8 encoding of the file name, byte for byte |
| [file read](sinter:#file-read=v1) | an operation that a program makes to give, for a text as a path in a folder tree, one of the results "invalid", "found", "no file", "symbolic link", "not a regular file", "not UTF-8", and "cannot read" |
| [read a text as a path in a folder tree](sinter:#file-read=v1) | make a file read of the text in the folder tree |
| [file-read result](sinter:#file-read-result=v1) | the result that a valid path in a folder tree gives for a program, from the folder entries and the files that the file names name, one file name after the other from the root, and from the permissions of the program: "cannot read", "no file", "symbolic link", "not a regular file", "not UTF-8", or "found", with the text of a content |
| [file of the path](sinter:#path-file=v1) | in a folder tree, a file that a valid path names: the root, or, for file name k, the file of the folder entry for file name k in folder k, where folder 1 is the root and folder k + 1 is the folder that file name k names, when file name k is not the last |
| [folder of the path](sinter:#path-file=v1) | in a folder tree, a folder k of a valid path: the root, or a folder that a file name other than the last names |
| [follow a symbolic link](sinter:#follow-no-symbolic-links=v1) | find a file by the reference of the symbolic link |
| [valid glob](sinter:#glob=v1) | a pattern for valid paths, such as `docs/**/*.md` |
| [glob segment](sinter:#glob=v1) | one of the texts that a valid glob joins with `/`, such as `docs`, `**`, or `*.md` in `docs/**/*.md`; when the valid glob ends with `/`, the text `**` is one more glob segment after them, so the glob segments of `docs/` are `docs` and `**`; the glob segments of a valid glob have numbers from 1, in order |
| [fit](sinter:#glob-fit=v1) | a valid path fits a valid glob when the valid path has the form that the valid glob gives |
| [path set](sinter:#path-set=v1) | a finite sequence of texts, its path set members, such as `docs/` followed by `!docs/old/` |
| [path set member](sinter:#path-set=v1) | one text of a path set |
| [plain member](sinter:#path-set=v1) | a path set member that does not start with `!` |
| [`!` member](sinter:#path-set=v1) | a path set member that starts with `!`, such as `!docs/old/` |
| [glob text of a path set member](sinter:#path-set=v1) | the text after the `!` of a `!` member, or the whole path set member for a plain member; it can be a text that is not a valid glob |
| [valid path set](sinter:#valid-path-set=v1) | a path set in which the glob text of each path set member is a valid glob, no two path set members are the same text, and at least one path set member is a plain member when the path set holds a path set member |
| [set of a path set](sinter:#path-set-membership=v1) | the valid paths that fit the glob text of a plain member of the path set and the glob text of no `!` member of it, when the glob text of each path set member is a valid glob |
| validate | to validate a text as a path, a text as a glob, or a path set is to make an operation to give for it one of the results "valid" and "invalid", other than a file read; a validation is one such operation, also when the program gives another thing in it, or nothing |
| decide | to decide whether a valid path fits a valid glob is to make an operation to give one of the results "fits" and "does not fit"; to decide whether a valid path is in the set of a path set in which the glob text of each path set member is a valid glob is to make an operation to give one of the results "in the set" and "not in the set"; the program decides in such an operation also when it gives another thing in it, or nothing |
| [file object](sinter:#file-object=v1) | a JSON object that stands for a file, and for the permissions of a program for it: its member `type`, such as `"regular file"`, its member `entries`, `content`, or `reference`, and the members `read`, `search`, `write`, and `owned-by-other` when they differ from their defaults |
| [folder tree object](sinter:#folder-tree-object=v1) | the file object of the root of a folder tree, which stands for that folder tree |
| [store the folder tree of a folder tree object](sinter:#stored-folder-tree=v1) | for a file system: hold that folder tree, with its entry names, its file types, its contents, its references, its owners, and the permissions of the program, as the folder tree object gives them |
| valid, invalid | the results of a validation of a text as a path, of a text as a glob, or of a path set; a file read also gives "invalid", when, and only when, its text is not a valid path |

## 2. Files, paths, globs, and path sets

### 2.1 Folder trees and files

The system of a program is the computer that executes the program,
together with the operating system of that computer. The program, and
the libraries and the runtime that the program uses, are not part of the
system. A file system is the part of the system that stores files, as
POSIX.1-2024 defines a file system, and that acts on those files when a
program asks it to. A file is on the file system that stores it. The
folders of a folder tree can be on more than one file system.

A folder tree is a folder, its root, together with the file of each
folder entry of the root and the file of each folder entry of each
folder of the folder tree. Each file is of one of four kinds:

| kind | what the file holds |
|---|---|
| folder | folder entries: each folder entry has an entry name and a file |
| regular file | a content: a byte sequence |
| symbolic link | a reference, which can lead to a file or to no file |
| file of another kind | something that is not a content, folder entries, or a reference, such as the data of a pipe, a character special file, a block special file, or a socket |

An entry name is a byte sequence. No two folder entries of one folder
have the same entry name. A folder holds a file when that file is the
file of a folder entry of the folder.

On a file system, the file type of a file gives its kind, as
POSIX.1-2024 defines the file types. A file of the type directory is a
folder. A file of the type regular file is a regular file. A file of the
type symbolic link is a symbolic link. A file of each other type, such
as a FIFO special file (a pipe), a character special file, a block
special file, or a socket, is a file of another kind.

The listing of a folder is the names of the directory entries of the
folder that the file system that the folder is on would give to the
process of the program if that process had the read permission for the
folder, as POSIX.1-2024 defines directory entries. Some file systems
give different names to different processes: for example, a file system
can hide from a process the names of the files that the process cannot
read. The folder entries of a folder are the directory entries whose
names the listing of the folder holds, other than `.` and `..`. The file
of a folder entry is the file that the system finds for its entry name
in the folder, as in a pathname resolution of POSIX.1-2024 that does not
go on from a symbolic link. So the file of a folder entry can be a
symbolic link. In POSIX.1-2024, the names `.` and `..` in a directory
lead to the directory itself and to the directory above it. So the name
`..` does not make the folder above the root a file of the folder tree.
Some file systems also have a name that a program can look up and that
the listing does not hold, such as the name of a hidden folder of
snapshots. Such a name is not the entry name of a folder entry.

A program takes a byte from a file when it copies into the program a
byte that the file holds or gives: a byte of the content of a regular
file, of the names of the directory entries of a folder, of the
reference of a symbolic link, of the data of a file of another kind, or
of the value of an extended attribute of the file. Copying another
attribute of a file into the program, such as its size or its mode,
takes no bytes from that file.

The search permission of a program for a folder lets the program look up
names in the folder. The read permission of a program for a regular file
lets the program take the bytes of the content, and the read permission
for a folder lets the program take the names of the directory entries of
the folder. These are the permissions of the process of the program, as
POSIX.1-2024 defines them.

An attribute of a file is a property of the file other than the content
of a regular file, the folder entries of a folder, the reference of a
symbolic link, and the data of a file of another kind. Examples of
attributes are the file type of a file, as POSIX.1-2024 defines the
file types, its size, its mode, its owner, its times, and its extended
attributes.

### 2.2 Valid paths

A valid path is one or more file names, with `/` between each two of
them. A file name is a text that is not empty, that holds no `/` and no
U+0000, and that is not `.` or `..`. So a valid path never starts or
ends with `/`, and it never holds two `/` together. The file names of a
valid path have numbers from 1, in order: in `docs/guide/a.md`, file
name 1 is `docs`, and file name 3, the file name with the highest
number, is `a.md`. Two file names of one valid path can be the same
text, as in `a/a`. A file name is a text, not an entry name, which is a
byte sequence. The folder entry for a file name in a folder is the
folder entry of that folder whose entry name is the UTF-8 encoding of
the file name, byte for byte.

A conforming program that validates these texts as paths gives these
results:

| text | result |
|---|---|
| `a.md` | "valid": one file name |
| `docs/guide/a.md` | "valid": three file names |
| `.github/workflows/ci.yml` | "valid": a file name can start with `.` |
| `...` | "valid": of the texts of dots alone, only `.` and `..` are not file names |
| `a b/c\d.md` | "valid": a space and `\` are characters of a file name |
| the empty text | "invalid" |
| `/a.md` | "invalid": it starts with `/` |
| `docs/` | "invalid": it ends with `/` |
| `docs//a.md` | "invalid": two `/` together |
| `./a.md` | "invalid": `.` is not a file name |
| `docs/../a.md` | "invalid": `..` is not a file name |

`/` is the only separator, so `a\b.md` is one file name. `.` and `..`
are not file names, so `docs/../a.md` does not lead to `a.md`: it is not
a valid path.

A valid path is a text. Two valid paths are the same valid path only
when they are the same text. So case matters: `Docs/a.md` and
`docs/a.md` are two different valid paths. No Unicode normalization
applies, so a valid path with `é` as U+00E9 and a valid path with `e`
and U+0301 are two different valid paths, though they look the same.
Two different valid paths can still lead to the same file, because two
folder entries can have the same file, such as two hard links to one
regular file, as POSIX.1-2024 defines hard links.

### 2.3 The file read

A file read is an operation that a program makes to give, for a text as
a path in a folder tree, one of the results "invalid", "found", "no
file", "symbolic link", "not a regular file", "not UTF-8", and "cannot
read". An operation that a program makes to give one of these results
for a text as a path in a folder tree is a file read, also when the
program gives another thing in it, or nothing. To read a text as a path
in a folder tree is to make a file read of that text in that folder
tree.

A file read gives "invalid" when, and only when, its text is not a valid
path. So a file read of the text `../a.md` or `/etc/passwd` gives
"invalid".

A valid path names files in a folder tree, one file name after the
other. Folder 1 is the root. When folder k holds the folder entry for
file name k, file name k names the file of that folder entry. When that
file is a folder, and file name k is not the last file name, that folder
is folder k + 1. The files of the path are the root and each file that a
file name of the valid path names. The folders of the path are the
folders k.

When the text is a valid path, and no other process changes the folder
tree during the file read, the file read gives the file-read result of
the valid path. The folder tree and the permissions of the program give
the file-read result. For each file name k of the valid path in turn,
from file name 1, the first row of this table whose condition holds
gives the file-read result. When no row holds, file name k is not the
last file name, and the file that it names is folder k + 1. File name
k + 1 is next.

| condition | result |
|---|---|
| the program has no search permission or no read permission for folder k | "cannot read" |
| folder k holds no folder entry for file name k | "no file" |
| the file that file name k names is a symbolic link | "symbolic link" |
| file name k is not the last file name, and that file is not a folder | "no file" |
| file name k is the last file name, and that file is a folder or a file of another kind | "not a regular file" |
| that file is a regular file, and the program has no read permission for it | "cannot read" |
| that file is a regular file whose content is not valid UTF-8 | "not UTF-8" |
| that file is a regular file whose content is valid UTF-8 | "found", with the text of that content |

Example: the root holds the folder `docs`, which holds the regular file
`a.md`, whose content is the text `hi`. The valid path `docs/a.md` gives
"found", with the text `hi`. The valid path `docs` gives "not a regular
file", and `docs/b.md` gives "no file". The valid path `docs/a.md/x`
gives "no file", because file name 2, `a.md`, is not the last file
name, and its file is not a folder. Whether a file name is the last
file name depends on its number, and not on its text: in a folder tree
with the regular file `a`, the valid path `a/a` gives "no file".

A folder holds the folder entry for a file name only when the entry name
of that folder entry is the UTF-8 encoding of the file name, byte for
byte, on every file system. Some file systems ignore case or differences
of Unicode normalization, so that a call of `openat` with the bytes of
`A.md` can open the file of the folder entry `a.md`. Still, the valid
path `A.md` gives "no file" in a folder tree whose root holds only the
regular file `a.md`. So a file name that is longer than the file system
allows in an entry name gives "no file", because the listing of the
folder holds no such name. A name that the listing of a folder does not
hold names no folder entry: the name of a hidden folder of snapshots,
and `..` followed by a space on a file system that ignores a space at
the end of a name, are examples.

Folder k is the folder that must hold the folder entry for file name k:
the root for file name 1, and the folder that the file name before it
names for each later file name. The result is "cannot read" when the
program has no read permission for folder k, also when folder k holds
the folder entry for file name k, and on every file system. Without the
read permission, the program cannot take the names of the listing of the
folder, and so it cannot compare them with the UTF-8 encoding of the
file name, byte for byte. The permissions of the program for a folder
that the last file name names do not change the result: the valid path
`docs` gives "not a regular file" when `docs` is a folder, also when the
program has neither the search permission nor the read permission for
`docs`.

When the system fails during the file read, for a cause other than the
folder tree and the permissions of the program for the files of the
folder tree, such as an input or output error of a device, a lack of
memory, or too many open files, the program can give "cannot read"
instead of the file-read result. Also, when the program cannot reach the
root because it has no search permission for a folder above the root, it
can give "cannot read". An error that the system gives because a name or
a pathname that the program passes to the system is longer than the
system or the file system allows, or because the file system does not
accept a name as an entry name, is not a failure of the system. So, on a
system that allows at most 1,024 bytes in a pathname, a file read of a
valid path of 5,024 characters in a folder tree that no other process
changes still gives the file-read result, unless the system fails for
another cause.

With the result "found", the file read also gives the text of the
content of the regular file, and no other text as the text of the
content. The text holds one character for each character that the
content encodes, in order. The program adds no character, removes no
character, and changes no character. So the text keeps a byte order
mark, keeps each carriage return, and keeps each character in the form
that the content encodes, with no Unicode normalization. The text is the
text of the whole content, whatever its size, so a conforming program
sets no limit of its own on the size of a file. With each other result,
the file read gives no text as the text of a content. A program can give
other texts in a file read, such as a message.

When another process changes the folder tree during a file read of a
valid path, no requirement fixes the result of the file read, or the
text that it gives with "found", but the guarantees below still hold.

In each file read, also when another process changes the folder tree, a
conforming program keeps these guarantees:

- It follows no symbolic link of the folder tree: it finds no file by
  the reference of such a symbolic link.
- For a file read, it takes bytes only from the folders of the path and
  from the regular file that the last file name names; for a text that
  is not a valid path, it takes none. So, for a file read, it takes no
  byte from a file outside the folder tree.
- It does not wait for another process or for a device to act on a file
  of another kind of the folder tree, such as for a process to open the
  other end of a pipe.
- It changes no file of the folder tree. A change that the file system
  makes by itself, such as a change of the time of last access, is not a
  change by the program.
- It uses only the permissions and the appropriate privileges, as
  POSIX.1-2024 defines these, that its process has without a change by
  the program: not one that it gets by a change of the user IDs, the
  group IDs, or the appropriate privileges of its process, or through
  another process that acts for it. A capability, on a system that gives
  capabilities to processes, is an example of an appropriate privilege.

A valid path cannot lead out of the folder tree through a symbolic link.
In a folder tree whose root holds the symbolic link `d`, whose reference
leads to the folder `q`, the valid path `d/a.md` gives "symbolic link",
and the program takes no byte from a file in `q`. A symbolic link that
the valid path does not name does not change the file read: in a folder
tree with the symbolic link `self`, whose reference leads to the root,
and the regular file `a.md`, the valid path `a.md` gives "found".

### 2.4 Valid globs

A valid glob is a pattern for valid paths. A valid glob is one or more
texts with `/` between each two of them, and it can end with `/`. Its
glob segments are these texts and, when the valid glob ends with `/`,
one more glob segment, `**`, after them (statement 5 below). Each glob
segment is `**`, or a text in which `*` stands for any run of characters
inside one file name. The glob segments of a valid glob have numbers
from 1, in order. A valid path fits a valid glob when the valid path has
the form that the valid glob gives. These statements say what that form
is:

1. A valid path fits a valid glob only as a whole, from file name 1.
   Only the valid path `Cargo.lock` fits `Cargo.lock`. A valid path
   whose file name with the highest number is `Cargo.lock` fits
   `**/Cargo.lock`, at any depth.
2. Any run of characters inside one file name fits `*`, the empty run
   included. No `/` fits `*`, because a file name holds no `/`.
3. Any number of file names, zero included, fit a glob segment `**`
   that does not have the highest number. So `x.md` and `a/b/x.md` fit
   `**/x.md`, and `a/b` fits `a/**/b`.
4. One or more file names fit a glob segment `**` that has the highest
   number. So each valid path that has file name 1 `docs` and more than
   one file name, such as `docs/a.md` and `docs/a/b.md`, fits `docs/**`.
   The valid path `docs` does not fit `docs/**`.
   In `**/x/**`, glob segment 1 is a `**` that does not have the highest
   number, and glob segment 3 is a `**` that has the highest number. So
   `x/a` fits `**/x/**`, and `x` does not.
5. A valid glob that ends with `/` has the glob segment `**` after that
   `/`. So `docs/` means `docs/**`.
6. File names that start with `.` fit `*` and `**`.
7. Only a run of one character, the same character, fits a character of
   a glob segment other than `*`. So `aa.md` does not fit `a.md`. Case
   always matters, so `docs/a.md` does not fit `Docs/*`.

These texts are not valid globs:

- the empty text;
- a text that starts with `/`;
- a text with two `/` together;
- a text with a glob segment `.` or `..`;
- a text with `**` in a glob segment that holds other characters too,
  such as `src/**.ts`; `src/**/*.ts` is a valid glob;
- a text that holds `?`, `[`, `]`, `{`, `}`, or `\`.

A valid glob can hold U+0000, but no file name holds U+0000. So no file
name fits a glob segment that holds U+0000.

| valid glob | valid paths that fit it | valid paths that do not fit it |
|---|---|---|
| `*.md` | `a.md`; `.md`; `.notes.md` | `a/b.md`; `a.txt` |
| `docs/**/*.md` | `docs/a.md`; `docs/x/y/a.md` | `a.md`; `docs/a.txt` |
| `a*b*c` | `abc`; `aXbYc` | `ab`; `acb` |

### 2.5 Path sets

A path set is a finite sequence of texts, its path set members. A path
set member that starts with `!` is a `!` member, and the glob text of
that path set member is the text after that `!`. Every other path set
member is a plain member, and the glob text of that path set member is
the path set member. The glob text of a path set member can be a text
that is not a valid glob.

When the glob text of each path set member is a valid glob, the path set
gives a set of valid paths, the set of the path set. A valid path is in
the set of the path set when the valid path fits the glob text of a
plain member, and fits the glob text of no `!` member. So a `!` member
removes valid paths from the set. The order of the path set members does
not change the set. No valid path is in the set of the empty path set.

Example: with the path set members `docs/` and `!docs/old/`, the valid
path `docs/a.md` is in the set of the path set, and `docs/old/a.md` and
`a.md` are not. The glob text of the path set member `!!x` is `!x`, and
the valid path `!x` fits that valid glob.

A path set is valid when:

1. the glob text of each path set member is a valid glob;
2. no two path set members are the same text;
3. at least one path set member is a plain member, when the path set
   holds at least one path set member.

The empty path set is valid. A path set that is not valid can still give
a set of valid paths: the path set with the path set members `a/` and
`a/` is not valid, because two path set members are the same text, and
the valid path `a/b` is in the set of that path set.

### 2.6 Validations and results

A program validates a text as a path, a text as a glob, or a path set
when it makes an operation to give for it one of the results "valid" and
"invalid", other than a file read. A program decides whether a valid
path fits a valid glob when it makes an operation to give one of the
results "fits" and "does not fit". A program decides whether a valid
path is in the set of a path set when it makes an operation to give one
of the results "in the set" and "not in the set". The program validates
or decides in such an operation also when it gives another thing in it,
or nothing. This table gives the input and the
results of each of these five operations:

| operation | input | results |
|---|---|---|
| validate a text as a path | a text | "valid" or "invalid" |
| validate a text as a glob | a text | "valid" or "invalid" |
| decide whether a valid path fits a valid glob | a valid path and a valid glob | "fits" or "does not fit" |
| validate a path set | a path set | "valid" or "invalid" |
| decide whether a valid path is in the set of a path set in which the glob text of each path set member is a valid glob | that valid path and that path set | "in the set" or "not in the set" |

In each validation that it makes, a conforming program gives exactly one
result. Each time it decides whether a valid path fits a valid glob, or
whether a valid path is in the set of a path set, a conforming program
also gives exactly one result. So a program that, in a validation of a
long text, gives an error in place of a result does not conform. In each
file read that it makes in a folder tree that no other process changes
during the file read, a conforming program gives exactly one of seven
results: "invalid", "found", "no file", "symbolic link", "not a regular
file", "not UTF-8", and "cannot read".

## 3. Definitions

### 3.1 The system

@term system=v1

The system of a program is the computer that executes the program,
together with the operating system of that computer. The program, and
the libraries and the runtime that the program uses, are not part of the
system. In a statement about a program, the system is the system of that
program.

### 3.2 File systems

@term file-system=v1
@cites {posix/2024, #{system=v1}}

A file system is the part of the system that stores files, as
POSIX.1-2024 defines a file system, and that acts on those files when a
program asks it to. A file is on a file system when, and only when, that
file system stores that file.

### 3.3 Folders

@term folder=v1
@cites {
    posix/2024,
    #{system=v1, file-system=v1, symbolic-link=v1, read-permission=v1},
    text#{byte-sequence=v1, text=v1, utf-8-encoding=v1, code-span=v1},
}

A folder is a file that holds folder entries. Each folder entry of a
folder has an entry name, which is a byte sequence, and a file. No two
folder entries of one folder have the same entry name. A folder holds a
file when, and only when, that file is the file of a folder entry of
that folder. In a statement about a program, the listing of a folder is
the names of the directory entries of that folder that the file system
that the folder is on would give to the process of that program if that
process had the read permission for that folder, as POSIX.1-2024 defines
directory entries and the read permission of a process. The folder
entries of a folder are the directory entries of that folder whose names
its listing holds, except each directory entry whose name is the UTF-8
encoding of the text `.` or of the text `..`. The entry name of a folder
entry is the name of that directory entry. The file of a folder entry is
the file that the system finds for that entry name in that folder, as in
a pathname resolution of POSIX.1-2024 that does not go on from a
symbolic link, so the file of a folder entry can be a symbolic link.

### 3.4 Regular files

@term regular-file=v1
@cites text#{byte-sequence=v1}

A regular file is a file that holds a content, which is a byte
sequence.

### 3.5 Symbolic links

@term symbolic-link=v1

A symbolic link is a file that holds a reference, which can lead to a
file or to no file.

### 3.6 Files of another kind

@term file-of-another-kind=v1
@cites #{folder=v1, regular-file=v1, symbolic-link=v1}

A file of another kind is a file that is not a folder, a regular file,
or a symbolic link.

### 3.7 Folder trees

@term folder-tree=v1
@cites #{folder=v1}

A folder tree is a folder, its root, together with the file of each
folder entry of the root and the file of each folder entry of each
folder of the folder tree.

### 3.8 The kinds of files on a file system

@term file-kind=v1
@cites {
    posix/2024,
    #{
        file-system=v1, folder=v1, regular-file=v1, symbolic-link=v1,
        file-of-another-kind=v1,
    },
}

On a file system, the file type of a file gives its kind, as
POSIX.1-2024 defines the file types: a file of the type directory is a
folder, a file of the type regular file is a regular file, a file of
the type symbolic link is a symbolic link, and a file of each other
type is a file of another kind.

### 3.9 The search permission

@term search-permission=v1
@cites posix/2024

The search permission of a program for a file is the search permission
of the process of the program for that file, as POSIX.1-2024 defines
it.

### 3.10 The read permission

@term read-permission=v1
@cites posix/2024

The read permission of a program for a file is the read permission of
the process of the program for that file, as POSIX.1-2024 defines it.

### 3.11 Attributes

@term attribute=v1
@cites {
    posix/2024,
    #{
        folder=v1, regular-file=v1, symbolic-link=v1,
        file-of-another-kind=v1, file-kind=v1,
    },
}

An attribute of a file is a property of the file other than the content
of a regular file, the folder entries of a folder, the reference of a
symbolic link, and the data of a file of another kind, such as the file
type of the file, as POSIX.1-2024 defines the file types, its size, its
mode, its owner, its times, or its extended attributes.

### 3.12 Bytes taken from a file

@term taken-byte=v1
@cites {
    posix/2024,
    #{
        folder=v1, regular-file=v1, symbolic-link=v1,
        file-of-another-kind=v1, attribute=v1,
    },
    text#{byte=v1},
}

A byte that a program takes from a file is a byte that the file holds or
gives and that the program copies into the program: a byte of the
content of a regular file, of the names of the directory entries of a
folder, as POSIX.1-2024 defines directory entries, of the reference of a
symbolic link, of the data of a file of another kind, or of the value of
an extended attribute of the file. To take bytes from a file is to copy
such bytes into the program. Copying another attribute of a file into
the program takes no bytes from that file.

### 3.13 Valid paths

@term path=v1
@cites text#{production=v1, rule-name=v1, code-span=v1, text=v1}

A valid path is a text that matches the production `path`:

```abnf
path       = file-name *( "/" file-name )
file-name  = *"." non-dot *name-char / 3*"."
name-char  = %x1-2E / %x30-D7FF / %xE000-10FFFF
non-dot    = %x1-2D / %x30-D7FF / %xE000-10FFFF
```

The file names of a valid path are the texts that its `file-name`
elements match. They have numbers from 1, in the order of the
`file-name` elements: file name 1 is the text that the first
`file-name` element matches, and each later file name has the number 1
more than the file name right before it.

### 3.14 File reads

@term file-read=v1
@cites {#{folder-tree=v1, path=v1}, text#{text=v1, result=v1}}

A file read is an operation that a program makes to give, for a text as
a path in a folder tree, one of the results "invalid", "found", "no
file", "symbolic link", "not a regular file", "not UTF-8", and "cannot
read". Such an operation is a file read also when the program gives
another thing in it, or nothing. That text is the text of the file read,
and that folder tree is the folder tree of the file read. To read a text
as a path in a folder tree is to make a file read of that text in that
folder tree.

### 3.15 The files of the path

@term path-file=v1
@cites {
    #{folder=v1, folder-tree=v1, path=v1},
    text#{text=v1, utf-8-encoding=v1},
}

For a valid path in a folder tree, folder 1 is the root of that folder
tree. For each file name k of that valid path, from file name 1, when
folder k exists and holds a folder entry whose entry name is the UTF-8
encoding of file name k, file name k names the file of that folder
entry; and when that file is a folder, and file name k is not the last
file name of that valid path, that folder is folder k + 1. The files of
the path of a valid path in a folder tree are the root of that folder
tree and each file that a file name of that valid path names in that
folder tree. The folders of the path of a valid path in a folder tree
are the folders k that exist for that valid path in that folder tree.

### 3.16 The result of a file read

@term file-read-result=v1
@cites {
    #{
        file-system=v1, folder=v1, regular-file=v1, symbolic-link=v1,
        file-of-another-kind=v1, folder-tree=v1, file-kind=v1,
        search-permission=v1, read-permission=v1, path=v1, path-file=v1,
    },
    text#{
        text=v1, result=v1, utf-8-encoding=v1, valid-utf-8=v1,
        text-of-a-byte-sequence=v1,
    },
}

The file-read result of a valid path in a folder tree, for a program, is
the result of the first of these cases that holds, where folder k and
the file that file name k names are those of that valid path in that
folder tree. For each file name k of that valid path in turn, from file
name 1, the cases apply in order from case 1 to case 6:

1. The program has no search permission or no read permission for folder
   k: "cannot read".
2. Folder k holds no folder entry whose entry name is the UTF-8 encoding
   of file name k: "no file". So folder k holds no folder entry for a
   file name that is longer than the file system that folder k is on
   allows in an entry name, because the listing of folder k holds no
   such name.
3. The file that file name k names is a symbolic link: "symbolic link".
4. File name k is not the last file name of that valid path, and that
   file is not a folder: "no file".
5. File name k is the last file name of that valid path, and that file
   is a folder or a file of another kind: "not a regular file".
6. That file is a regular file: "cannot read" when the program has no
   read permission for it; otherwise "not UTF-8" when its content is not
   valid UTF-8; and otherwise "found", with the text of its content.

### 3.17 Valid globs

@term glob=v1
@cites text#{production=v1, rule-name=v1, code-span=v1, text=v1}

A valid glob is a text that matches the production `glob`:

```abnf
glob           = glob-segment *( "/" glob-segment ) [ "/" ]
glob-segment   = "**" / star-segment / plain-segment
star-segment   = *glob-char "*" *( 1*glob-char "*" ) *glob-char
plain-segment  = *"." glob-non-dot *glob-char / 3*"."
glob-char      = %x0-29 / %x2B-2E / %x30-3E / %x40-5A / %x5E-7A / %x7C
               / %x7E-D7FF / %xE000-10FFFF
glob-non-dot   = %x0-29 / %x2B-2D / %x30-3E / %x40-5A / %x5E-7A / %x7C
               / %x7E-D7FF / %xE000-10FFFF
```

The glob segments of a valid glob are the texts that its `glob-segment`
elements match, in order, and then the text `**` when the valid glob
ends with `/`. They have numbers from 1, in that order.

### 3.18 Valid paths that fit valid globs

@term glob-fit=v1
@cites {
    #{path=v1, glob=v1},
    text#{character=v1, text=v1, run=v1, code-span=v1, place=v1},
}

A valid path fits a valid glob when, and only when, the file names of
the valid path can be divided into groups, one group for each glob
segment of the valid glob, such that the file names of the groups, group
after group in the order of the numbers of the glob segments, are the
file names of the valid path in the order of their numbers, and each
group fits its glob segment:

- A group fits a glob segment `**` that has the highest number when,
  and only when, the group holds one or more file names.
- A group fits a glob segment `**` that does not have the highest
  number when, and only when, the group holds zero or more file names.
- A group fits each other glob segment when, and only when, the group
  holds exactly one file name, and that file name fits the glob segment.

A file name fits a glob segment other than `**` when, and only when,
the file name can be divided into runs, one run for each place of the
glob segment, such that the characters of the runs, run after run in the
order of the places of the glob segment, are the characters of the file
name in order, and each run fits its place of the glob segment. A run
fits a place at which the character of the glob segment is `*`, whatever
characters the run holds, the empty run included. A run fits a place at
which the character of the glob segment is a character other than `*`
when, and only when, the run holds one character, and that character is
the character of the glob segment at that place.

### 3.19 Path sets

@term path-set=v1
@cites text#{
    text=v1, character=v1, code-span=v1, place=v1, boundary=v1, run=v1,
}

A path set is a finite sequence of texts, its path set members. A path
set member whose character at place 1 is `!` is a `!` member, and the
glob text of that path set member is the text of the run of that path
set member that starts at boundary 1 and ends at the last boundary of
that path set member. Each other path set member is a plain member, and
the glob text of that path set member is the path set member.

### 3.20 Valid path sets

@term valid-path-set=v1
@cites {#{path-set=v1, glob=v1}, text#{text=v1}}

A path set is valid when, and only when, the glob text of each path set
member is a valid glob, no two path set members are the same text, and
at least one path set member is a plain member when the path set holds
at least one path set member.

### 3.21 The set of a path set

@term path-set-membership=v1
@cites {
    #{path=v1, glob=v1, glob-fit=v1, path-set=v1},
    text#{text=v1, code-span=v1},
}

For a path set in which the glob text of each path set member is a
valid glob, a valid path is in the set of the path set when, and only
when, the valid path fits the glob text of at least one plain member of
the path set, and the valid path fits the glob text of no `!` member of
the path set.

### 3.22 File objects

@term file-object=v1
@cites {
    rfc/8259,
    posix/2024,
    #{
        folder=v1, regular-file=v1, symbolic-link=v1,
        file-of-another-kind=v1, file-kind=v1, search-permission=v1,
        read-permission=v1,
    },
    text#{
        whole-number=v1, decimal-numeral=v1, hex-digit=v1, byte=v1,
        byte-sequence=v1, code-span=v1,
    },
}

A file object is a JSON object, as RFC 8259 defines JSON values, that
stands for a file, and for the permissions of a program for that file.
Its member `type` is a JSON string that names the file type of that
file, as POSIX.1-2024 defines the file types: `"directory"` for a
folder, `"regular file"` for a regular file, `"symbolic link"` for a
symbolic link, and `"FIFO special file"` for a FIFO special file, which
is a file of another kind. By its type, a file object also has one
member for what its file holds, or none:

- `"directory"`: `entries`, a JSON array of one entry object for each
  folder entry of the folder, in increasing order of their entry names,
  where one entry name comes before another when, at the first byte at
  which they differ, its byte is less, or when its bytes are fewer and
  they are the first bytes of the other. An entry object is a JSON
  object with two members: `name`, the entry name of the folder entry,
  as a hex byte sequence, and `file`, the file object of the file of the
  folder entry. A folder that holds no folder entry has `"entries":[]`.
- `"regular file"`: `content`, the content of the regular file, as
  pieces of a byte sequence.
- `"symbolic link"`: `reference`, the reference of the symbolic link, as
  a hex byte sequence. The reference leads to a file as in a pathname
  resolution of POSIX.1-2024, from the folder that holds the symbolic
  link.
- `"FIFO special file"`: no such member.

A file object can also have the members `read`, `search`, `write`, and
`owned-by-other`, each a JSON boolean, `true` or `false`. It has one of
them only when its value differs from the value in brackets, which
applies when the file object does not have that member:

- `read` (`true`): whether the program has the read permission for the
  file. A file object of the type `"symbolic link"` cannot have this
  member.
- `search` (`true`): whether the program has the search permission for
  the folder. Only a file object of the type `"directory"` can have this
  member, and the value in brackets applies only to a file object of
  that type.
- `write` (`true`): whether the program has the write permission for the
  file, as POSIX.1-2024 defines it. A file object of the type
  `"symbolic link"` cannot have this member.
- `owned-by-other` (`false`): whether the user ID of the owner of the
  file, as POSIX.1-2024 defines it, differs from the effective user ID
  of the process of the program.

A file object and an entry object have the members that this definition
names, and no other member, and no JSON object of them has two members
with the same name. A hex byte sequence is a JSON string of hex digits
that holds, for each byte of the byte sequence, in order, the hex digit
of the whole-number quotient of the byte divided by 16, then the hex
digit of the remainder: so the byte sequence 0xC3, 0xA9 is `"c3a9"`, and
the empty byte sequence is `""`. The pieces of a byte sequence are a
JSON array of JSON objects, each with two members: `bytes`, a hex byte
sequence, and `times`, a JSON number written as the decimal numeral of a
whole number of 1 or more. The byte sequence of these pieces is the
bytes of each piece, `times` times in a row, piece after piece in the
order of the JSON array: so `[{"bytes":"61","times":3}]` is the byte
sequence 0x61, 0x61, 0x61, and `[]` is the empty byte sequence. Pieces
that give the same byte sequence stand for the same content.

### 3.23 Folder tree objects

@term folder-tree-object=v1
@cites {
    #{folder=v1, folder-tree=v1, file-object=v1},
    text#{code-span=v1},
}

A folder tree object is a file object whose member `type` is
`"directory"`, and that no other file object holds. It stands for the
folder tree whose root is the folder that it stands for: the files of
that folder tree are the files that the file objects in the folder tree
object stand for, and no other file.

### 3.24 Stored folder trees

@term stored-folder-tree=v1
@cites {
    posix/2024,
    #{
        file-system=v1, folder=v1, regular-file=v1, symbolic-link=v1,
        folder-tree=v1, file-kind=v1, file-object=v1,
        folder-tree-object=v1,
    },
    text#{code-span=v1},
}

A file system stores the folder tree of a folder tree object, for a
process of a program, while these conditions hold, and a stored folder
tree is a folder tree that a file system stores in this way:

1. The whole folder tree is on that file system.
2. The listing of each folder of the folder tree, for that program,
   holds the entry name of each entry object of the file object of that
   folder, and no other name except `.` and `..`.
3. Each file of the folder tree has the file type, the content, and the
   reference that its file object gives; its owner has a user ID, as
   POSIX.1-2024 defines it, that differs from the effective user ID of
   that process when, and only when, its file object has
   `owned-by-other` with the value `true`; and, for each file other than
   a symbolic link, that process has the permissions that its file
   object gives.

## 4. Requirements

### 4.1 The validation of texts as paths

@req validate-paths=v1
@cites {
    #{path=v1, file-read=v1},
    text#{
        conforming-program=v1, result=v1, text=v1, production=v1,
        code-span=v1, requirement=v1,
    },
}

In each validation of a text as a path that it makes, which is an
operation to give one of the results "valid" and "invalid" for whether
the text is a valid path, other than a file read, also when the program
gives another thing in it, or nothing, a conforming program must give
exactly one result: "valid" when the text matches `path`, and "invalid"
when the text does not match `path`.

### 4.2 Texts that are not valid paths

@req give-invalid-for-non-paths=v1
@cites {
    #{folder-tree=v1, path=v1, file-read=v1},
    text#{conforming-program=v1, result=v1, text=v1, requirement=v1},
}

In each file read of a text in a folder tree, a conforming program must
give exactly one result, "invalid", when the text is not a valid path,
and must not give the result "invalid" when the text is a valid path.

### 4.3 The result of a file read

@req give-file-read-results=v1
@cites {
    posix/2024,
    #{
        system=v1, file-system=v1, folder=v1, folder-tree=v1,
        search-permission=v1, path=v1, file-read=v1,
        file-read-result=v1,
    },
    text#{conforming-program=v1, result=v1, text=v1, requirement=v1},
}

In each file read of a valid path in a folder tree that no other process
changes during the file read, a conforming program must give exactly one
result, which is the file-read result of that valid path in that folder
tree for the program, or "cannot read" when the system fails during the
file read for a cause other than the folder tree and the permissions of
the program for the files of the folder tree, such as an input or output
error of a device, a lack of memory, too many open files, or the lack of
the search permission of the program for a folder outside the folder
tree through which the program finds the root. An error that the system
gives because a name, or a pathname of POSIX.1-2024, that the program
passes to the system is longer than the system or the file system
allows, or because the file system does not accept a name as an entry
name, is not a failure of the system.

### 4.4 The text of the content

@req give-file-text=v1
@cites {
    #{
        folder-tree=v1, regular-file=v1, path=v1, file-read=v1,
        file-read-result=v1,
    },
    text#{conforming-program=v1, result=v1, text=v1, requirement=v1},
}

When it gives the result "found" in a file read of a valid path in a
folder tree that no other process changes during the file read, a
conforming program must give with that result, as the text of the
content, the text that the file-read result of that valid path in that
folder tree, for the program, gives with "found", and no other text as
the text of the content.

### 4.5 No text of a content with another result

@req omit-texts-of-other-results=v1
@cites {
    #{folder-tree=v1, regular-file=v1, path=v1, file-read=v1},
    text#{conforming-program=v1, result=v1, text=v1, requirement=v1},
}

When it reads a text as a path in a folder tree and gives a result other
than "found", a conforming program must give, in that file read, no text
as the text of the content of a regular file.

### 4.6 No symbolic link followed

@req follow-no-symbolic-links=v1
@cites {
    #{folder-tree=v1, symbolic-link=v1, file-read=v1},
    text#{conforming-program=v1, text=v1, requirement=v1},
}

In each file read of a text in a folder tree, a conforming program must
follow no symbolic link that is a file of the folder tree: it must find
no file by the reference of such a symbolic link.

### 4.7 Bytes only from the files that the path names

@req read-only-named-files=v1
@cites {
    #{
        folder-tree=v1, folder=v1, regular-file=v1, taken-byte=v1,
        path=v1, file-read=v1, path-file=v1,
    },
    text#{conforming-program=v1, text=v1, byte=v1, requirement=v1},
}

For each file read of a text in a folder tree, a conforming program must
take bytes only from the folders of the path of that text in that folder
tree and from the regular file that the last file name of that text
names in that folder tree; for a text that is not a valid path, it must
take none.

### 4.8 No wait for another process

@req avoid-waits=v1
@cites {
    #{folder-tree=v1, file-of-another-kind=v1, file-read=v1},
    text#{conforming-program=v1, text=v1, requirement=v1},
}

In each file read of a text in a folder tree, a conforming program must
not wait for another process or for a device to act on a file of another
kind that is a file of the folder tree, such as for a process to open
the other end of a pipe.

### 4.9 No change to the files of the folder tree

@req keep-folder-trees-unchanged=v1
@cites {
    #{
        file-system=v1, folder-tree=v1, folder=v1, regular-file=v1,
        symbolic-link=v1, file-of-another-kind=v1, attribute=v1,
        file-read=v1,
    },
    text#{conforming-program=v1, text=v1, requirement=v1},
}

In each file read of a text in a folder tree, a conforming program must
change no file of the folder tree: not the content of a regular file,
the folder entries of a folder, the reference of a symbolic link, the
data of a file of another kind, or an attribute of a file, such as its
mode, its owner, its times, or its extended attributes, other than by a
change that the file system makes by itself when the program uses that
file, such as a change of the time of last access.

### 4.10 No permission or privilege that the process did not have

@req gain-no-privileges=v1
@cites {
    posix/2024,
    #{system=v1, folder-tree=v1, file-read=v1},
    text#{conforming-program=v1, text=v1, requirement=v1},
}

In each file read of a text in a folder tree, a conforming program must
use only the permissions and the appropriate privileges, as POSIX.1-2024
defines these, such as a capability on a system that gives capabilities
to processes, that its process has without a change by the program: not
one that it gets by a change of the user IDs, the group IDs, or the
appropriate privileges of its process, or through another process that
acts for it.

### 4.11 The validation of texts as globs

@req validate-globs=v1
@cites {
    #{glob=v1},
    text#{
        conforming-program=v1, result=v1, text=v1, production=v1,
        code-span=v1, requirement=v1,
    },
}

In each validation of a text as a glob that it makes, which is an
operation to give one of the results "valid" and "invalid" for whether
the text is a valid glob, also when the program gives another thing in
it, or nothing, a conforming program must give exactly one result:
"valid" when the text matches `glob`, and "invalid" when the text does
not match `glob`.

### 4.12 Whether valid paths fit valid globs

@req decide-glob-fit=v1
@cites {
    #{glob=v1, path=v1, glob-fit=v1},
    text#{conforming-program=v1, result=v1, requirement=v1},
}

Each time it decides whether a valid path fits a valid glob, which is an
operation to give one of the results "fits" and "does not fit" for
whether that valid path fits that valid glob, also when the program
gives another thing in it, or nothing, a conforming program must give
exactly one result: "fits" when the valid path fits the valid glob, and
"does not fit" when the valid path does not fit the valid glob.

### 4.13 The validation of path sets

@req validate-path-sets=v1
@cites {
    #{path-set=v1, valid-path-set=v1},
    text#{conforming-program=v1, result=v1, requirement=v1},
}

In each validation of a path set that it makes, which is an operation to
give one of the results "valid" and "invalid" for whether the path set
is valid, also when the program gives another thing in it, or nothing, a
conforming program must give exactly one result: "valid" when the path
set is valid, and "invalid" when the path set is not valid.

### 4.14 Whether valid paths are in the sets of path sets

@req decide-path-set-membership=v1
@cites {
    #{path-set=v1, glob=v1, path=v1, path-set-membership=v1},
    text#{conforming-program=v1, result=v1, text=v1, requirement=v1},
}

Each time it decides whether a valid path is in the set of a path set in
which the glob text of each path set member is a valid glob, which is an
operation to give one of the results "in the set" and "not in the set"
for whether that valid path is in the set of that path set, also when
the program gives another thing in it, or nothing, a conforming program
must give exactly one result: "in the set" when the valid path is in the
set of the path set, and "not in the set" when the valid path is not in
the set of the path set.

## 5. Conformance

A program, or a part of a program, conforms to this design when it
meets every requirement of the section Requirements.

The vectors of this design are in the file
[`files.test-vectors.jsonl`](files.test-vectors.jsonl), the vector
file, in the same directory as this design. A vector is an input and
what a conforming program gives for it. Each vector follows from the
requirements and adds nothing to them. The person or the program that
runs the vectors, and compares what a program gives with them, is the
runner. The vectors are in groups. Each group has a name, such as
`paths`, and a subsection below. The subsection names the requirements
that the vectors of the group follow from, and it describes their
inputs, results, and values. Each vector of a group follows from one or
more of these requirements. Section 5.7 gives setups in which a
conforming program reads a text as a path, and what it does not do in
these file reads. The setups are not vectors, and the vector file does
not hold them.

The vector file is valid UTF-8. Its text does not start with U+FEFF, it
holds no carriage return, and it ends with a line feed. Each line of the
text of the vector file is a JSON text, as RFC 8259 defines it, that
holds one JSON object. No JSON object of the vector file has two members
with the same name. Only a line feed ends a line of the vector file. A
JSON string of the vector file can hold U+0085, U+2028, or U+2029, and
these characters do not end a line. The vector file has three kinds of
line, in this order:

1. The first line is the set line. Its JSON object has one member,
   `rev`: the revision of the whole set of vectors.
2. Then each group has a group line, in this order: `file-reads`,
   `fits`, `globs`, `memberships`, `path-sets`, `paths`. Its JSON object
   has two members: `group`, the name of the group, as a JSON string,
   and `rev`, the revision of the group.
3. Then each vector has a vector line, in increasing order of the
   numbers of the vectors.

The JSON object of a vector line has these members:

- `n`: the number of the vector, a JSON number written as the decimal
  numeral of a whole number from 1 to 9,007,199,254,740,991. No other
  vector of the vector file has this number. A number is given to one
  vector only: when a vector leaves the vector file, no later vector
  gets its number, and a new vector gets a number greater than each
  number before it.
- `rev`: the revision of the vector.
- `group`: the name of the group of the vector, as a JSON string.
- `input`: the inputs of the vector: what a conforming program takes or
  reads. The subsection of each group names these inputs and gives their
  form. The input of a vector can hold more than one input of the
  program: for example, a valid glob and a valid path. In the group
  `file-reads`, the input also stands for conditions on the file read.
- `result`: the result that a conforming program gives for the inputs
  that the subsection of the group names, such as a valid glob and a
  valid path together, as a JSON string that holds the characters of the
  result without its double quotes. Each vector has this member. The
  subsection of each group also names the operations on these inputs in
  which a conforming program gives this result: each validation that it
  makes, each time that it decides, or each file read that it makes. In
  each such operation, under the conditions that the subsection names,
  if any, a conforming program gives this result, and no other result.
- `values`: a JSON object that holds what a conforming program gives, or
  does not give, for the inputs of the vector, other than the result.
  Only the vectors of the group `file-reads` have this member, and its
  subsection gives the members of this JSON object. A vector without the
  member `values` says nothing about what a conforming program gives for
  its inputs, other than the result.
- `needs`: the needs of the vector, as a JSON array of one or more need
  names, each a JSON string. A need is a condition of the run of a
  vector that a runner can be unable to make true and that a need name
  of the vector file names. The need names of the vector file, the same
  for each group, are `long-names`, `names-kept`, `no-privilege`,
  `non-utf-8-names`, and `other-owner`, in this order. Section 5.2 says
  what each need is and when a vector has it; only vectors of the group
  `file-reads` have needs. The array holds each need of the vector once,
  in the order of the need names, and no other name. A vector has this
  member only when it has a need.
- `note`: an explanation of the vector, as a JSON string, which is no
  part of the input, the result, or the values. A vector has this member
  only when it has an explanation.

A revision is a JSON string of `v`, then the decimal numeral of a whole
number of 1 or more, such as `"v1"`. The revision of the set line is the
revision of the whole set, the revision of a group line is the revision
of the group, and the revision of a vector line is the revision of the
vector. A revision rises to a greater number after its `v`. The revision
of a vector rises when its group, its input, its result, or its values
change. The revision of a group rises when a vector joins the group,
leaves it, or changes in it. The revision of the set rises when a vector
joins the set, leaves it, or changes. A group that comes back after it
left gets a revision with a greater number than each revision that it
had before. When the text of this section changes, the revisions of
every vector, every group, and the set rise. A change of the member
`note` or the member `needs` of a vector, and of no other member,
changes no revision. The addition or the removal of one of these members
is such a change. The runner does not need the revisions to run the
vectors.

A vector writes each input and each value in a fixed form. Inside the
members `input` and `values`, each text, byte sequence, whole number,
and sequence has this fixed form, the terms of sections 3.22 and 3.23
give the fixed form of a folder tree and of the pieces of a content, and
section 5.2 gives the fixed form of the pieces of a text:

- A text, such as a valid path, a valid glob, or a path set member, is a
  JSON string whose characters are the characters of the text, in
  order. So the text `a`, U+0000, `.md` is `"a\u0000.md"`, and the empty
  text is `""`.
- A byte sequence, such as an entry name, is a JSON string of hex
  digits: for each byte, in order, the hex digit of the whole-number
  quotient of the byte divided by 16, then the hex digit of the
  remainder. So the byte sequence 0xC3, 0xA9 is `"c3a9"`, and the empty
  byte sequence is `""`.
- A whole number is a JSON number written as its decimal numeral, such
  as `12`.
- A sequence, such as the path set members of a path set, is a JSON
  array of its elements, in order. So the path set with the path set
  members `docs/` and `!docs/old/` is `["docs/","!docs/old/"]`, and the
  empty path set is `[]`.

Each JSON object that a form of this section describes has the members
that the form names, and no other member.

### 5.1 Paths

The group `paths` holds the vectors of the requirement `validate-paths`.
Each vector gives a text and the result that a conforming program gives
when it validates the text as a path.

- `input`: the text.
- `result`: the result of each validation of the text as a path that a
  conforming program makes: "valid" or "invalid".
- `values`: no vector of the group has this member.

In each validation of the text as a path that it makes, a conforming
program gives the result that `result` holds, and no other result.

```
{"group":"paths","input":"docs/guide/a.md","n":2,"result":"valid","rev":"v1"}
{"group":"paths","input":"docs/../a.md","n":17,"note":"`..` is not a file name","result":"invalid","rev":"v1"}
```

### 5.2 File reads

The group `file-reads` holds the vectors of the requirements
`give-invalid-for-non-paths`, `give-file-read-results`,
`give-file-text`, and `omit-texts-of-other-results`. Each vector gives a
text and a folder tree, and what a conforming program gives when it
reads the text as a path in the folder tree.

- `input`: a JSON object with two members: `text`, the text, and `tree`,
  the folder tree, as a folder tree object (section 3.23). The input
  stands for the text and the folder tree of a file read in which these
  conditions hold:
  1. A file system stores the folder tree of `tree`, for the process of
     the program, as section 3.24 defines it, from the time at which the
     runner has made the folder tree to the end of the file read. So the
     program has the permissions that `tree` states.
  2. No other process changes the folder tree during the file read.
  3. The system does not fail during the file read. This condition
     excludes only failures of the system. An error that the system
     gives because a name or a pathname that the program passes to the
     system is longer than the system or the file system allows, or
     because the file system does not accept a name as an entry name, is
     not a failure of the system, so the condition does not exclude such
     an error.
  4. No other process opens a pipe of the folder tree during the file
     read.

  The runner makes these conditions true, or it skips the vector, as the
  needs below allow.
- `result`: the result of each file read of the text in the folder tree
  that a conforming program makes under these conditions: "invalid",
  "found", "no file", "symbolic link", "not a regular file", "not
  UTF-8", or "cannot read".
- `values`: what a conforming program gives, or does not give, as the
  text of the content in such a file read. With the result "found", a
  JSON object with one member, `text`: the text of the content, as
  pieces of a text (below). With each other result, the empty JSON
  object, `{}`.

In each file read of the text in the folder tree that it makes under
these conditions, a conforming program gives the result that `result`
holds, and no other result. With the result "found", it gives the text
that `text` holds as the text of the content, and no other text as the
text of the content. When `values` is `{}`, it gives no text as the
text of a content. A conforming program gives exactly one result in each
file read, also when no process opens a pipe of the folder tree. So
when a file read has given no result after a time that the runner
chooses, the runner judges that the program did not give the result
that `result` holds.

`tree` is a folder tree object (section 3.23): a file object (section
3.22) whose member `type` is `"directory"`, with the file objects, the
entry objects, and the pieces of a byte sequence of the files of the
folder tree. For example, the reference `b.md` of a symbolic link, which
is `"622e6d64"`, leads to the file of the folder entry `b.md` of the
folder that holds the symbolic link, and the reference `.`, which is
`"2e"`, leads to that folder.

The text in `values` stands as pieces of a text, so that a long text can
stand in a short line, as a long content does. The pieces of a text are
the same as the pieces of a byte sequence of a file object, with the
member `text`, a text, in place of `bytes`. So
`[{"text":"hi","times":1}]` is the text `hi`, and `[]` is the empty
text. Different lists of pieces can give the same byte sequence:
`[{"bytes":"6161","times":1}]`, `[{"bytes":"61","times":2}]`, and
`[{"bytes":"61","times":1},{"bytes":"61","times":1}]` all give the
content 0x61, 0x61. Lists of pieces that give the same text stand for
the same text. So the runner compares the byte sequences and the texts
that the pieces give, and not the pieces.

Some file systems change entry names, add folder entries of their own,
or do not allow some entry names. For example, a file system that
changes each entry name into a decomposed form of Unicode normalization
lists the entry name 0x63, 0x61, 0x66, 0xC3, 0xA9, 0x2E, 0x6D, 0x64 of
vector 30 as 0x63, 0x61, 0x66, 0x65, 0xCC, 0x81, 0x2E, 0x6D, 0x64, so it
does not store the folder tree of vector 30. Some file systems do not
allow the entry name 0xE9 of vector 41, so they do not store the folder
tree of vector 41. Some file systems allow fewer than 250 bytes in an
entry name, so they do not store the folder tree of vector 26. Whether a
file system stores a folder tree also depends on the process of the
program: a process that has an appropriate privilege, as POSIX.1-2024
defines it, that gives it a permission that a file object takes away
does not have the permissions that the file object gives. The result and
the values of a vector are the same on every file system that stores its
folder tree.

A need of a vector is a condition of its run that a runner can be unable
to make true and that a need name of the vector file names: a condition
on the file system that holds the folder tree, on the process of the
program, or on the owners of the files of the folder tree. These are the
need names of the vector file, what each need is, and when a vector has
it. No other need name stands in the vector file, and a name in the
member `needs` that is not one of these need names allows no skip.

- `long-names`: the folder tree is on a file system that allows each
  entry name of the folder tree, with all its bytes. A vector has this
  need when an entry name of its folder tree has more than 14 bytes, the
  least number of bytes in a filename that POSIX.1-2024 lets a system
  allow (`{_POSIX_NAME_MAX}`), such as the entry names of 250 bytes of
  vector 26.
- `names-kept`: the folder tree is on a file system that keeps each
  entry name of the folder tree as the runner makes it, byte for byte:
  for example, the file system does not change an entry name into a
  decomposed form of Unicode normalization. A vector has this need when
  an entry name of its folder tree is valid UTF-8 and holds a byte of
  0x80 or more, such as the entry name 0x63, 0x61, 0x66, 0xC3, 0xA9,
  0x2E, 0x6D, 0x64 of vector 30.
- `no-privilege`: the process of the program has no appropriate
  privilege, as POSIX.1-2024 defines it, that gives it a permission that
  a file object of the folder tree takes away. A vector has this need
  when a file object of its folder tree has the member `read`, `search`,
  or `write` with the value `false`, as in vectors 49 to 56.
- `non-utf-8-names`: the folder tree is on a file system that keeps each
  entry name of the folder tree that is not valid UTF-8 as the runner
  makes it, byte for byte. A vector has this need when an entry name of
  its folder tree is not valid UTF-8, such as the entry name 0xE9 of
  vector 41.
- `other-owner`: each file of the folder tree whose file object has the
  member `owned-by-other` with the value `true` has an owner whose user
  ID differs from the effective user ID of the process of the program. A
  vector has this need when a file object of its folder tree has the
  member `owned-by-other` with the value `true`, as in vector 57.

A vector of the group `file-reads` has the member `needs` when, and only
when, it has one or more of these needs, and the member names each need
of the vector and no other. A vector of another group has no need. For
each vector that it does not skip, the runner uses a file system that
stores its folder tree, and a process of the program for which the
conditions of its input hold. The runner can skip a vector only when it
cannot make true a need that the member `needs` of the vector names.
When it skips a vector, it reports the number of the vector and each
such need. Any other skip of a vector makes the run of the vectors fail,
as when the program does not give the result of a vector.

```
{"group":"file-reads","input":{"text":"a.md","tree":{"entries":[{"file":{"content":[{"bytes":"6869","times":1}],"type":"regular file"},"name":"612e6d64"}],"type":"directory"}},"n":20,"result":"found","rev":"v1","values":{"text":[{"text":"hi","times":1}]}}
{"group":"file-reads","input":{"text":"a.md","tree":{"entries":[{"file":{"reference":"622e6d64","type":"symbolic link"},"name":"612e6d64"},{"file":{"content":[{"bytes":"6869","times":1}],"type":"regular file"},"name":"622e6d64"}],"type":"directory"}},"n":34,"result":"symbolic link","rev":"v1","values":{}}
{"group":"file-reads","input":{"text":"docs/a.md","tree":{"entries":[{"file":{"entries":[{"file":{"content":[{"bytes":"6869","times":1}],"type":"regular file"},"name":"612e6d64"}],"search":false,"type":"directory"},"name":"646f6373"}],"type":"directory"}},"n":51,"needs":["no-privilege"],"note":"the program has no search permission for folder 2, `docs`","result":"cannot read","rev":"v1","values":{}}
```

### 5.3 Globs

The group `globs` holds the vectors of the requirement `validate-globs`.
Each vector gives a text and the result that a conforming program gives
when it validates the text as a glob.

- `input`: the text.
- `result`: the result of each validation of the text as a glob that a
  conforming program makes: "valid" or "invalid".
- `values`: no vector of the group has this member.

In each validation of the text as a glob that it makes, a conforming
program gives the result that `result` holds, and no other result.

```
{"group":"globs","input":"docs/**/*.md","n":111,"result":"valid","rev":"v1"}
{"group":"globs","input":"src/**.ts","n":156,"note":"`**` in a glob segment that holds other characters too","result":"invalid","rev":"v1"}
```

### 5.4 Valid paths that fit valid globs

The group `fits` holds the vectors of the requirement `decide-glob-fit`.
Each vector gives a valid glob and a valid path, and the result that a
conforming program gives when it decides whether the valid path fits the
valid glob. The group `globs` holds a vector of each valid glob of the
group `fits`, with the result "valid".

- `input`: a JSON object with two members: `glob`, the valid glob, and
  `path`, the valid path. Each is a text.
- `result`: the result of each operation in which a conforming program
  decides whether the valid path fits the valid glob: "fits" or "does
  not fit".
- `values`: no vector of the group has this member.

Each time it decides whether the valid path fits the valid glob, a
conforming program gives the result that `result` holds, and no other
result.

```
{"group":"fits","input":{"glob":"docs/**","path":"docs/a/b.md"},"n":89,"result":"fits","rev":"v1"}
{"group":"fits","input":{"glob":"docs/**","path":"docs"},"n":90,"result":"does not fit","rev":"v1"}
```

### 5.5 Path sets

The group `path-sets` holds the vectors of the requirement
`validate-path-sets`. Each vector gives a path set and the result that a
conforming program gives when it validates the path set.

- `input`: the path set, as the sequence of its path set members.
- `result`: the result of each validation of the path set that a
  conforming program makes: "valid" or "invalid".
- `values`: no vector of the group has this member.

In each validation of the path set that it makes, a conforming program
gives the result that `result` holds, and no other result.

```
{"group":"path-sets","input":["docs/","!docs/old/"],"n":169,"result":"valid","rev":"v1"}
{"group":"path-sets","input":["!docs/"],"n":190,"note":"no plain member","result":"invalid","rev":"v1"}
```

### 5.6 Valid paths in the sets of path sets

The group `memberships` holds the vectors of the requirement
`decide-path-set-membership`. Each vector gives a path set in which the
glob text of each path set member is a valid glob, a valid path, and the
result that a conforming program gives when it decides whether the valid
path is in the set of the path set. The path set need not be valid. The
group `path-sets` holds a vector of each path set of the group
`memberships`.

- `input`: a JSON object with two members: `path-set`, the path set, as
  the sequence of its path set members, and `path`, the valid path, as a
  text.
- `result`: the result of each operation in which a conforming program
  decides whether the valid path is in the set of the path set: "in the
  set" or "not in the set".
- `values`: no vector of the group has this member.

Each time it decides whether the valid path is in the set of the path
set, a conforming program gives the result that `result` holds, and no
other result.

```
{"group":"memberships","input":{"path":"docs/a.md","path-set":["docs/","!docs/old/"]},"n":170,"result":"in the set","rev":"v1"}
{"group":"memberships","input":{"path":"a/b","path-set":["a/","a/"]},"n":193,"result":"in the set","rev":"v1"}
```

### 5.7 Setups for the guarantees

Each setup gives a folder tree, a text that a conforming program reads
as a path in that folder tree, what a conforming program gives, and what
it does not do. A setup gives its folder tree in words, and these
conventions hold for each setup:

- The files of the folder tree are only the root and the files that the
  setup names. A file that a setup names with a text, such as the
  regular file `a.md`, is the file of a folder entry whose entry name is
  the UTF-8 encoding of that text. The root holds each such file, unless
  the setup names the folder that holds it. A content that a setup
  writes as a text, such as the text `hi`, is the UTF-8 encoding of that
  text. A pipe is a FIFO special file.
- Unless a setup says otherwise, the program has the search permission
  for each folder of the folder tree, and the read permission for each
  regular file and each folder of the folder tree, as in a file object
  of the group `file-reads` without the members `read` and `search`.
- The system does not fail during the file read. The folder tree does
  not change during the file read, except in a setup that says that
  another process changes it.
- A writer of a pipe is a process that asks to open the pipe for
  writing, and that waits until a process opens the pipe for reading.

These are the setups:

- The symbolic link `d`, whose reference leads to a folder outside the
  folder tree, which holds the pipe `p`, with a writer of `p`; the text
  `d/p`: "symbolic link". The program follows no symbolic link, so it
  does not find `p` by the reference of `d`, and after the file read the
  writer still waits.
- The pipe `p`, and no process that opens `p`; the text `p`: "not a
  regular file". The program does not wait for a process to open the
  other end of `p`, so the file read ends.
- The folder `docs`, which holds the regular file `a.md`, whose content
  is the text `hi`, and the folder `s`, which holds the regular file
  `a.md`, whose content is the text `secret`; the text `docs/a.md`;
  during the file read, another process replaces the folder `docs` with
  a symbolic link whose reference leads to the folder `s`. No
  requirement fixes the result. The program follows no symbolic link, so
  it takes no byte from the regular file `a.md` in `s`.
- The folder `docs`, for which the program has neither the read
  permission nor the search permission, and which holds the regular file
  `a.md`, whose content is the text `hi`; the text `docs/a.md`: "cannot
  read". In the file read, the program does not change the mode or the
  owner of `docs`, and it gets no permission for `docs` by a change of
  the user IDs or the group IDs of its process.
- Any folder tree, and any text: in the file read, the program does not
  change the content, the folder entries, the reference, or an attribute
  of a file of the folder tree, such as its mode or its owner, other
  than by a change that the file system makes by itself when the program
  uses that file, such as a change of the time of last access.
