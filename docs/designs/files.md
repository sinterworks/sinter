<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Files and paths
@design files=v1
@cites text=v1
@cites rfc/5234
@cites rfc/7405
@cites posix/2024
Specifies trees and files; valid paths; file reads of texts as paths in trees, and their results; valid globs, and the valid paths that fit them; path sets, and the valid paths in their sets; and requirements for conforming programs that test texts, valid paths, valid globs, and path sets, and that make file reads.

A tree is a folder, its root, with every file under it. A valid path,
such as `docs/guide/a.md`, is one or more file names joined by `/`. A
file read looks up a valid path in a tree one file name at a time, from
the root, and gives the text of the regular file that it finds. A valid
glob, such as `docs/**/*.md`, is a pattern for valid paths. A path set
is a finite sequence of texts, its path set members, such as `docs/`
followed by `!docs/old/`. A path set can give a set of valid paths.

The productions in the section Definitions are productions as Text and
notation defines them: rules of ABNF, the notation of RFC 5234, with the
case-sensitive strings of RFC 7405.

From Text and notation, the design takes characters, texts, places,
runs, bytes, byte sequences, UTF-8, the notation of productions,
conforming programs, inputs, and results. From POSIX.1-2024, the design
takes files and what a file system is; the file types, such as a
directory, a regular file, and a symbolic link; the directory entries of
a directory, and the names `.` and `..` in a directory; hard links; the
search permission, the read permission, and the write permission of a
process for a file, and the owner of a file; and the function `openat`,
a call of which looks up one or more names and opens the file that it
finds, with its flag `O_SEARCH`, with which a call opens a directory for
search only.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [system](sinter:#system=v1) | the computer that executes a program, together with the operating system of that computer, and not the program, nor the libraries and the runtime that the program uses |
| [file system](sinter:#file-system=v1) | the part of the system that holds files, as POSIX.1-2024 defines a file system, and that acts on those files when a program asks it to, such as to look for a folder entry of a folder, or to give the bytes of a regular file |
| [tree](sinter:#tree=v1) | a folder, its root, with the file of each folder entry of the root and of each folder of the tree |
| [root](sinter:#tree=v1) | the folder at the top of a tree |
| file | a file as POSIX.1-2024 defines a file: a folder, a regular file, a symbolic link, or a file of another kind |
| [file type](sinter:#file-kind=v1) | the type of a file on a file system, such as a directory or a regular file, as POSIX.1-2024 defines the file types; it gives the kind of the file |
| [folder](sinter:#folder=v1) | a file that holds folder entries; POSIX.1-2024 calls it a directory |
| [folder entry](sinter:#folder=v1) | an entry name and a file, which a folder holds: a directory entry of POSIX.1-2024 other than `.` and `..` |
| [entry name](sinter:#folder=v1) | the byte sequence that names a folder entry |
| [hold a file](sinter:#folder=v1) | a folder holds a file when, and only when, that file is the file of a folder entry of the folder |
| [regular file](sinter:#regular-file=v1) | a file that holds a content |
| [content](sinter:#regular-file=v1) | the byte sequence that a regular file holds |
| [symbolic link](sinter:#symbolic-link=v1) | a file that holds a reference, which can lead to a file or to no file, such as a link that `ln -s` makes |
| [file of another kind](sinter:#file-of-another-kind=v1) | a file that is not a folder, a regular file, or a symbolic link, such as a pipe, a character special file, a block special file, or a socket |
| [valid path](sinter:#path=v1) | a text of one or more file names, with `/` between each two of them, such as `docs/a.md` |
| [file name](sinter:#path=v1) | one of the texts of which a valid path is made, such as `docs` or `a.md` in `docs/a.md`; the file names of a valid path have numbers from 1, in order: `docs` is file name 1 of `docs/a.md`; a file name is a text, and an entry name is a byte sequence |
| [lookup](sinter:#lookup=v1) | an action of a program, or a part of one, in which the file system that holds a folder looks for a folder entry of the folder for a byte sequence; the lookups that the file system makes to complete it, in folders that the action does not name, are part of it; a lookup finds the file of a folder entry only when the file system finds that folder entry and its entry name is that byte sequence; one action can make several lookups |
| union file system | a file system whose folders each show, as one folder, the folder entries of several folders of other file systems |
| ignore case | treat two names that differ only in the case of their letters, such as `a.md` and `A.md`, as one name |
| Unicode normalization | a change of a text into a standard form of Unicode, such as the change of `e` and U+0301 into U+00E9; a file system that ignores Unicode normalization treats two names that differ only in this way as one name |
| [fold names](sinter:#name-folding-folder=v1) | a folder folds names when, and only when, there are two different byte sequences s and t such that, when the folder holds a folder entry whose entry name is t, the file system can find that folder entry in a lookup of s in that folder, as in a folder of a file system that ignores case or Unicode normalization; this does not depend on the folder entries that the folder holds |
| [refused](sinter:#refused-lookup=v1) | a lookup, as a step of a file read, is refused when, and only when, the file system reports for it a failure other than that the folder holds no folder entry for the byte sequence; when the file system treats the byte sequence as the name `.` or `..`; or when the folder folds names and the program does not take the entry names of the folder, as a step of the file read, because it has no read permission for the folder, or because the action that takes them fails for too many open files, because the system does not give the program the memory that the action needs, or for an input or output error |
| [open](sinter:#open=v1) | an open of a file is an action in which a program asks the file system to open the file: to give the program a means by which it can ask for the bytes of the file or make lookups in it; an action that both makes lookups and opens the file that the last of them finds is these lookups followed by an open |
| [search permission](sinter:#search-permission=v1) | the permission of a program, as POSIX.1-2024 defines it, to look up folder entries in a folder |
| [read permission](sinter:#read-permission=v1) | the permission of a program, as POSIX.1-2024 defines it, to take bytes from a regular file or the entry names of a folder |
| [take bytes from a file](sinter:#taken-byte=v1) | copy into the program a byte that the file holds or gives: a byte of the content of a regular file, of the entry names of a folder, of the reference of a symbolic link, or of the data of a file of another kind; copying the file type or another attribute of a file takes no bytes from it |
| [request](sinter:#request=v1) | an action in which a program asks the file system for one or more bytes of the content of a regular file that the program has open, in their order in the content; the first byte of the request is the first of these bytes; an action that maps the content into the memory of the program is not a request |
| [end of the content](sinter:#request=v1) | what the file system reports for a request when, and only when, it gives no byte and reports no error for that request; it is not a failure |
| [read a text as a path in a tree](sinter:#file-read=v1) | give, for the text and the tree, one of the results "invalid", "found", "no file", "symbolic link", "not a regular file", "not UTF-8", and "cannot read" |
| [file read](sinter:#file-read=v1) | one operation of a program that reads a text as a path in a tree in which a file system holds each folder |
| [step of a file read](sinter:#file-read=v1) | each action that the program makes, from the start of the file read to its result, with the text of the file read, with the root of the tree, or with a file that a step of that file read finds, except an action that the program makes only for another file read, as a step of that other file read, and not with the text of the file read; each lookup that the program makes during the file read to reach the root, the first time or again, is a step of it; the lookups by which the program opened the root before the file read started are not steps of it |
| [fail to take the content](sinter:#failure-to-take-content=v1) | in a file read, a program fails to take the content of a regular file when, and only when, it stops taking bytes from the regular file, as steps of the file read, for one of three reasons, unless the file system reported the end of the content for the latest request of the program, as a step of the file read, for bytes of the regular file; the reasons: the latest open of the regular file, as a step of the file read, failed for a lack of the read permission, for too many open files, because the system does not give the program the memory that the open needs, or for an error of the file system or of the device; on the latest request, as a step of the file read, for the first byte of the content that the program has not taken, the file system reported an error of the file system or of the device that holds the content, such as an input or output error, and not an error that the form of the request causes; or the system does not give the program the memory to keep a byte that the file system gives for such a request |
| [byte sequence that a file read takes](sinter:#file-read-byte-sequence=v1) | when the file system reports the end of the content for the latest request, as a step of a file read, for bytes of a regular file, and a request, as a step of the file read, gave each byte before the first byte of that request: those bytes, each as the latest such request that gave it gave it |
| [file names of a file read](sinter:#file-name-lookup=v1) | the file names of the text of a file read, when that text is a valid path |
| [lookup of a file name](sinter:#file-name-lookup=v1) | a lookup of the UTF-8 encoding of a file name of a file read: of file name 1 in the root, and of each later file name in a folder that a lookup of the file name right before it, as a step of the same file read, found |
| [walk](sinter:#walk=v1) | the lookups that a program makes as steps of a file read |
| [outcome](sinter:#walk=v1) | what a walk gives for a file name, such as regular file or no entry: first, refused, when no lookup of the file name follows the latest open of a folder that a lookup of the file name right before it found, and that open fails for too many open files, because the system does not give the program the memory that the open needs, for an input or output error, or for a lack of the search permission, or when no lookup of the file name follows an action that asks only for the lookup of the file name and fails before that lookup for a cause other than that the system does not accept the form of the action; otherwise, from the latest lookup of that file name; the outcome of a walk is the outcome of the file name with the lowest number that has one |
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
| [test](sinter:#test=v1) | an action of a program of one of five kinds, each of which gives, for an input, one of two results, such as a test of a text as a path, which gives "valid" or "invalid" |
| valid, invalid | the results of a test of a text as a path, of a test of a text as a glob, and of a test of a path set; a file read also gives "invalid", for a text that is not a valid path |

## 2. Files, paths, globs, and path sets

### 2.1 Trees and files

The system of a program is the computer that executes the program,
together with the operating system of that computer. The program, and
the libraries and the runtime that the program uses, are not part of the
system. A file system is the part of the system that holds files, as
POSIX.1-2024 defines a file system, and that acts on those files when a
program asks it to, such as to look for a folder entry of a folder, or
to give the bytes of a regular file. The folders of a tree can be on
more than one file system.

A tree is a folder, its root, together with the file of each folder
entry of the root and the file of each folder entry of each folder of
the tree. Each file is of one of four kinds:

| kind | what the file holds |
|---|---|
| folder | folder entries: each folder entry has an entry name and a file |
| regular file | a content: a byte sequence |
| symbolic link | a reference, which can lead to a file or to no file |
| file of another kind | something that is not a content, folder entries, or a reference, such as the data of a pipe, a character special file, a block special file, or a socket |

An entry name is a byte sequence. No two folder entries of one folder
have the same entry name. A folder holds a file when that file is the
file of a folder entry of the folder. In a file read, a lookup of a byte
sequence finds the file of a folder entry only when that byte sequence
is the entry name of that folder entry, on every file system. So, when
the program has the read permission for the root, a file read of `A.md`
in a tree whose root holds only the regular file `a.md` gives "no file",
also on a file system that ignores case.

On a file system, the file type of a file gives its kind, as
POSIX.1-2024 defines the file types. A file of the type directory is a
folder. A file of the type regular file is a regular file. A file of the
type symbolic link is a symbolic link. A file of each other type, such
as a FIFO special file (a pipe), a character special file, a block
special file, or a socket, is a file of another kind.

In POSIX.1-2024, the names `.` and `..` in a directory lead to the
directory itself and to the directory above it. The folder entries of a
folder do not include `.` or `..`. So the name `..` does not make the
folder above the root a file of the tree.

### 2.2 Valid paths

A valid path is one or more file names, with `/` between each two of
them. A file name is a text that is not empty, that holds no `/` and no
U+0000, and that is not `.` or `..`. So a valid path never starts or
ends with `/`, and it never holds two `/` together. The file names of a
valid path have numbers from 1, in order: in `docs/guide/a.md`, file
name 1 is `docs`, and file name 3, the file name with the highest
number, is `a.md`. Two file names of one valid path can be the same
text, as in `a/a`. A file name is a text, not an entry name, which is a
byte sequence: a file read looks up the UTF-8 encoding of each file
name.

A program that tests these texts as paths gives these results:

| text | result |
|---|---|
| `a.md` | "valid": one file name |
| `docs/guide/a.md` | "valid": three file names |
| `.github/workflows/ci.yml` | "valid": a file name can start with `.` |
| `...` | "valid": only `.` and `..` are not file names |
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

To read a text as a path in a tree is to give, for that text and that
tree, one of the results "invalid", "found", "no file", "symbolic
link", "not a regular file", "not UTF-8", and "cannot read". A file read
is one operation of a program that reads a text as a path in a tree in
which a file system holds each folder. In a file read, the program does
these things, in order:

1. The program checks whether the text is a valid path. When the text
   is not a valid path, the file read gives the result "invalid".
2. The program looks up the file names of the valid path one at a time:
   file name 1 in the root, and each later file name in the folder that
   the lookup of the file name right before it found. These lookups are
   the walk of the file read. The walk gets an outcome, such as regular
   file or no entry.
3. When the outcome of the walk is regular file, the program opens the
   regular file that the walk finds and takes the bytes of its content.
4. The file read gives one result, such as "found" with the text of the
   regular file, or "no file".

A step of a file read is each action that the program makes, from the
start of the file read to its result, with the text of the file read,
with the root of the tree, or with a file that a step of that file read
finds. An action that the program makes only for another file read, as
a step of that other file read, is not a step of the file read, unless
the action is with the text of the file read. So, when the program makes
file reads of two different texts in one tree at the same time, an
action that it makes only for one of them, and not with the text of the
other, is not a step of the other.

Each lookup that the program makes during the file read to reach the
root, the first time or again, is a step of the file read. The lookups
by which the program opened the root before the file read started are
not steps of the file read. A lookup that the program makes to reach the
root is not a lookup of a file name of the file read, so a conforming
program opens the root before the file read starts.

A lookup of a byte sequence in a folder is an action of a program, or a
part of one, in which the file system that holds the folder looks for a
folder entry of the folder for that byte sequence, at the moment of the
lookup. The lookups that a file system makes, to complete a lookup, in
folders that the action does not name, such as the folders that a union
file system joins into one folder, are part of that lookup.

A lookup finds no folder entry when the file system reports that the
folder holds no folder entry for the byte sequence. It also finds no
folder entry when the file system finds a folder entry whose entry name
is another byte sequence. A lookup finds the file of a folder entry when
the file system finds that folder entry, and the entry name of that
folder entry is the byte sequence. What the program does with that file
after the lookup does not change what the lookup finds.

A folder folds names when, and only when, there are two different byte
sequences s and t such that, when the folder holds a folder entry whose
entry name is t, the file system that holds the folder can find that
folder entry in a lookup of s in that folder. Whether a folder folds
names does not depend on the folder entries that it holds. Each folder
of a file system that ignores case or Unicode normalization folds names.
In a folder that folds names and holds the folder entry `a.md`, a lookup
of `A.md` finds no folder entry.

A lookup that a program makes as a step of a file read is refused when,
and only when, one of these holds:

- The file system reports, for the lookup, a failure other than that the
  folder holds no folder entry for the byte sequence, such as a failure
  for a lack of the search permission of the program for the folder, or
  for a byte sequence longer than the file system allows in an entry
  name.
- The file system treats the byte sequence as the name `.` or `..`, as a
  file system that ignores a space at the end of a name can do.
- The folder folds names, and the program does not take the entry names
  of the folder, as a step of the file read, because it has no read
  permission for the folder, or because the action that takes them fails
  for too many open files, because the system does not give the program
  the memory that the action needs, or for an input or output error.

In a folder that folds names, the program can learn whether the entry
name of the folder entry that the file system finds is the byte sequence
of the lookup from the bytes of the entry names of the folder. When the
program does not take these bytes, as a step of the file read, for one
of the causes of the third case above, such as a lack of the read
permission for the folder, the lookup is refused, also when the folder
holds a folder entry whose entry name is the byte sequence. The file
read then gives "cannot read".

A lookup follows no symbolic link: when the file of the folder entry is
a symbolic link, the lookup finds that symbolic link.

To open a file is to get from the file system a means by which a
program can ask for the bytes that the file holds or gives, or make
lookups in the file. An open of a file is an action in which a program
asks the file system to open the file. An open fails when the file
system does not give that means. An action in which a program asks the
file system both to make lookups and to open the file that the last of
them finds, such as a call of the function `openat` of POSIX.1-2024, is
these lookups followed by an open. The open is not part of a lookup, so
a failure of the open does not make a lookup refused.

One action can make several lookups. When one action looks for the
folder entries for several byte sequences in turn, the first in a folder
and each later byte sequence in the folder that the action found for the
byte sequence right before it, the action makes one lookup of each byte
sequence, in that order. Example: when `docs` is a folder, a call of
`openat` with the bytes of `docs/a.md` makes the lookup of `docs` in a
folder, and then the lookup of `a.md` in the folder that the lookup of
`docs` found. When such an action follows a symbolic link, each lookup
that it makes to follow the link is a further lookup. Only the following
of a symbolic link makes further lookups. An action that fails before a
file system looks for a folder entry for a byte sequence is not a lookup
of that byte sequence. Example: an action fails in this way when the
program gives it more bytes than the system accepts in one action.

In POSIX.1-2024, the file system can complete a lookup in a folder with
the search permission of the program for that folder and no other
permission of the program. So the permissions of the program for the
file that a lookup finds do not change what the lookup finds. The walk
of a file read can find a file in a folder that does not fold names and
for which the program has the search permission and not the read
permission.

A program takes a byte from a file when it copies into the program a
byte that the file holds or gives: a byte of the content of a regular
file, of the entry names of a folder, of the reference of a symbolic
link, or of the data of a file of another kind. A lookup takes no bytes
from a file. Copying the file type or another attribute of a file, such
as its size, into the program takes no bytes from that file.

A request is an action in which a program asks the file system for one
or more bytes of the content of a regular file that the program has
open, in their order in the content. The first byte of a request is the
first of these bytes. An action that maps the content into the memory of
the program is not a request. The file system reports the end of the
content for a request when, and only when, it gives no byte and reports
no error for that request, such as for a request whose first byte is
past the last byte of the content. The end of the content is not a
failure. A request on which the file system gives fewer bytes than the
request asks for is not a failure either. When the file system gives at
least one byte for a request, that request does not report the end of
the content, so the program asks again, from the next byte.

Only the latest request of the program for bytes of a regular file, as
a step of the file read, counts for the end of the content. So, when
the program asks for bytes again after the file system reports the end
of the content, the program goes on until the file system reports the
end of the content for a later request, or until the program fails to
take the content.

In a file read, a program fails to take the content of a regular file
when it stops taking bytes from it, as steps of the file read, for one
of these reasons, unless the file system reported the end of the
content for the latest request of the program, as a step of the file
read, for bytes of the regular file:

- The latest open of the regular file by the program, as a step of the
  file read, failed for a lack of the read permission of the program
  for the regular file, for too many open files, because the system
  does not give the program the memory that the open needs, or for an
  error of the file system or of the device that holds the content.
- On the latest request of the program, as a step of the file read, for
  the first byte of the content that the program has not taken, the
  file system reported an error of the file system, or of the device
  that holds the content, such as an input or output error. An error
  that the form of the request causes, such as an error for a request
  that the file system does not accept, is not such an error.
- The system does not give the program the memory to keep a byte that
  the file system gives for a request of the program, as a step of the
  file read.

An open of the regular file that fails for another cause, such as an
open that a signal interrupts, is not one of these reasons, so the
program opens the regular file again. A request or an open that fails
does not make the program fail to take the bytes of a regular file when
the program makes it again and the later request gives the byte, or the
later open succeeds. An open or a request of an earlier file read does
not count for a later file read.

When the file system reports the end of the content for the latest
request of the program for bytes of a regular file, as a step of a file
read, and a request of the program, as a step of that file read, gave
each byte before the first byte of that request, the byte sequence that
the file read takes from that regular file is the bytes before the first
byte of that request, in their order in the content. It holds each byte
as the latest request of the program, as a step of the file read, that
gave that byte gave it. Example: a program takes 100 bytes of a content.
Another process then cuts the content to 50 bytes, and the program takes
every byte of the content again, from the first byte. The file system
reports the end of the content for the request whose first byte is
byte 51. So the byte sequence holds 50 bytes, as the later requests
gave them.

For a text that is not a valid path, the program makes no lookup and
takes no bytes from a file as a step of the file read. Each action of
the program with that text, from the start of the file read to its
result, is a step of the file read. So a text such as `../a.md` or
`/etc/passwd` never leads the program out of the tree.

For a valid path, the file names of the file read are the file names of
the valid path. A lookup of a file name is a lookup of the UTF-8
encoding of that file name. So the walk of a file read never finds the
file of a folder entry whose entry name is not valid UTF-8. A lookup of
file name 1 is a lookup in the root, and a lookup of each later file
name is a lookup in a folder that a lookup of the file name right before
it, in the same file read, found. So a lookup of an earlier file read
does not count for a later file read. As a step of the file read, the
program makes no lookup other than these lookups. The walk of the file
read is the lookups that the program makes as steps of the file read.

A file name of the file read can have an outcome. Two kinds of failure
give a file name the outcome refused:

- The latest open of a folder that a lookup of the file name right
  before it found fails for too many open files, because the system does
  not give the program the memory that the open needs, for an input or
  output error, or for a lack of the search permission of the program
  for that folder, and the program makes no lookup of the file name
  after that open. After an open of a folder that fails for another
  reason, such as for a lack of the read permission of the program for
  the folder, the program can still make the lookup of the file name in
  that folder. For example, the program can open the folder with a call
  of `openat` with the flag `O_SEARCH`, which needs only the search
  permission of the program for the folder, and then make the lookup in
  it.
- An action that asks for the lookup of the file name and for no other
  lookup fails before a file system looks for a folder entry for the
  UTF-8 encoding of the file name, and the program makes no lookup of
  the file name after that action. Each cause of such a failure counts,
  except that the system does not accept the form of the action, such as
  a flag that the system does not know. The causes that count include
  that the system does not accept, in one action, as many bytes as that
  UTF-8 encoding holds, and that the system does not give the program
  the memory that the action needs. An action that asks for the lookups
  of several file names and fails in this way, such as an action with
  all the bytes of a long valid path, makes no lookup and gives no
  outcome. The program can still look up each file name with an action
  of its own.

Otherwise, the outcome of a file name comes from the latest lookup of
that file name in the walk: it is the first row of this table whose
condition holds for that lookup.

| outcome | condition |
|---|---|
| refused | the lookup is refused |
| no entry | the lookup finds no folder entry |
| symbolic link | the lookup finds a symbolic link |
| not a folder | the file name does not have the highest number, and the lookup finds a regular file or a file of another kind |
| regular file | the file name has the highest number, and the lookup finds a regular file |
| not a regular file | the file name has the highest number, and the lookup finds a folder or a file of another kind |

When no row holds, the lookup finds a folder, and the file name does not
have the highest number. Then the file name has no outcome, and the
program looks up the file name with the next number in that folder. The
outcome of the walk is the outcome of the file name with the lowest
number that has an outcome. The program looks up file names, as steps of
the file read, until the walk has an outcome. With the outcome regular
file, the walk finds the regular file that the latest lookup of the file
name with the highest number found.

The number of a file name, and not its text, decides whether the file
name has the highest number. Example: in a tree with the regular file
`a`, the lookup of file name 1 of `a/a` finds a regular file, and file
name 1 does not have the highest number. So the outcome of the walk is
not a folder, and the file read gives "no file".

The program can look up a file name more than once. On a tree that does
not change during the file read, the lookups of one file name that are
not refused all find no folder entry, or all find the file of the same
folder entry.

With the outcome regular file, the program opens the regular file that
the walk finds. It takes each byte of the content by requests, in order
from the first byte, until the file system reports the end of the
content for the latest request of the program for bytes of the regular
file, or the program fails to take the content of the regular file in
the file read. So a conforming program sets no limit of
its own on the size of a file. The program makes the open of that
regular file in such a way that the file system can complete the open
with the read permission of the program for the regular file and no
other permission of the program, whoever owns the regular file. The
program makes each open of a folder that a lookup of the walk finds,
such as an open to make lookups in that folder, in such a way that the
file system can complete the open with the search permission or the read
permission of the program for the folder and no other permission of the
program, whoever owns the folder.

The program also takes the bytes of the content after a byte at which
the bytes stop being valid UTF-8, until the end of the content. So a
failure to take the content after such a byte gives the result "cannot
read", and not "not UTF-8".

Another process can change the tree during the file read. As a step of
the file read, the program takes only bytes of the entry names of a
folder in which it makes a lookup of the walk, and bytes of the content
of a regular file that a lookup of the file name with the highest number
found. So a change to the tree during the file read, such as a folder
that a lookup of the walk found and that another process then replaces
with a symbolic link, cannot make the program take bytes of the content
of a regular file that no lookup of the file name with the highest
number found, such as a regular file in the folder that the reference of
that symbolic link leads to. When another process changes the regular
file during the file read, the result comes from the bytes that the
program takes.

The walk never follows a symbolic link. A symbolic link ends the walk,
whatever the number of the file name whose lookup finds it, and the
program takes no bytes from the file that the reference of the link
leads to, or from a regular file in a folder that the reference leads
to. So a valid path cannot lead out of the tree through a symbolic link.
A symbolic link that no lookup of the walk finds does not change the
file read: in a tree with the symbolic link `self`, whose reference
leads to the root, and the regular file `a.md`, the walk of the file
read of `a.md` finds the regular file `a.md`.

When no other process changes the tree during the file read, the
program opens no file of another kind as a step of the file read. The
program can learn the kind of a file from its file type, which an action
that makes a lookup can give without an open of the file. An open of a
file of another kind can act on another process or on a device: for
example, an open of a pipe can let a process that waits for that open
go on.

As a step of a file read, the program does not wait for another process
or for a device to act on a file of another kind, such as for a process
to open the other end of a pipe.

As a step of a file read, the program does not change the content, the
folder entries, or the reference of a file of the tree. From the start
of the file read to its result, the program also does not change, by
any action, whether it has the search permission or the read permission
for a file of the tree.

The file read gives the result of the first row of this table whose
conditions hold. An empty cell sets no condition.

| text | outcome of the walk | regular file that the walk finds | result |
|---|---|---|---|
| not a valid path | | | "invalid" |
| a valid path | refused | | "cannot read" |
| a valid path | no entry | | "no file" |
| a valid path | not a folder | | "no file" |
| a valid path | symbolic link | | "symbolic link" |
| a valid path | not a regular file | | "not a regular file" |
| a valid path | regular file | the program fails to take its content in the file read | "cannot read" |
| a valid path | regular file | the byte sequence that the file read takes from it is not valid UTF-8 | "not UTF-8" |
| a valid path | regular file | the byte sequence that the file read takes from it is valid UTF-8 | "found" |

With the result "found", the file read also gives the text of the byte
sequence that the file read takes from the regular file, and no other
text. The text holds one character for each character that the byte
sequence encodes, in order. The program adds no character, removes no
character, and changes no character. So the text keeps a byte order
mark, keeps each carriage return, and keeps each character in the form
that the byte sequence encodes, with no Unicode normalization. With each
other result, the file read gives no text.

### 2.4 Valid globs

A valid glob is a pattern for valid paths. A valid glob is one or more
texts, its glob segments, with `/` between each two of them, and it can
end with `/`. Each glob segment is `**`, or a text in which `*` stands
for any run of characters inside one file name. When a valid glob ends
with `/`, it has one more glob segment, `**`, after the others (rule
5). The glob segments of a valid glob have numbers from 1, in order. A
valid path fits a valid glob when the valid path has the form that the
valid glob gives, by these rules:

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

### 2.6 Tests and results

A test is an action of a program that gives, for an input, one of two
results. There are five kinds of test:

| test | input | results |
|---|---|---|
| a test of a text as a path | a text | "valid" or "invalid" |
| a test of a text as a glob | a text | "valid" or "invalid" |
| a test of a valid glob and a valid path together | a valid glob and a valid path | "fits" or "does not fit" |
| a test of a path set | a path set | "valid" or "invalid" |
| a test of a valid path against a path set in which the glob text of each path set member is a valid glob | that valid path and that path set | "in the set" or "not in the set" |

A conforming program gives exactly one result for each test that it
makes and for each file read that it makes. A file read gives one of
seven results: "invalid", "found", "no file", "symbolic link", "not a
regular file", "not UTF-8", and "cannot read".

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

A file system is the part of the system that holds files, as
POSIX.1-2024 defines a file system, and that acts on those files when a
program asks it to.

### 3.3 Folders

@term folder=v1
@cites {
    posix/2024,
    #{file-system=v1},
    text#{byte-sequence=v1, text=v1, utf-8-encoding=v1, code-span=v1},
}

A folder is a file that holds folder entries. Each folder entry of a
folder has an entry name, which is a byte sequence, and a file. No two
folder entries of one folder have the same entry name. A folder holds a
file when, and only when, that file is the file of a folder entry of
that folder. The folder entries of a folder on a file system are the
directory entries of that folder, as POSIX.1-2024 defines directory
entries, except each directory entry whose name is the UTF-8 encoding of
the text `.` or of the text `..`.

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

### 3.7 Trees

@term tree=v1
@cites #{folder=v1}

A tree is a folder, its root, together with the file of each folder
entry of the root and the file of each folder entry of each folder of
the tree.

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

### 3.11 Lookups

@term lookup=v1
@cites {
    #{system=v1, file-system=v1, folder=v1, symbolic-link=v1},
    text#{byte=v1, byte-sequence=v1},
}

A lookup of a byte sequence in a folder is an action of a program, or a
part of an action of a program, in which the file system that holds the
folder looks for a folder entry of the folder for that byte sequence, at
the moment of the lookup. The lookups that a file system makes, to
complete a lookup, in folders that the action does not name, such as
the folders that a union file system joins into one folder, are part of
that lookup.

A lookup finds no folder entry when, and only when, the file system
reports that the folder holds no folder entry for the byte sequence, or
the file system finds a folder entry whose entry name is not that byte
sequence. A lookup finds the file of a folder entry when, and only when,
the file system finds that folder entry, and the entry name of that
folder entry is that byte sequence. What the program does with that file
after the lookup does not change what the lookup finds.

A lookup follows no symbolic link: when the file of the folder entry is
a symbolic link, the lookup finds that symbolic link. An action of a
program that looks for the folder entries for several byte sequences in
turn, the first in a folder and each later one in the folder that the
action found for the byte sequence right before it, makes one lookup of
each of these byte sequences, in that order. Each lookup that such an
action makes to follow a symbolic link is a further lookup of that
action. Only the following of a symbolic link makes further lookups. An
action that fails before a file system looks for a folder entry for a
byte sequence, such as an action that fails because the program gives
it more bytes than the system accepts in one action, is not a lookup of
that byte sequence.

### 3.12 Folders that fold names

@term name-folding-folder=v1
@cites {
    #{file-system=v1, folder=v1, lookup=v1},
    text#{byte-sequence=v1},
}

A folder folds names when, and only when, there are two different byte
sequences s and t such that, when the folder holds a folder entry whose
entry name is t, the file system that holds the folder can find that
folder entry in a lookup of s in that folder. Whether a folder folds
names does not depend on the folder entries that it holds.

### 3.13 Opens

@term open=v1
@cites {#{file-system=v1, lookup=v1}, text#{byte=v1}}

To open a file is to get from the file system a means by which a program
can ask for the bytes that the file holds or gives, or make lookups in
the file. An open of a file is an action in which a program asks the
file system to open the file. An open of a file fails when, and only
when, the file system does not give that means to the program. An
action in which a program asks the file system both to make one or more
lookups and to open the file that the last of these lookups finds is
these lookups followed by an open of that file. The open of the file
that a lookup finds is not part of that lookup.

### 3.14 Valid paths

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

### 3.15 File reads

@term file-read=v1
@cites {
    #{
        file-system=v1, folder=v1, tree=v1, lookup=v1, open=v1,
        path=v1,
    },
    text#{text=v1, result=v1},
}

To read a text as a path in a tree is to give, for that text and that
tree, one of the results "invalid", "found", "no file", "symbolic
link", "not a regular file", "not UTF-8", and "cannot read". A file read
is one operation of a program that reads a text as a path in a tree in
which a file system holds each folder. A step of a file read is each
action that the program makes, from the start of the file read to its
result, with the text of the file read, with the root of the tree, or
with a file that a step of that file read finds. An action that the
program makes only for another file read, as a step of that other file
read, is not a step of the file read, unless the action is with the
text of the file read. Each lookup that the program makes during the
file read to reach the root, the first time or again, is a step of the
file read. The lookups by which the program opened the root before the
file read started are not steps of the file read.

### 3.16 Bytes taken from a file

@term taken-byte=v1
@cites {
    #{
        folder=v1, regular-file=v1, symbolic-link=v1,
        file-of-another-kind=v1, file-kind=v1, lookup=v1,
    },
    text#{byte=v1},
}

A byte that a program takes from a file is a byte that the file holds
or gives and that the program copies into the program: a byte of the
content of a regular file, of the entry names of a folder, of the
reference of a symbolic link, or of the data of a file of another kind.
To take bytes from a file is to copy such bytes into the program. A
lookup takes no bytes from a file. Copying the file type or another
attribute of a file into the program takes no bytes from that file.

### 3.17 Refused lookups

@term refused-lookup=v1
@cites {
    #{
        system=v1, file-system=v1, folder=v1, search-permission=v1,
        read-permission=v1, lookup=v1, name-folding-folder=v1,
        open=v1, file-read=v1, taken-byte=v1,
    },
    text#{byte-sequence=v1, text=v1, utf-8-encoding=v1, code-span=v1},
}

A lookup that a program makes as a step of a file read is refused when,
and only when, one of these holds:

- The file system reports, for the lookup, a failure other than that the
  folder holds no folder entry for the byte sequence, such as a failure
  for a lack of the search permission of the program for the folder, or
  for a byte sequence longer than the file system allows in an entry
  name.
- The file system treats the byte sequence as the same name as the UTF-8
  encoding of the text `.` or of the text `..`.
- The folder folds names, and the program does not take the entry names
  of the folder, as a step of that file read, because it has no read
  permission for the folder, or because the action that takes them fails
  for too many open files, because the system does not give the program
  the memory that the action needs, or for an input or output error.

### 3.18 Requests

@term request=v1
@cites {#{file-system=v1, regular-file=v1, open=v1}, text#{byte=v1}}

A request is an action in which a program asks the file system for one
or more bytes of the content of a regular file that the program has
open, in their order in the content. The first byte of a request is the
first of the bytes that the request asks for. An action that maps the
content into the memory of the program is not a request. The file
system reports the end of the content for a request when, and only
when, it gives no byte and reports no error for that request. The end
of the content is not a failure, and a request on which the file system
gives fewer bytes than the request asks for is not a failure.

### 3.19 Failures to take a content

@term failure-to-take-content=v1
@cites {
    #{
        system=v1, file-system=v1, regular-file=v1, read-permission=v1,
        open=v1, taken-byte=v1, request=v1, file-read=v1,
    },
    text#{byte=v1},
}

In a file read, a program fails to take the content of a regular file
when, and only when, it stops taking bytes from that regular file, as
steps of that file read, for one of these reasons, unless the file
system reported the end of the content for the latest request of the
program, as a step of that file read, for bytes of that regular file:

- The latest open of that regular file by the program, as a step of
  that file read, failed for a lack of the read permission of the
  program for that regular file, for too many open files, because the
  system does not give the program the memory that the open needs, or
  for an error of the file system or of the device that holds the
  content.
- On the latest request of the program, as a step of that file read,
  for the first byte of the content that the program has not taken as a
  step of that file read, the file system reported an error of the file
  system, or of the device that holds the content, such as an input or
  output error. An error that the form of the request causes, such as an
  error for a request that the file system does not accept, is not such
  an error.
- The system does not give the program the memory to keep a byte that
  the file system gives for a request of the program, as a step of that
  file read.

### 3.20 The byte sequence that a file read takes

@term file-read-byte-sequence=v1
@cites {
    #{file-system=v1, regular-file=v1, file-read=v1, request=v1},
    text#{byte=v1, byte-sequence=v1},
}

When the file system reports the end of the content for the latest
request of a program for bytes of the content of a regular file, as a
step of a file read, and, for each byte before the first byte of that
request, a request of the program, as a step of that file read, gave
that byte, the byte sequence that the file read takes from that regular
file is the bytes before the first byte of that request, in their order
in the content, each byte as the latest request of the program, as a
step of that file read, that gave that byte gave it.

### 3.21 Lookups of the file names of a file read

@term file-name-lookup=v1
@cites {
    #{tree=v1, folder=v1, lookup=v1, path=v1, file-read=v1},
    text#{text=v1, utf-8-encoding=v1},
}

When the text of a file read is a valid path, the file names of the
file read are the file names of that text. A lookup of file name 1 of
the file read is a lookup of the UTF-8 encoding of file name 1 in the
root of the tree. A lookup of each later file name of the file read is a
lookup of the UTF-8 encoding of that later file name in a folder that a
lookup of the file name right before it, as a step of the same file
read, found.

### 3.22 Walks

@term walk=v1
@cites {
    #{
        system=v1, file-system=v1, folder=v1, regular-file=v1,
        symbolic-link=v1, file-of-another-kind=v1, file-kind=v1,
        search-permission=v1, lookup=v1, open=v1, path=v1,
        file-read=v1, refused-lookup=v1, file-name-lookup=v1,
    },
    text#{byte=v1, utf-8-encoding=v1},
}

The walk of a file read is the lookups that the program makes as steps
of that file read. For each file name of the file read, the outcome of
that file name is the first row of this table whose condition holds,
where the lookup is the latest lookup of that file name in the walk, and
where a row that names the lookup does not hold for a file name that the
walk does not look up:

| outcome | condition |
|---|---|
| refused | the latest open, as a step of the file read, of a folder that a lookup of the file name right before it found fails for too many open files, because the system does not give the program the memory that the open needs, for an input or output error, or for a lack of the search permission of the program for that folder, and the walk holds no lookup of the file name after that open |
| refused | an action, as a step of the file read, that asks for a lookup of the file name and for no other lookup fails before a file system looks for a folder entry for the UTF-8 encoding of the file name, for a cause other than that the system does not accept the form of the action, such as a flag that the system does not know, and the walk holds no lookup of the file name after that action; such a cause can be that the system does not accept, in one action, as many bytes as that UTF-8 encoding holds, or that the system does not give the program the memory that the action needs |
| refused | the lookup is refused |
| no entry | the lookup finds no folder entry |
| symbolic link | the lookup finds a symbolic link |
| not a folder | the file name does not have the highest number, and the lookup finds a regular file or a file of another kind |
| regular file | the file name has the highest number, and the lookup finds a regular file |
| not a regular file | the file name has the highest number, and the lookup finds a folder or a file of another kind |

When no row holds, the file name has no outcome. The outcome of the walk
is the outcome of the file name with the lowest number that has an
outcome. A walk in which no file name has an outcome has no outcome.
With the outcome regular file, the walk finds the regular file that the
latest lookup of the file name with the highest number found.

### 3.23 Valid globs

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

### 3.24 Valid paths that fit valid globs

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

- When the glob segment with the highest number is `**`, a group fits
  that glob segment when, and only when, the group holds one or more
  file names.
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

### 3.25 Path sets

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

### 3.26 Valid path sets

@term valid-path-set=v1
@cites {#{path-set=v1, glob=v1}, text#{text=v1}}

A path set is valid when, and only when, the glob text of each path set
member is a valid glob, no two path set members are the same text, and
at least one path set member is a plain member when the path set holds
at least one path set member.

### 3.27 The set of a path set

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

### 3.28 Tests

@term test=v1
@cites {
    #{path=v1, glob=v1, path-set=v1},
    text#{text=v1, input=v1, result=v1},
}

A test is an action of a program of one of these five kinds:

- To test a text as a path is to give, for that text, one of the
  results "valid" and "invalid".
- To test a text as a glob is to give, for that text, one of the results
  "valid" and "invalid".
- To test a valid glob and a valid path together is to give, for that
  valid glob and that valid path, one of the results "fits" and "does
  not fit".
- To test a path set is to give, for that path set, one of the results
  "valid" and "invalid".
- To test a valid path against a path set in which the glob text of
  each path set member is a valid glob is to give, for that valid path
  and that path set, one of the results "in the set" and "not in the
  set".

The input of a test is what the program tests: the text; the valid glob
and the valid path; the path set; or the valid path and the path set.

## 4. Requirements

### 4.1 Tests of texts as paths

@req test-paths=v1
@cites {
    #{path=v1, test=v1},
    text#{
        conforming-program=v1, result=v1, text=v1, production=v1,
        code-span=v1, requirement=v1,
    },
}

In each test of a text as a path that it makes, a conforming program
must give the result "valid" when the text matches `path`, and the
result "invalid" when the text does not match `path`.

### 4.2 Walks that reach an outcome

@req complete-walks=v1
@cites {
    #{
        tree=v1, lookup=v1, path=v1, file-read=v1,
        file-name-lookup=v1, walk=v1,
    },
    text#{conforming-program=v1, requirement=v1},
}

When it reads a valid path as a path in a tree, a conforming program
must, as steps of the file read, make lookups of the file names of the
file read, or actions that ask for these lookups, until the walk of the
file read has an outcome.

### 4.3 The lookups of a file read

@req limit-lookups=v1
@cites {
    #{tree=v1, lookup=v1, path=v1, file-read=v1, file-name-lookup=v1},
    text#{conforming-program=v1, text=v1, requirement=v1},
}

As a step of a file read of a text as a path in a tree, a conforming
program must make no lookup other than a lookup of a file name of that
file read.

### 4.4 The files from which a file read takes bytes

@req limit-bytes=v1
@cites {
    #{
        tree=v1, folder=v1, regular-file=v1, lookup=v1, taken-byte=v1,
        path=v1, file-read=v1, file-name-lookup=v1, walk=v1,
    },
    text#{conforming-program=v1, text=v1, byte=v1, requirement=v1},
}

As a step of a file read of a text as a path in a tree, a conforming
program must take no byte from a file other than a byte of the entry
names of a folder in which the program makes a lookup of the walk of
that file read, and a byte of the content of a regular file that a
lookup of the file name with the highest number of that file read, in
the walk of that file read, found.

### 4.5 The permissions that an open needs

@req limit-open-permissions=v1
@cites {
    #{
        file-system=v1, folder=v1, regular-file=v1,
        search-permission=v1, read-permission=v1, lookup=v1, open=v1,
        file-read=v1, walk=v1,
    },
    text#{conforming-program=v1, requirement=v1},
}

A conforming program must make each open, as a step of a file read, of
the regular file that the walk of that file read finds, or of a folder
that a lookup of that walk finds, in such a way that the file system can
complete that open with a permission of this list and no other
permission of the program, whoever owns that regular file or that
folder:

- for that regular file, the read permission of the program for it;
- for that folder, the search permission or the read permission of the
  program for it.

### 4.6 The bytes of a regular file

@req take-file-bytes=v1
@cites {
    #{
        file-system=v1, tree=v1, regular-file=v1, taken-byte=v1,
        request=v1, failure-to-take-content=v1, path=v1, file-read=v1,
        walk=v1,
    },
    text#{conforming-program=v1, text=v1, byte=v1, requirement=v1},
}

When the walk of a file read of a text as a path in a tree has the
outcome regular file, a conforming program must, as steps of the file
read, take by requests each byte of the content of the regular file that
the walk finds, in order from the first byte, until the file system
reports the end of the content for the latest request of the program,
as a step of the file read, for bytes of that regular file, or the
program fails to take the content of that regular file in that file
read.

### 4.7 No wait for another process

@req avoid-waits=v1
@cites {
    #{tree=v1, file-of-another-kind=v1, open=v1, path=v1, file-read=v1},
    text#{conforming-program=v1, text=v1, requirement=v1},
}

A conforming program must not, as a step of a file read of a text as a
path in a tree, wait for another process or for a device to act on a
file of another kind, such as for a process to open the other end of a
pipe.

### 4.8 No open of a file of another kind

@req avoid-opens-of-files-of-another-kind=v1
@cites {
    #{tree=v1, file-of-another-kind=v1, open=v1, path=v1, file-read=v1},
    text#{conforming-program=v1, text=v1, requirement=v1},
}

When no other process changes a tree during a file read of a text as a
path in that tree, a conforming program must make no open of a file of
another kind as a step of that file read.

### 4.9 No change to the files of the tree

@req keep-trees-unchanged=v1
@cites {
    #{
        tree=v1, folder=v1, regular-file=v1, symbolic-link=v1, path=v1,
        file-read=v1,
    },
    text#{conforming-program=v1, text=v1, requirement=v1},
}

As a step of a file read of a text as a path in a tree, a conforming
program must not change the content, the folder entries, or the
reference of a file of the tree.

### 4.10 No change to the permissions of the program

@req keep-permissions-unchanged=v1
@cites {
    #{
        tree=v1, search-permission=v1, read-permission=v1, path=v1,
        file-read=v1,
    },
    text#{conforming-program=v1, text=v1, result=v1, requirement=v1},
}

From the start of a file read of a text as a path in a tree to the
result of that file read, a conforming program must not change, by any
action, whether it has the search permission or the read permission for
a file of the tree.

### 4.11 The result of a file read

@req give-file-read-results=v1
@cites {
    #{
        tree=v1, regular-file=v1, failure-to-take-content=v1,
        file-read-byte-sequence=v1, path=v1, file-read=v1, walk=v1,
    },
    text#{
        conforming-program=v1, result=v1, text=v1, byte-sequence=v1,
        valid-utf-8=v1, requirement=v1,
    },
}

When it reads a text as a path in a tree, a conforming program must
give the result of the first row of this table whose conditions hold
for the text, for the outcome of the walk of the file read, and for the
regular file that the walk finds, where an empty cell sets no
condition:

| text | outcome of the walk | regular file that the walk finds | result |
|---|---|---|---|
| not a valid path | | | "invalid" |
| a valid path | refused | | "cannot read" |
| a valid path | no entry | | "no file" |
| a valid path | not a folder | | "no file" |
| a valid path | symbolic link | | "symbolic link" |
| a valid path | not a regular file | | "not a regular file" |
| a valid path | regular file | the program fails to take its content in the file read | "cannot read" |
| a valid path | regular file | the byte sequence that the file read takes from it is not valid UTF-8 | "not UTF-8" |
| a valid path | regular file | the byte sequence that the file read takes from it is valid UTF-8 | "found" |

### 4.12 The text of a file

@req give-file-text=v1
@cites {
    #{
        tree=v1, regular-file=v1, file-read-byte-sequence=v1, path=v1,
        file-read=v1, walk=v1,
    },
    text#{
        conforming-program=v1, result=v1, text=v1, byte-sequence=v1,
        text-of-a-byte-sequence=v1, requirement=v1,
    },
}

When it reads a text as a path in a tree and gives the result "found",
a conforming program must give with that result the text of the byte
sequence that the file read takes from the regular file that the walk
of the file read finds, and no other text.

### 4.13 No text with another result

@req omit-texts-of-other-results=v1
@cites {
    #{tree=v1, path=v1, file-read=v1},
    text#{conforming-program=v1, result=v1, text=v1, requirement=v1},
}

When it reads a text as a path in a tree and gives a result other than
"found", a conforming program must give no text with that result.

### 4.14 Tests of texts as globs

@req test-globs=v1
@cites {
    #{glob=v1, test=v1},
    text#{
        conforming-program=v1, result=v1, text=v1, production=v1,
        code-span=v1, requirement=v1,
    },
}

In each test of a text as a glob that it makes, a conforming program
must give the result "valid" when the text matches `glob`, and the
result "invalid" when the text does not match `glob`.

### 4.15 Tests of valid paths against valid globs

@req test-glob-fit=v1
@cites {
    #{glob=v1, path=v1, glob-fit=v1, test=v1},
    text#{conforming-program=v1, result=v1, requirement=v1},
}

In each test of a valid glob and a valid path together that it makes, a
conforming program must give the result "fits" when the valid path fits
the valid glob, and the result "does not fit" when the valid path does
not fit the valid glob.

### 4.16 Tests of path sets

@req test-path-sets=v1
@cites {
    #{path-set=v1, valid-path-set=v1, test=v1},
    text#{conforming-program=v1, result=v1, requirement=v1},
}

In each test of a path set that it makes, a conforming program must give
the result "valid" when the path set is valid, and the result "invalid"
when the path set is not valid.

### 4.17 Tests of valid paths against path sets

@req test-path-set-membership=v1
@cites {
    #{path-set=v1, glob=v1, path=v1, path-set-membership=v1, test=v1},
    text#{conforming-program=v1, result=v1, text=v1, requirement=v1},
}

In each test that it makes of a valid path against a path set in which
the glob text of each path set member is a valid glob, a conforming
program must give the result "in the set" when the valid path is in the
set of the path set, and the result "not in the set" when the valid path
is not in the set of the path set.

### 4.18 One result for each test and each file read

@req give-one-result=v1
@cites {
    #{file-read=v1, test=v1},
    text#{conforming-program=v1, result=v1, requirement=v1},
}

A conforming program must give exactly one result for each test that it
makes and for each file read that it makes.

## 5. Conformance

A program, or a part of a program, conforms to this design when it
meets every requirement of the section Requirements.

Each vector below gives an input and what a conforming program gives
for it. These conventions apply:

- A vector writes a text as its parts, in order, with commas between
  them. A part is characters between backticks; a space, a tab, a line
  feed, or a carriage return; a U+ numeral, for the character that it
  names; or a part, then "written", a decimal numeral, and "times", for
  that part as many times in a row as the numeral writes. "The empty
  text" is the text of no characters. A note such as "with `é` as
  U+00E9" says which characters a part between backticks holds.
- A vector writes a byte sequence as "the byte" and a 0x numeral, for a
  byte sequence of one byte, or as "the bytes" and its bytes, in order,
  each as a 0x numeral, with commas between them. "The empty byte
  sequence" is the byte sequence of no bytes.
- A list of texts has a semicolon between each two texts, as in `a.md`;
  `b.md`.
- A row of a table gives the input in its first cells and the result in
  its last cell. An item of a list gives the input, then a colon, then
  the result.
- In a result, each of the labels "Fit:", "Do not fit:", "In the set:",
  and "Not in the set:" starts a list of valid paths that the vector
  gives. The list ends at the next label or at the end of the result.
- In a result, the text after each other colon that is not between
  backticks explains the result, up to the next label or the end of the
  result. A conforming program does not give that text.
- A vector of a file read with the result "found" also gives the text
  that a conforming program gives with that result, as in "found, with
  the text `hi`". With each other result of a file read, a conforming
  program gives no text.

### 5.1 Paths

Each row gives a text and the result that a conforming program gives
when it tests the text as a path.

| text | result |
|---|---|
| `a.md` | valid |
| `docs/guide/a.md` | valid |
| `.github/workflows/ci.yml` | valid |
| `...` | valid |
| `..a` | valid |
| `a b/c\d.md` | valid |
| `Docs/A.MD` | valid |
| `a/a` | valid |
| U+00E9, `.md` | valid |
| the empty text | invalid: a valid path holds at least one file name |
| `/a.md` | invalid: it starts with `/` |
| `docs/` | invalid: it ends with `/` |
| `docs//a.md` | invalid: two `/` together |
| `.` | invalid: `.` is not a file name |
| `./a.md` | invalid: `.` is not a file name |
| `docs/../a.md` | invalid: `..` is not a file name |
| `docs/..` | invalid: `..` is not a file name |
| `a`, U+0000, `.md` | invalid: a file name holds no U+0000 |

### 5.2 File reads

Each row gives a tree, a text that a conforming program reads as a path
in that tree, and the result. A file system holds each folder of the
tree. Except in a row with "any tree", the files of the tree are only
the root and the files that the row names. A file that a row writes with
a text, such as the regular file `a.md`, is the file of a folder entry
whose entry name is the UTF-8 encoding of that text. The root holds each
such file, unless the row names the folder that holds it. No other
process changes the tree during the file read. Unless a row says
otherwise, the program has the search permission for every folder of the
tree, and the read permission for every regular file and every folder of
the tree. Unless a row says otherwise, the system gives the program each
open file and all the memory that the program asks for; no lookup, no
open, and no request of the program fails for an error of the file
system or of a device; and no action of the program fails before a file
system looks for a folder entry, other than for the form of the action
or because the action holds more bytes than the system accepts in one
action. A condition on the file system, when a row has one, ends the
description of the tree. A row with no condition on the file system
gives the same result on every file system that can hold the tree. A
content written as "the text" and a text is the UTF-8 encoding of that
text.

| tree | text | result |
|---|---|---|
| the regular file `a.md`, whose content is the text `hi` | `a.md` | found, with the text `hi` |
| the folder `docs`, which holds the regular file `a.md`, whose content is the text `hi` | `docs/a.md` | found, with the text `hi` |
| the regular file `a.md`, whose content is the empty byte sequence | `a.md` | found, with the empty text |
| the regular file `a.md`, whose content is the text `hi` | `b.md` | no file |
| the regular file `a.md`, whose content is the text `hi` | `a.md/b.md` | no file: `a.md` is not a folder |
| the regular file `a`, whose content is the text `hi` | `a/a` | no file: file name 1, `a`, is not a folder |
| a chain of 200 folders, each the folder `ddddddddddddddddddddddddd`, in which the root holds the first folder, each folder except the last holds the next folder, and the last folder holds the regular file `a.md`, whose content is the text `hi` | `ddddddddddddddddddddddddd/` written 200 times, `a.md` | found, with the text `hi`: the valid path holds 5,204 characters, more than many systems accept in one action |
| the regular file `a.md`, whose content is the text `hi` | `A.md` | no file: a lookup finds the file of a folder entry only by its entry name |
| the regular file `café.md`, with `é` as U+00E9, whose content is the text `hi` | `cafe`, U+0301, `.md` | no file: the UTF-8 encoding of the text is not the entry name |
| the folder `docs` | `docs` | not a regular file |
| the pipe `p`, which no process opens | `p` | not a regular file: the program does not open the pipe, and does not wait for a process to open it |
| the symbolic link `a.md`, whose reference leads to the regular file `b.md`, and the regular file `b.md`, whose content is the text `hi` | `a.md` | symbolic link |
| the symbolic link `a.md`, whose reference leads to the regular file `b.md`, and the regular file `b.md`, whose content is the text `hi` | `b.md` | found, with the text `hi` |
| the symbolic link `d`, whose reference leads to the folder `docs`, and the folder `docs`, which holds the regular file `a.md`, whose content is the text `hi` | `d/a.md` | symbolic link |
| the symbolic link `d`, whose reference leads to the folder `docs`, and the folder `docs`, which holds the regular file `a.md`, whose content is the text `hi` | `docs/a.md` | found, with the text `hi` |
| the symbolic link `a.md`, whose reference leads to no file | `a.md` | symbolic link |
| the symbolic link `self`, whose reference leads to the root, and the regular file `a.md`, whose content is the text `hi` | `a.md` | found, with the text `hi` |
| the symbolic link `self`, whose reference leads to the root, and the regular file `a.md`, whose content is the text `hi` | `self/a.md` | symbolic link |
| the folder of the folder entry of the root whose entry name is the byte 0xE9, and the regular file `x` in that folder, on a file system that can hold a folder entry whose entry name is the byte 0xE9 | `é/x`, with `é` as U+00E9 | no file: the UTF-8 encoding of `é` is the bytes 0xC3, 0xA9 |
| the regular file `a.md`, whose content is the bytes 0xFF, 0xFE | `a.md` | not UTF-8 |
| the regular file `a.md`, whose content is the bytes 0xED, 0xA0, 0x80 | `a.md` | not UTF-8: the three-byte form of UTF-8 for 55,296, which is not the code point of a character |
| the regular file `a.md`, whose content is the bytes 0xC0, 0xAF | `a.md` | not UTF-8: an overlong encoding |
| the regular file `a.md`, whose content is the bytes 0xEF, 0xBB, 0xBF, 0x78 | `a.md` | found, with the text U+FEFF, `x` |
| the regular file `a.md`, whose content is the bytes 0x61, 0x0D, 0x0A, 0x62 | `a.md` | found, with the text `a`, a carriage return, a line feed, `b` |
| the regular file `a.md`, whose content is the bytes 0x65, 0xCC, 0x81 | `a.md` | found, with the text `e`, U+0301 |
| the regular file `a.md`, whose content is the text `a` written 16777217 times | `a.md` | found, with the text `a` written 16777217 times: a conforming program sets no limit of its own on the size of a file |
| the folder `docs`, which does not fold names, for which the program has the search permission and not the read permission, and which holds the regular file `a.md`, whose content is the text `hi` | `docs/a.md` | found, with the text `hi` |
| the folder `docs`, which folds names, for which the program has the search permission and not the read permission, and which holds the regular file `a.md`, whose content is the text `hi` | `docs/a.md` | cannot read: the lookup of `a.md` is refused |
| the folder `docs`, which folds names, for which the program has the search permission and not the read permission, and which holds the regular file `a.md`, whose content is the text `hi` | `docs/b.md` | cannot read: the lookup of `b.md` is refused |
| the folder `docs`, for which the program has neither the read permission nor the search permission, and which holds the regular file `a.md`, whose content is the text `hi` | `docs` | not a regular file |
| the folder `docs`, for which the program has neither the read permission nor the search permission, and which holds the regular file `a.md`, whose content is the text `hi` | `docs/a.md` | cannot read: file name 2, `a.md`, has the outcome refused |
| the regular file `a.md`, whose content is the text `hi`, and for which the program has no read permission | `a.md` | cannot read |
| the regular file `a.md`, whose content is the text `hi`, and for which the program has the read permission and not the write permission | `a.md` | found, with the text `hi` |
| the regular file `a.md`, whose content is the text `hi`, which another user owns, and for which the program has the read permission | `a.md` | found, with the text `hi` |
| a tree whose root holds no folder entry, on a file system that allows at most 255 bytes in an entry name | `a` written 300 times | cannot read: file name 1 is longer than the file system allows in an entry name |
| a tree whose root holds no folder entry, on a file system that allows fewer than 5,000 bytes in an entry name | `a` written 5000 times | cannot read: file name 1 is longer than the file system allows in an entry name |
| any tree | `../a.md` | invalid |
| any tree | `/etc/passwd` | invalid |

### 5.3 Globs

Each vector gives a text and the result that a conforming program gives
when it tests the text as a glob. For a valid glob, the vector can also
give, after "Fit:", valid paths for which a conforming program gives the
result "fits" when it tests the valid glob and each of them together,
and, after "Do not fit:", valid paths for which it gives the result
"does not fit".

- `Cargo.lock`: valid. Fit: `Cargo.lock`. Do not fit: `a/Cargo.lock`;
  `cargo.lock`.
- `**/Cargo.lock`: valid. Fit: `Cargo.lock`; `a/b/Cargo.lock`. Do not
  fit: `Cargo.lock.bak`.
- `*.md`: valid. Fit: `a.md`; `.md`; `.notes.md`. Do not fit: `a/b.md`;
  `a.txt`.
- `a.md`: valid. Fit: `a.md`. Do not fit: `aa.md`.
- `*`: valid. Fit: `a`; `.gitignore`. Do not fit: `a/b`.
- `**`: valid. Fit: `a`; `a/b/c`; `.git/x`.
- `docs/**`: valid. Fit: `docs/a.md`; `docs/a/b.md`. Do not fit: `docs`;
  `a/docs/a.md`.
- `docs/`: valid. Fit: `docs/a.md`; `docs/a/b.md`. Do not fit: `docs`.
- `**/`: valid. Fit: `a`; `a/b`.
- `a/**/b`: valid. Fit: `a/b`; `a/x/b`; `a/x/y/b`. Do not fit: `b`;
  `a/b/c`.
- `**/x/**`: valid. Fit: `x/a`; `a/x/b`; `x/x/x`. Do not fit: `x`;
  `a/x`.
- `docs/**/*.md`: valid. Fit: `docs/a.md`; `docs/x/y/a.md`. Do not fit:
  `a.md`; `docs/a.txt`.
- `a*b*c`: valid. Fit: `abc`; `aXbYc`; `abbc`. Do not fit: `ab`; `acb`.
- `*a*`: valid. Fit: `a`; `bab`. Do not fit: `b`.
- `.*`: valid. Fit: `.env`; `...`. Do not fit: `env`.
- `...`: valid. Fit: `...`. Do not fit: `a`.
- `Docs/*`: valid. Fit: `Docs/a.md`. Do not fit: `docs/a.md`.
- `café.md`, with `é` as U+00E9: valid. Fit: `café.md`, with `é` as
  U+00E9. Do not fit: `cafe`, U+0301, `.md`.
- `!x`: valid. Fit: `!x`. Do not fit: `x`.
- `a b`: valid. Fit: `a b`. Do not fit: `ab`.
- `a`, U+0000: valid. Do not fit: `a`.
- the empty text: invalid: a valid glob holds at least one glob segment.
- `/docs`: invalid: it starts with `/`.
- `docs//a.md`: invalid: two `/` together.
- `/`: invalid: it starts with `/`.
- `./a.md`: invalid: the glob segment `.`.
- `docs/..`: invalid: the glob segment `..`.
- `src/**.ts`: invalid: `**` in a glob segment that holds other
  characters too.
- `***`: invalid: `**` in a glob segment that holds other characters
  too.
- `a**`: invalid: `**` in a glob segment that holds other characters
  too.
- `a?.md`: invalid: `?`.
- `[ab].md`: invalid: `[` and `]`.
- `{a,b}.md`: invalid: `{` and `}`.
- `a\b`: invalid: `\`.

### 5.4 Path sets

Each vector gives the path set members of a path set, in order, and the
result that a conforming program gives when it tests the path set. When
the glob text of each path set member is a valid glob, the vector can
also give, after "In the set:", valid paths for which a conforming
program gives the result "in the set" when it tests each of them against
the path set, and, after "Not in the set:", valid paths for which it
gives the result "not in the set".

- no path set member: valid. Not in the set: `a.md`.
- `docs/`: valid. In the set: `docs/a.md`. Not in the set: `a.md`;
  `docs`.
- `docs/`; `!docs/old/`: valid. In the set: `docs/a.md`. Not in the set:
  `docs/old/a.md`; `a.md`.
- `!docs/old/`; `docs/`: valid. In the set: `docs/a.md`. Not in the set:
  `docs/old/a.md`.
- `**`; `!**/*.tmp`: valid. In the set: `a.md`; `x/b.md`. Not in the
  set: `a.tmp`; `x/b.tmp`.
- `a`; `!a`: valid. Not in the set: `a`.
- `**`; `!!x`: valid. In the set: `x`. Not in the set: `!x`.
- `*.md`; `!a.md`; `!b.md`: valid. In the set: `c.md`. Not in the set:
  `a.md`; `b.md`.
- `!docs/`: invalid: no plain member.
- `docs/`; `docs/`: invalid: two path set members are the same text.
- `a/`; `a/`: invalid: two path set members are the same text. In the
  set: `a/b`.
- `docs/`; `!`: invalid: the glob text of `!` is the empty text, which
  is not a valid glob.
- `docs/`; `!/x`: invalid: the glob text of `!/x` starts with `/`.
- `a?`: invalid: the glob text of `a?` holds `?`.
