<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Files and paths
@design files=v1
@cites rfc/3629
@cites rfc/5234
@cites rfc/7405
@cites posix/2024
A program reads the regular file at a path in a tree as a text in UTF-8, with no symbolic link followed, tests paths against globs and path sets, and gives the line number and the column of each character of a text except its byte order mark.

A tree is a folder, its root, with every file under it. A path, such as
`docs/guide/a.md`, names a file of a tree: the file names that lead
from the root to the file, joined by `/`. A glob, such as
`docs/**/*.md`, is a pattern for paths. A path set is a finite sequence
of texts, its members, such as `docs/` and `!docs/old/`, that can give a
set of paths. A position, such as line 3, column 7, is a line number
and a column.

The productions in section 3 are written in ABNF, the notation of
RFC 5234, with the case-sensitive strings of RFC 7405. A production,
such as `path = file-name *( "/" file-name )`, gives the texts that its
name matches. In a production, `/` separates two alternatives. The
quoted string `"/"` is the character `/`. `( )` groups elements, and
`[ ]` makes an element optional. `*` repeats the element after it zero
or more times, `1*` repeats it one or more times, and `3*` repeats it
three or more times. `%x2F` is the character U+002F, and `%x30-3E` is
any one character from U+0030 to U+003E.

From RFC 3629, the design takes UTF-8: how a byte sequence encodes a
text, and the rule `UTF8-octets`, which gives the byte sequences that
are valid UTF-8. From POSIX.1-2024, the design takes what a file system
is; the file types, such as a directory, a regular file, and a symbolic
link; the names `.` and `..` in a directory; and the search
permission and the read permission of a process for a file.

## 1. Terms

| term | meaning |
|---|---|
| conforming program | a program that meets every requirement of section 3 |
| must | states an obligation of a conforming program |
| ABNF | the notation for grammars of RFC 5234, with the case-sensitive strings of RFC 7405 |
| production | a rule of ABNF, such as `path = file-name *( "/" file-name )`, which gives the texts that its name matches |
| character | one Unicode scalar value: a code point that is not from U+D800 to U+DFFF |
| text | a finite sequence of characters |
| place | the number of a character in the order of a text, counted from 1 |
| run | the characters of a text at the places from one place to another, such as `cd` in `abcde`; a run can be empty |
| Unicode normalization | a change of a text into a standard form of Unicode, such as the change of `e` and U+0301 into U+00E9 |
| byte | an integer from 0 to 255 |
| byte sequence | a finite sequence of bytes |
| valid UTF-8 | a byte sequence is valid UTF-8 when it encodes a text in UTF-8, as RFC 3629 defines UTF-8 |
| UTF-8 encoding | the byte sequence that encodes a text in UTF-8 |
| file system | the part of an operating system that keeps files in folders and gives them to programs |
| tree | a folder, its root, with every file under it |
| root | the folder at the top of a tree |
| file | a folder, a regular file, a symbolic link, or a file of another kind |
| file type | the type of a file on a file system, such as a directory or a regular file, as POSIX.1-2024 defines the file types |
| folder | a file that holds entries; POSIX calls it a directory |
| entry | an entry name and a file, which a folder holds |
| entry name | the byte sequence that names an entry of a folder |
| regular file | a file that holds a content |
| content | the byte sequence that a regular file holds |
| symbolic link | a file that holds a reference, which can lead to a file or to no file, such as a link that `ln -s` makes |
| file of another kind | a file that is not a folder, a regular file, or a symbolic link, such as a pipe, a device, or a socket |
| path | one or more file names joined by `/`, such as `docs/a.md` |
| file name | a text that names one entry on a path, such as `docs` or `a.md` in `docs/a.md`; a file name is a text, not the entry name that a lookup of its UTF-8 encoding finds; the file names of a path are numbered from 1, so `docs` is file name 1 of `docs/a.md` |
| lookup | the action in which the file system looks for the entry that a folder gives for a byte sequence, for a program |
| refuse | the file system refuses a lookup when the lookup fails and the file system does not report that the folder gives no entry for the byte sequence |
| search permission | the permission of a program, as POSIX.1-2024 defines it, to look up entries in a folder |
| read permission | the permission of a program, as POSIX.1-2024 defines it, to take bytes from a regular file or the entry names of a folder |
| take bytes from a file | copy into the program any byte that the file holds or gives: the content of a regular file, the entry names of a folder, the reference of a symbolic link, or the data of a file of another kind |
| read a text as a path in a tree | test the text as a path, look up its file names one at a time, the first one in the root and each later one in the folder that the lookup before it found, and give a result, such as "found" with the text of a regular file; a read is one such operation |
| step of a read | an action that a program does to give the result of a read, such as a lookup |
| walk | the lookups that a program makes as steps of a read |
| outcome | what the latest lookup of a file name in a walk gives, such as "regular file" or "no entry"; the outcome of a walk is the outcome of the file name with the lowest number that has one |
| byte order mark | the character U+FEFF when it is at place 1 of a text |
| body | the run of a text without its byte order mark |
| line feed | the character U+000A |
| carriage return | the character U+000D |
| line ending | a line feed of a body, with the carriage return right before it when there is one |
| line | one of the runs into which the line endings divide a body, except an empty run at the end; it holds no line feed |
| position | a line number and a column, such as line 3, column 7 |
| line number | the first number of a position: the number of a line, counted from 1 |
| column | the second number of a position |
| span | a run of a body that holds a character of a line; it has a start and an end |
| glob | a pattern for paths, such as `docs/**/*.md` |
| glob segment | one of the parts of a glob that `/` separates, such as `docs`, `**`, or `*.md` in `docs/**/*.md`, or the `**` that a final `/` adds; the glob segments of a glob are numbered from 1 |
| fit | a path fits a glob when the path has the form that the glob gives |
| path set | a finite sequence of texts, its members, such as `docs/` and `!docs/old/`; when the glob of each member is a valid glob, the path set gives a set of paths |
| member | one text of a path set |
| plain glob | a member that does not start with `!` |
| `!` glob | a member that starts with `!`, such as `!docs/old/` |
| glob of a member | the text after the `!` of a `!` glob, or the whole member for a plain glob; it can be a text that is not a valid glob |
| result | what a conforming program gives for an input, such as "valid" or "found" |
| valid, invalid | the results of a test of whether a text is a valid path or a valid glob, or of whether a path set is valid; a read also gives "invalid" for a text that is not a valid path |

## 2. Files, paths, globs, and positions

### 2.1 Trees and files

A tree is a folder, called the root, together with every file that the
root holds, directly or through other folders. Each file is of one of
four kinds:

| kind | what the file holds |
|---|---|
| folder | entries: each entry has an entry name and a file |
| regular file | a content: a byte sequence |
| symbolic link | a reference, which can lead to a file or to no file |
| file of another kind | something that is not a content, entries, or a reference, such as the data of a pipe, a device, or a socket |

An entry name is a byte sequence. No two entries of one folder have the
same entry name. A folder gives at most one entry for a byte sequence.
On a file system that treats each byte sequence as a different name,
that entry is the entry whose entry name is that byte sequence. On a
file system that treats two different byte sequences as the same name,
such as a file system that ignores case, a folder can instead give the
entry whose entry name the file system treats as the same name: on such
a file system, a folder that holds the entry `a.md` gives that entry
for `A.md`.

On a file system, the file type of a file gives its kind, as
POSIX.1-2024 defines the file types. A file of the type directory is a
folder. A file of the type regular file is a regular file. A file of the
type symbolic link is a symbolic link. A file of each other type, such
as a FIFO special file (a pipe), a character special file, a block
special file, or a socket, is a file of another kind.

In POSIX.1-2024, the names `.` and `..` in a directory lead to the
directory itself and to the directory above it. The entries of a folder
do not include `.` or `..`. So a tree holds no file above its root.

### 2.2 Paths

A path is one or more file names joined by `/`. A file name is a text
that is not empty, that holds no `/` and no U+0000, and that is not `.`
or `..`. So a path never starts or ends with `/`, and it never holds two
`/` together. The file names of a path are numbered from 1, in order:
in `docs/guide/a.md`, file name 1 is `docs`, and file name 3, the file
name with the highest number, is `a.md`. Two file names of one path can
be the same text, as in `a/a`. A file name is a text, not an entry name,
which is a byte sequence: a read looks up the UTF-8 encoding of each
file name.

| text | result |
|---|---|
| `a.md` | "valid": one file name |
| `docs/guide/a.md` | "valid": three file names |
| `.github/workflows/ci.yml` | "valid": a file name can start with `.` |
| `...` | "valid": only `.` and `..` are excluded |
| `a b/c\d.md` | "valid": a space and `\` are characters of a file name |
| the empty text | "invalid" |
| `/a.md` | "invalid": it starts with `/` |
| `docs/` | "invalid": it ends with `/` |
| `docs//a.md` | "invalid": two `/` together |
| `./a.md`, `docs/../a.md` | "invalid": `.` and `..` are not file names |

`/` is the only separator, so `a\b.md` is one file name. `.` and `..`
are not file names, so `docs/../a.md` does not lead to `a.md`: it is not
a path.

A path is a text. Two paths are the same path only when they are the
same text. So case matters: `Docs/a.md` and `docs/a.md` are two
different paths. No Unicode normalization applies, so a path with `é`
written as U+00E9 and a path with `e` and U+0301 are two different
paths, though they look the same.

### 2.3 Reading a file

To read a text as a path in a tree is to give a result for the text in
that tree, such as "found" with the text of a regular file, or "no
file". A read is one such operation of a program.

A lookup of a byte sequence in a folder is the action in which the file
system looks for the entry that the folder gives for that byte sequence
at the moment of the lookup. Exactly one of these holds, by what the
file system reports:

- The lookup finds no entry when the file system reports that the
  folder gives no entry for the byte sequence.
- The file system refuses the lookup when the lookup fails and the file
  system does not report that the folder gives no entry for the byte
  sequence, such as for a lack of the search permission of the program
  for the folder, or for a byte sequence longer than the file system
  allows in an entry name.
- Otherwise, the lookup finds the file of the entry, whatever the
  program does with that file after the lookup. A failure to open
  the file that the lookup finds is not a refusal of the lookup.

A lookup follows no symbolic link: when the file of the entry is a
symbolic link, the lookup finds that symbolic link.

A step of a read is an action that the program does to give the result
of that read, such as a lookup. A read takes the root as a folder that
the program has open when the read starts, such as a folder that the
program opened before its first read. So the lookups by which the
program reaches the root are not steps of the read.

A conforming program makes each lookup of a read in a way that needs no
permission of the program other than the search permission for the
folder of that lookup. So the permissions of the program for the file
that a lookup finds do not change what the lookup finds, and a read can
find a file in a folder for which the program has the search permission
and not the read permission.

To take bytes from a file is to copy into the program any byte that the
file holds or gives: the content of a regular file, the entry names of a
folder, the reference of a symbolic link, or the data of a file of
another kind. A lookup takes no bytes from a file. Taking bytes from a
file fails when the file system does not give the program a byte that
the program asks for, such as for a lack of the read permission of the
program for a regular file, or for an error of the device.

For a text that is not a valid path, the read gives the result
"invalid". The program looks up nothing in the tree and takes no bytes
from a file. So a text such as `../a.md` or `/etc/passwd` never leads
the program out of the tree.

For a valid path, the program looks up the file names of the path one
at a time, from file name 1. A lookup of a file name is a lookup of the
UTF-8 encoding of that file name. A lookup of file name 1 is a lookup in
the root. A lookup of file name 2 is a lookup in a folder that a lookup
of file name 1, in the same read, found. A lookup of file name 3 is a
lookup in a folder that a lookup of file name 2, in the same read,
found, and so on for each later file name. So a lookup of an earlier
read does not count for a later read: each read looks up file name 1 in
the root, and each later file name in a folder that a lookup of that
same read found. As a step of the read, the program makes no lookup
other than these lookups. The walk of the read is the lookups that the
program makes as steps of the read. So no path reaches an entry whose
entry name is not valid UTF-8, except on a file system that treats two
different byte sequences as the same name.

A file name that the walk looks up can have an outcome. The outcome of
a file name comes from the latest lookup of that file name in the walk:
it is the first row of this table whose condition holds for that
lookup.

| outcome | condition |
|---|---|
| "refused" | the file system refuses the lookup |
| "no entry" | the lookup finds no entry |
| "symbolic link" | the lookup finds a symbolic link |
| "not a folder" | the file name does not have the highest number, and the lookup finds a regular file or a file of another kind |
| "regular file" | the file name has the highest number, and the lookup finds a regular file |
| "not a regular file" | the file name has the highest number, and the lookup finds a folder or a file of another kind |

When no row holds, the lookup finds a folder, and the file name does not
have the highest number. Then the file name has no outcome, and the
program looks up the file name with the next number in that folder. The
outcome of the walk is the outcome of the file name with the lowest
number that has an outcome. The program looks up file names, as steps of
the read, until the walk has an outcome. With the outcome "regular
file", the walk finds the regular file that the latest lookup of the
file name with the highest number found.

With the outcome "regular file", the program takes the bytes of the
regular file that the walk finds, in order from its first byte, until
the file system gives no more bytes or taking bytes from the regular
file fails. The program takes these bytes in a way that needs no
permission of the program for the regular file other than the read
permission. So a conforming program sets no limit of its own on the
size of a file.

The program can look up a file name more than once. On a tree that does
not change during the read, each lookup of a file name finds the same
entry, so the outcome of the walk depends only on the tree, the path,
the permissions of the program, and the file system. Example: in a tree
with the regular file `a`, the lookup of file name 1 of `a/a` finds a
regular file, and file name 1 does not have the highest number. So the
outcome of the walk is "not a folder", and the read gives "no file".

Another process can change the tree during the read. As a step of the
read, the program takes bytes only from a regular file that a lookup of
the file name with the highest number found. So a change to the tree
during the read, such as a folder of the path that another process
replaces with a symbolic link, cannot make the program take bytes from a
file that no lookup of the file name with the highest number found, such
as the file that the reference of that symbolic link leads to. When
another process changes the regular file during the read, the result
comes from the bytes that the program takes.

The walk never follows a symbolic link. A symbolic link ends the walk,
wherever it is on the path, and the program takes no bytes from the file
that the reference of the link leads to. So a path cannot lead out of
the tree through a symbolic link. A symbolic link that is not on the
path does not change the read: in a tree with a symbolic link `self`,
whose reference leads to the root, the read of `a.md` finds the regular
file `a.md`.

As a step of a read, the program does not wait for another process or
for a device to act on a file of another kind, such as for a process to
open the other end of a pipe.

The read gives the result of the first row of this table whose
conditions hold. An empty cell sets no condition.

| text | outcome of the walk | regular file that the walk finds | result |
|---|---|---|---|
| not a valid path | | | "invalid" |
| a valid path | "refused" | | "cannot read" |
| a valid path | "no entry" | | "no file" |
| a valid path | "not a folder" | | "no file" |
| a valid path | "symbolic link" | | "symbolic link" |
| a valid path | "not a regular file" | | "not a regular file" |
| a valid path | "regular file" | taking bytes from it fails, as a step of the read | "cannot read" |
| a valid path | "regular file" | the byte sequence that the program takes from it, as steps of the read, is not valid UTF-8 | "not UTF-8" |
| a valid path | "regular file" | the byte sequence that the program takes from it, as steps of the read, is valid UTF-8 | "found" |

With the result "found", the read also gives the text of the byte
sequence that the program takes from the regular file. The text holds
one character for each character that the byte sequence encodes, in
order. The program adds no character, removes no character, and changes
no character. So the text keeps a byte order mark, keeps each carriage
return, and keeps each character in the form that the byte sequence
encodes, with no Unicode normalization.

### 2.4 Lines and positions

A position is a line number and a column, both counted from 1. Each
character of a text, except its byte order mark, has a position.

The byte order mark of a text is the character at place 1 when that
character is U+FEFF. The body of a text is the text without its byte
order mark. The byte order mark is on no line, so it has no position. A
U+FEFF at any other place is a character like any other.

A line ending is a line feed of the body, together with the carriage
return at the place right before that line feed when there is one. The
line endings divide the body into runs: the run before the first line
ending, the run between each line ending and the next line ending, and
the run after the last line ending. A body with no line ending is one
run. The lines of the text are these runs, in order, except the last run
when it is empty. The lines are numbered from 1. A conforming program
that gives the lines of a text gives each line, in order, and no other
run.

A line never holds a line feed. A body that ends with a line feed has no
empty line after that line feed. The empty body has no line. A carriage
return that is not right before a line feed is a character of its line.
Only a line feed ends a line: U+000B, U+000C, U+0085, U+2028, and
U+2029 are characters of their line.

The tables write a text as its parts in order, separated by commas,
such as `ab`, a line feed, `c`. In the cells under "lines", a semicolon
separates two lines, "the empty text" is an empty line, and "none"
means that the text has no line.

| text | lines |
|---|---|
| `a`, a line feed, `b` | `a`; `b` |
| `a`, a line feed | `a` |
| a line feed | the empty text |
| the empty text | none |
| `ab`, a carriage return, a line feed, `c` | `ab`; `c` |
| `a`, a carriage return | `a`, a carriage return |
| U+FEFF, `x` | `x` |
| `a`, U+2028, `b` | `a`, U+2028, `b` |

The column of the character at a place of a line is 1 more than the
number of characters of the line at places before that place. A line
ending is not part of its line, so its characters add nothing to the
columns of the line. Each character of a line ending has the line
number of the line that ends at that line ending. Its column is 1 more
than the number of characters of that line. A column counts characters,
not bytes: `é` written as U+00E9 is one character, written in two bytes
of UTF-8. A tab is one character, so it counts as one column.

| text | character | position |
|---|---|---|
| `ab`, a line feed, `c` | `c` | line 2, column 1 |
| `ab`, a carriage return, a line feed, `c` | the carriage return | line 1, column 3 |
| `ab`, a carriage return, a line feed, `c` | the line feed | line 1, column 3 |
| `é`, `x`, with `é` as U+00E9 | `x` | line 1, column 2 |
| `e`, U+0301, `x` | `x` | line 1, column 3 |
| U+FEFF, `x` | `x` | line 1, column 1 |
| U+FEFF, `x` | U+FEFF | no position |

A span is a run of the body that holds at least one character of a
line. The start of a span is the position of the character at its first
place. The end of a span is one column past the last character in the
span that is a character of a line, on the line of that character. So a
line ending at the end of a span does not move the end of the span.
Example: in the text `ab`, a carriage return, a line feed, `cd`, the
span `b`, the carriage return, the line feed, `c` starts at line 1,
column 2, and ends at line 2, column 2.

### 2.5 Globs

A glob is a pattern for paths. A glob is one or more texts joined by
`/`, and it can end with `/`. Each of these texts is `**`, or a text in
which `*` stands for any run of characters inside one file name. The
glob segments of a glob are these texts, in order, and then one more
glob segment, `**`, when the glob ends with `/` (rule 5). The glob
segments of a glob are numbered from 1, in order. A path fits a glob
when the path has the form that the glob gives, by these rules:

1. A path fits a glob only as a whole, from file name 1. Only the path
   `Cargo.lock` fits `Cargo.lock`. A path whose file name with the
   highest number is `Cargo.lock` fits `**/Cargo.lock`, at any depth.
2. Any run of characters inside one file name fits `*`, the empty run
   included. No `/` fits `*`, because a file name holds no `/`.
3. Any number of file names, zero included, fit a glob segment `**`
   that does not have the highest number. So `x.md` and `a/b/x.md` fit
   `**/x.md`, and `a/b` fits `a/**/b`.
4. One or more file names fit a glob segment `**` that has the highest
   number. So every path inside the folder `docs`, such as `docs/a.md`
   and `docs/a/b.md`, fits `docs/**`. The path `docs` does not fit
   `docs/**`.
   In `**/x/**`, glob segment 1 is a `**` that does not have the highest
   number, and glob segment 3 is a `**` that has the highest number. So
   `x/a` fits `**/x/**`, and `x` does not.
5. A glob that ends with `/` has the glob segment `**` after that `/`.
   So `docs/` means `docs/**`.
6. File names that start with `.` fit `*` and `**`.
7. Only the same character fits each other character of a glob segment.
   Case always matters, so `docs/a.md` does not fit `Docs/*`.

These texts are not valid globs:

- the empty text;
- a text that starts with `/`;
- a text with two `/` together;
- a text with a glob segment `.` or `..`;
- a text with `**` in a glob segment that holds other characters too,
  such as `src/**.ts`; `src/**/*.ts` is a valid glob;
- a text that holds `?`, `[`, `]`, `{`, `}`, or `\`.

A glob can hold U+0000, but no file name holds U+0000. So no file name
fits a glob segment that holds U+0000.

| glob | paths that fit it | paths that do not fit it |
|---|---|---|
| `*.md` | `a.md`, `.md`, `.notes.md` | `a/b.md`, `a.txt` |
| `docs/**/*.md` | `docs/a.md`, `docs/x/y/a.md` | `a.md`, `docs/a.txt` |
| `a*b*c` | `abc`, `aXbYc` | `ab`, `acb` |

### 2.6 Path sets

A path set is a finite sequence of texts, its members. A member that
starts with `!` is a `!` glob, and the glob of that member is the text
after that `!`. Every other member is a plain glob, and the glob of that
member is the member. The glob of a member can be a text that is not a
valid glob.

When the glob of each member is a valid glob, the path set gives a set
of paths. A path is in that set when the path fits the glob of a plain
glob, and the path fits the glob of no `!` glob. So a `!` glob removes
paths from the set. The order of the members does not change the set.
No path is in the empty path set.

Example: with the members `docs/` and `!docs/old/`, the path
`docs/a.md` is in the set, and `docs/old/a.md` and `a.md` are not. The
glob of the member `!!x` is `!x`, and the path `!x` fits that glob.

A path set is valid when:

1. the glob of each member is a valid glob;
2. no two members are the same text;
3. at least one member is a plain glob, when the path set holds at
   least one member.

The empty path set is valid. A path set that is not valid can still give
a set of paths: the path set with the members `a/` and `a/` is not
valid, because two members are the same text, and the path `a/b` is in
its set.

### 2.7 Results

A conforming program gives one result for each input that it tests or
reads:

| input | result |
|---|---|
| a text that it tests as a path | "valid" or "invalid" |
| a text that it tests as a glob | "valid" or "invalid" |
| a valid glob and a valid path that it tests together | "fits" or "does not fit" |
| a path set that it tests | "valid" or "invalid" |
| a path set in which the glob of each member is a valid glob, and a valid path, that it tests together | "in the set" or "not in the set" |
| a text that it reads as a path in a tree | "invalid", "found", "no file", "symbolic link", "not a regular file", "not UTF-8", or "cannot read" |

## 3. Requirements

### 3.1 Characters and texts

@req characters=v1

A character is a Unicode scalar value: a code point from U+0000 to
U+D7FF, or from U+E000 to U+10FFFF. A text is a finite sequence of
characters. The empty text is the text of no characters. Two texts are
the same text when they have the same characters in the same order. The
places of a text are numbered from 1, one place for each character of
the text, in the order of the text: the character at place 1 is the
first character of the text. A run of a text is the characters of the
text at the places from one place to the same place or a later place,
in order, each at its place. A run can also be empty, and then it holds
no character. A line feed is U+000A, and a carriage return is U+000D.

### 3.2 Notation

@req notation=v1
@cites {rfc/5234, rfc/7405, #characters=v1}

The productions of this design are rules of ABNF, the notation of
RFC 5234, with the case-sensitive strings of RFC 7405. Each terminal
value of a production of this design is the code point of one
character, so `%x2F` matches the character `/`. A text matches a
production when the production matches the whole of the text.

### 3.3 Results

@req result-list=v1

The results are these twelve: "valid", "invalid", "fits", "does not
fit", "in the set", "not in the set", "found", "no file", "symbolic
link", "not a regular file", "not UTF-8", and "cannot read".

### 3.4 UTF-8

@req utf-8=v1
@cites {rfc/3629, #{notation=v1, characters=v1}}

A byte is an integer from 0 to 255. A byte sequence is a finite
sequence of bytes. A byte sequence is valid UTF-8 when the rule
`UTF8-octets` of RFC 3629 matches the whole byte sequence, with each
byte as one terminal value of that rule. The text of a byte sequence
that is valid UTF-8 holds one character for each `UTF8-char` that the
rule `UTF8-octets` matches in the byte sequence, in order, a leading
U+FEFF included: the character that the bytes of that `UTF8-char`
encode, as RFC 3629 defines UTF-8. The UTF-8 encoding of a text is the
byte sequence that encodes the text, as RFC 3629 defines UTF-8.

### 3.5 Trees

@req trees=v1
@cites {posix/2024, #utf-8=v1}

A file system is a file system as POSIX.1-2024 defines the term. A tree
is a folder, its root, together with the file of each entry of the root
and the file of each entry of each folder of the tree. Each file is of
exactly one of four kinds: a folder, a regular file, a symbolic link,
or a file of another kind. A folder holds entries. Each entry of a
folder has an entry name, which is a byte sequence, and a file. No two
entries of one folder have the same entry name. A regular file holds a
content, which is a byte sequence. A symbolic link holds a reference,
which can lead to a file or to no file. A folder gives at most one
entry for each byte sequence: the entry whose entry name is that byte
sequence, or, on a file system that treats two different byte
sequences as the same name, the entry whose entry name the file system
treats as the same name as that byte sequence.

### 3.6 File types

@req file-types=v1
@cites {posix/2024, #{trees=v1, utf-8=v1, characters=v1}}

On a file system, the file type of a file gives its kind, as
POSIX.1-2024 defines the file types: a file of the type directory is a
folder, a file of the type regular file is a regular file, a file of
the type symbolic link is a symbolic link, and a file of each other
type is a file of another kind. The entries of a folder on a file
system are the entries of its directory, except any entry whose entry
name is the UTF-8 encoding of the text `.` or of the text `..`.

### 3.7 Permissions

@req permissions=v1
@cites {posix/2024, #trees=v1}

The search permission and the read permission of a program for a file
are the search permission and the read permission of the process of
the program for that file, as POSIX.1-2024 defines them.

### 3.8 Lookups

@req lookups=v1
@cites #{trees=v1, utf-8=v1, permissions=v1}

A lookup of a byte sequence in a folder is an action of a program in
which the file system looks for the entry that the folder gives for
that byte sequence at the moment of the lookup. The lookup finds no
entry when the file system reports that the folder gives no entry for
the byte sequence. The file system refuses the lookup when the lookup
fails and the file system does not report that the folder gives no
entry for the byte sequence, such as for a lack of the search
permission of the program for the folder, or for a byte sequence longer
than the file system allows in an entry name. Otherwise, the lookup
finds the file of the entry, whatever the program does with that file
after the lookup, and a failure to open that file is not a refusal of
the lookup. A lookup follows no symbolic link: when the file of the
entry is a symbolic link, the lookup finds that symbolic link.

### 3.9 Taking bytes

@req taken-bytes=v1
@cites #{trees=v1, utf-8=v1, permissions=v1, lookups=v1}

To take bytes from a file is to copy into the program any byte that the
file holds or gives: a byte of the content of a regular file, of the
entry names of a folder, of the reference of a symbolic link, or of the
data of a file of another kind. A lookup takes no bytes from a file.
Taking bytes from a file fails when the file system does not give the
program a byte of that file that the program asks for, such as for a
lack of the read permission of the program for a regular file, or for
an error of the device.

### 3.10 The grammar of paths

@req paths=v1
@cites #{notation=v1, characters=v1}

These productions give the form of a path:

```abnf
path       = file-name *( "/" file-name )
file-name  = *"." non-dot *name-char / 3*"."
name-char  = %x1-2E / %x30-D7FF / %xE000-10FFFF
non-dot    = %x1-2D / %x30-D7FF / %xE000-10FFFF
```

A valid path is a text that matches `path`. The file names of a valid
path are the texts that its `file-name` elements match. They are
numbered from 1, in the order of the `file-name` elements: file name 1
is the text that the first `file-name` element matches.

### 3.11 Testing a text as a path

@req test-paths=v1
@cites #{characters=v1, paths=v1, result-list=v1, notation=v1}

For each text that it tests as a path, a conforming program must give
the result "valid" when the text matches `path`, and the result
"invalid" when the text does not match `path`.

### 3.12 Reads

@req reads=v1
@cites #{characters=v1, trees=v1, lookups=v1, paths=v1, result-list=v1}

To read a text as a path in a tree is to give a result for that text
and that tree. A read is one such operation of a program. A step of a
read is an action that the program does to give the result of that
read, such as a lookup. A read takes the root of the tree as a folder
that the program has open when the read starts, so a lookup by which
the program reaches the root is not a step of the read.

### 3.13 Walks

@req walks=v1
@cites #{
    characters=v1, utf-8=v1, trees=v1, lookups=v1, paths=v1,
    reads=v1,
}

When the text of a read is a valid path, a lookup of file name 1 of the
read is a lookup of the UTF-8 encoding of file name 1 of the text in the
root of the tree. A lookup of each later file name of the read is a
lookup of the UTF-8 encoding of that later file name in a folder that a
lookup of the file name right before it, as a step of the same read,
found. The walk of a read is the lookups that the program makes as steps
of that read. For each file name that the walk looks up, the outcome of
that file name is the first row of this table whose condition holds for
the latest lookup of that file name in the walk:

| outcome | condition |
|---|---|
| "refused" | the file system refuses the lookup |
| "no entry" | the lookup finds no entry |
| "symbolic link" | the lookup finds a symbolic link |
| "not a folder" | the file name does not have the highest number, and the lookup finds a regular file or a file of another kind |
| "regular file" | the file name has the highest number, and the lookup finds a regular file |
| "not a regular file" | the file name has the highest number, and the lookup finds a folder or a file of another kind |

When no row holds, or when the walk does not look up the file name, the
file name has no outcome. The outcome of the walk is the outcome of the
file name with the lowest number that has an outcome. A walk in which no
file name has an outcome has no outcome. With the outcome "regular
file", the walk finds the regular file that the latest lookup of the
file name with the highest number found.

### 3.14 Walks that reach an outcome

@req complete-walks=v1
@cites #{
    characters=v1, trees=v1, lookups=v1, paths=v1, reads=v1,
    walks=v1,
}

When it reads a valid path as a path in a tree, a conforming program
must make lookups of the file names of the read, as steps of the read,
until the walk of the read has an outcome.

### 3.15 The lookups of a read

@req limit-lookups=v1
@cites #{
    characters=v1, paths=v1, trees=v1, lookups=v1, reads=v1,
    walks=v1,
}

As a step of a read of a text as a path in a tree, a conforming program
must make no lookup other than a lookup of a file name of that read.

### 3.16 The permission that a lookup needs

@req search-without-read-permission=v1
@cites #{trees=v1, permissions=v1, lookups=v1, reads=v1, walks=v1}

A conforming program must make each lookup of the walk of a read in a
way that needs no permission of the program other than the search
permission for the folder of that lookup.

### 3.17 The files from which a read takes bytes

@req limit-bytes=v1
@cites #{
    characters=v1, utf-8=v1, trees=v1, lookups=v1, taken-bytes=v1,
    paths=v1, reads=v1, walks=v1,
}

As a step of a read of a text as a path in a tree, a conforming program
must take bytes from no file other than a regular file that a lookup of
the file name with the highest number of that read, in the walk of that
read, found.

### 3.18 The bytes of a regular file

@req take-file-bytes=v1
@cites #{
    characters=v1, utf-8=v1, trees=v1, permissions=v1,
    taken-bytes=v1, paths=v1, reads=v1, walks=v1,
}

When the walk of a read of a text as a path in a tree has the outcome
"regular file", a conforming program must, as steps of the read, take
the bytes of the regular file that the walk finds, in order from its
first byte, in a way that needs no permission of the program for that
regular file other than the read permission, until the file system
gives no more bytes or taking bytes from that regular file fails.

### 3.19 No wait for another process

@req never-wait=v1
@cites #{characters=v1, paths=v1, trees=v1, reads=v1}

A conforming program must not, as a step of a read of a text as a path
in a tree, wait for another process or for a device to act on a file of
another kind, such as for a process to open the other end of a pipe.

### 3.20 The result of a read

@req give-read-result=v1
@cites #{
    characters=v1, utf-8=v1, trees=v1, taken-bytes=v1, paths=v1,
    reads=v1, walks=v1, result-list=v1,
}

When it reads a text as a path in a tree, a conforming program must
give the result of the first row of this table whose conditions hold
for the text, for the outcome of the walk of the read, and for the
regular file that the walk finds, where an empty cell sets no
condition:

| text | outcome of the walk | regular file that the walk finds | result |
|---|---|---|---|
| not a valid path | | | "invalid" |
| a valid path | "refused" | | "cannot read" |
| a valid path | "no entry" | | "no file" |
| a valid path | "not a folder" | | "no file" |
| a valid path | "symbolic link" | | "symbolic link" |
| a valid path | "not a regular file" | | "not a regular file" |
| a valid path | "regular file" | taking bytes from it fails, as a step of the read | "cannot read" |
| a valid path | "regular file" | the byte sequence that the program takes from it, as steps of the read, is not valid UTF-8 | "not UTF-8" |
| a valid path | "regular file" | the byte sequence that the program takes from it, as steps of the read, is valid UTF-8 | "found" |

### 3.21 The text of a file

@req give-file-text=v1
@cites #{
    characters=v1, utf-8=v1, trees=v1, taken-bytes=v1, paths=v1,
    reads=v1, walks=v1, result-list=v1,
}

When it reads a text as a path in a tree and gives the result "found",
a conforming program must give with that result the text of the byte
sequence that it takes, as steps of that read, from the regular file
that the walk of the read finds.

### 3.22 Lines

@req lines=v1
@cites #characters=v1

The byte order mark of a text is the character at place 1 of the text
when that character is U+FEFF. The body of a text is the run of the
text that holds every character of the text except its byte order mark.
A line ending is the line feed at a place of the body, together with the
character at the place right before that place when that character is
a carriage return. The line endings divide the body into runs: the run
before the first line ending, the run between each line ending and the
next line ending, and the run after the last line ending; a body with no
line ending is one run. The lines of the text are these runs, in the
order of the body, except the last run when it is empty. The lines are
numbered from 1. The line that ends at a line ending is the run right
before that line ending. A character of a line is the character at a
place of the body that the line holds.

### 3.23 Positions

@req positions=v1
@cites #{lines=v1, characters=v1}

A position is a pair of numbers: a line number and a column. The
position of the character at a place of a line has the number of that
line as its line number, and, as its column, 1 more than the number of
the places of that line before that place. The position of the
character at a place of a line ending has, as its line number, the
number of the line that ends at that line ending, and, as its column, 1
more than the number of the characters of that line. A byte order mark
has no position.

### 3.24 Spans

@req spans=v1
@cites #{characters=v1, lines=v1, positions=v1}

A span of a text is a run of the body of the text that holds at least
one character of a line. The start of a span is the position of the
character at the first place of the span. The end of a span comes from
the last place of the span that holds a character of a line: the end
has the line number of the position of the character at that place, and
a column 1 more than the column of that position.

### 3.25 The lines that a program gives

@req give-lines=v1
@cites #{lines=v1, characters=v1}

When a conforming program gives the lines of a text, it must give each
line of the text, in order, and no other run.

### 3.26 The positions that a program gives

@req give-positions=v1
@cites #{positions=v1, characters=v1, lines=v1}

When a conforming program gives the position of the character at a
place of the body of a text, it must give the position of the character
at that place.

### 3.27 No position for a byte order mark

@req omit-bom-position=v1
@cites #{positions=v1, lines=v1, characters=v1}

A conforming program must give no position for the byte order mark of a
text.

### 3.28 The spans that a program gives

@req give-span-ends=v1
@cites #{spans=v1, characters=v1, positions=v1}

When a conforming program gives the start and the end of a span of a
text, it must give the start of that span and the end of that span.

### 3.29 The grammar of globs

@req glob-grammar=v1
@cites #{notation=v1, characters=v1}

These productions give the form of a glob:

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

A valid glob is a text that matches `glob`. The glob segments of a
valid glob are the texts that its `glob-segment` elements match, in
order, and then the text `**` when the glob ends with `/`. They are
numbered from 1, in that order.

### 3.30 Testing a text as a glob

@req test-globs=v1
@cites #{characters=v1, glob-grammar=v1, result-list=v1, notation=v1}

For each text that it tests as a glob, a conforming program must give
the result "valid" when the text matches `glob`, and the result
"invalid" when the text does not match `glob`.

### 3.31 The meaning of a glob

@req glob-meaning=v1
@cites #{paths=v1, glob-grammar=v1, characters=v1}

A valid path fits a valid glob when the file names of the path can be
divided into groups, one group for each glob segment of the glob, such
that the file names of the groups, group after group in the order of
the numbers of the glob segments, are the file names of the path in the
order of their numbers, and each group fits its glob segment:

- When the glob segment with the highest number is `**`, a group fits
  that glob segment when the group holds one or more file names.
- A group fits a glob segment `**` that does not have the highest
  number when the group holds zero or more file names.
- A group fits each other glob segment when the group holds exactly one
  file name, and that file name fits the glob segment.

A file name fits a glob segment other than `**` when the file name can
be divided into runs, one run for each place of the glob segment, such
that the characters of the runs, run after run in the order of the
places of the glob segment, are the characters of the file name in
order, and each run fits its place of the glob segment. A run fits a
place that holds `*`, whatever characters the run holds, the empty run
included. A run fits a place that holds another character when the run
holds exactly that character and no other character.

### 3.32 Testing a path against a glob

@req test-glob-fit=v1
@cites #{glob-grammar=v1, paths=v1, result-list=v1, glob-meaning=v1}

For each valid glob and each valid path that it tests together, a
conforming program must give the result "fits" when the path fits the
glob, and the result "does not fit" when the path does not fit the
glob.

### 3.33 Path sets

@req path-sets=v1
@cites #characters=v1

A path set is a finite sequence of texts, its members. A member whose
character at place 1 is `!` is a `!` glob, and the glob of that member
is the text of the characters of the member at the places after
place 1. Each other member is a plain glob, and the glob of that member
is the member.

### 3.34 Valid path sets

@req valid-path-sets=v1
@cites #{characters=v1, glob-grammar=v1, path-sets=v1}

A path set is valid when the glob of each member is a valid glob, no
two members are the same text, and at least one member is a plain glob
when the path set holds at least one member.

### 3.35 Testing a path set

@req test-path-sets=v1
@cites #{path-sets=v1, valid-path-sets=v1, result-list=v1}

For each path set that it tests, a conforming program must give the
result "valid" when the path set is valid, and the result "invalid"
when the path set is not valid.

### 3.36 The meaning of a path set

@req path-set-meaning=v1
@cites #{paths=v1, path-sets=v1, glob-meaning=v1, glob-grammar=v1}

For a path set in which the glob of each member is a valid glob, a valid
path is in the path set when the path fits the glob of at least one
plain glob of the path set, and the path fits the glob of no `!` glob of
the path set.

### 3.37 Testing a path against a path set

@req test-path-set-membership=v1
@cites #{
    path-sets=v1, glob-grammar=v1, paths=v1, result-list=v1,
    path-set-meaning=v1,
}

For each path set in which the glob of each member is a valid glob, and
each valid path, that it tests together, a conforming program must give
the result "in the set" when the path is in the path set, and the result
"not in the set" when the path is not in the path set.

### 3.38 One result for each input

@req give-one-result=v1
@cites #{
    result-list=v1, characters=v1, paths=v1, glob-grammar=v1,
    path-sets=v1, trees=v1, reads=v1,
}

A conforming program must give exactly one result for each input of
this table that it tests or reads, and only a result that the table
lists for that input:

| input | result |
|---|---|
| a text that it tests as a path | "valid" or "invalid" |
| a text that it tests as a glob | "valid" or "invalid" |
| a valid glob and a valid path that it tests together | "fits" or "does not fit" |
| a path set that it tests | "valid" or "invalid" |
| a path set in which the glob of each member is a valid glob, and a valid path, that it tests together | "in the set" or "not in the set" |
| a text that it reads as a path in a tree | "invalid", "found", "no file", "symbolic link", "not a regular file", "not UTF-8", or "cannot read" |

## 4. Conformance

A program conforms to this design when it meets every requirement of
section 3.

Each vector below gives an input and what a conforming program gives
for it. These conventions apply:

- A vector with the result "found" also gives the text that a
  conforming program gives with that result, as in "found, with the
  text `hi`".
- The text after a colon that follows a result, as in "invalid: it
  starts with `/`", explains the result. A program does not give it.

### 4.1 Paths

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
| the empty text | invalid: a path holds at least one file name |
| `/a.md` | invalid: it starts with `/` |
| `docs/` | invalid: it ends with `/` |
| `docs//a.md` | invalid: two `/` together |
| `.` | invalid: `.` is not a file name |
| `./a.md` | invalid: `.` is not a file name |
| `docs/../a.md` | invalid: `..` is not a file name |
| `docs/..` | invalid: `..` is not a file name |
| `a`, U+0000, `.md` | invalid: a file name holds no U+0000 |

### 4.2 Reads

Each row gives a tree, a text that a conforming program reads as a path
in that tree, and the result. The tree is on a file system, and it
holds only the files that the row names. No other process changes the
tree during the read. Unless a row says otherwise, the program has the
search permission and the read permission for every file of the tree. A
condition on the file system, when a row has one, ends the description
of the tree. A row with no condition on the file system gives the same
result on every file system. A content written as "the text `hi`" is
the UTF-8 encoding of that text. A content written as "the bytes
`FF FE`" gives each byte in two hexadecimal digits.

| tree | text | result |
|---|---|---|
| the regular file `a.md`, whose content is the text `hi` | `a.md` | found, with the text `hi` |
| the folder `docs`, which holds the regular file `a.md`, whose content is the text `hi` | `docs/a.md` | found, with the text `hi` |
| the regular file `a.md`, whose content is empty | `a.md` | found, with the empty text |
| the regular file `a.md`, whose content is the text `hi` | `b.md` | no file |
| the regular file `a.md`, whose content is the text `hi` | `a.md/b.md` | no file: `a.md` is not a folder |
| the regular file `a`, whose content is the text `hi` | `a/a` | no file: file name 1, `a`, is not a folder |
| a chain of 200 folders, each with the name `ddddddddddddddddddddddddd`, in which the root holds the first folder, each folder except the last holds the next folder, and the last folder holds the regular file `a.md`, whose content is the text `hi` | `ddddddddddddddddddddddddd/` 200 times, then `a.md` | found, with the text `hi`: the path holds 5204 characters, more than many systems allow in a path |
| the regular file `a.md`, whose content is the text `hi`, on a file system that treats each byte sequence as a different name | `A.md` | no file |
| the regular file `a.md`, whose content is the text `hi`, on a file system that treats `A.md` and `a.md` as the same name | `A.md` | found, with the text `hi` |
| the regular file `café.md`, with `é` as U+00E9, whose content is the text `hi`, on a file system that treats each byte sequence as a different name | `cafe`, U+0301, `.md` | no file: the UTF-8 encoding of the text is not the entry name |
| the folder `docs` | `docs` | not a regular file |
| the pipe `p`, which no process opens | `p` | not a regular file: the program does not wait for a process to open the pipe |
| the symbolic link `a.md`, whose reference leads to the regular file `b.md`, and the regular file `b.md`, whose content is the text `hi` | `a.md` | symbolic link |
| the symbolic link `a.md`, whose reference leads to the regular file `b.md`, and the regular file `b.md`, whose content is the text `hi` | `b.md` | found, with the text `hi` |
| the symbolic link `d`, whose reference leads to the folder `docs`, and the folder `docs`, which holds the regular file `a.md`, whose content is the text `hi` | `d/a.md` | symbolic link |
| the symbolic link `d`, whose reference leads to the folder `docs`, and the folder `docs`, which holds the regular file `a.md`, whose content is the text `hi` | `docs/a.md` | found, with the text `hi` |
| the symbolic link `a.md`, whose reference leads to no file | `a.md` | symbolic link |
| the symbolic link `self`, whose reference leads to the root, and the regular file `a.md`, whose content is the text `hi` | `a.md` | found, with the text `hi` |
| the symbolic link `self`, whose reference leads to the root, and the regular file `a.md`, whose content is the text `hi` | `self/a.md` | symbolic link |
| the folder whose entry name is the byte `E9`, which holds the regular file `x`, on a file system that treats each byte sequence as a different name | `é/x`, with `é` as U+00E9 | no file: the UTF-8 encoding of `é` is the bytes `C3 A9` |
| the regular file `a.md`, whose content is the bytes `FF FE` | `a.md` | not UTF-8 |
| the regular file `a.md`, whose content is the bytes `ED A0 80` | `a.md` | not UTF-8: these bytes have the form of U+D800, which is not a character |
| the regular file `a.md`, whose content is the bytes `C0 AF` | `a.md` | not UTF-8: an overlong form |
| the regular file `a.md`, whose content is the bytes `EF BB BF 78` | `a.md` | found, with the text U+FEFF, `x` |
| the regular file `a.md`, whose content is the bytes `61 0D 0A 62` | `a.md` | found, with the text `a`, a carriage return, a line feed, `b` |
| the regular file `a.md`, whose content is the bytes `65 CC 81` | `a.md` | found, with the text `e`, U+0301 |
| the folder `docs`, for which the program has the search permission and not the read permission, and which holds the regular file `a.md`, whose content is the text `hi` | `docs/a.md` | found, with the text `hi` |
| the folder `docs`, for which the program has neither the read permission nor the search permission, and which holds the regular file `a.md`, whose content is the text `hi` | `docs` | not a regular file |
| the folder `docs`, for which the program has neither the read permission nor the search permission, and which holds the regular file `a.md`, whose content is the text `hi` | `docs/a.md` | cannot read: the file system refuses the lookup of `a.md` |
| the regular file `a.md`, whose content is the text `hi`, and for which the program has no read permission | `a.md` | cannot read |
| a tree whose root holds no entry, on a file system that allows at most 255 bytes in an entry name and refuses each lookup of a longer byte sequence | `a` 300 times | cannot read: the file system refuses the lookup |
| any tree | `../a.md` | invalid |
| any tree | `/etc/passwd` | invalid |

### 4.3 Lines and positions

Each row gives a text, its lines, and the position of some of its
characters. The table writes texts and lines as the tables of
section 2.4 do.

| text | lines | positions |
|---|---|---|
| `a`, a line feed, `b` | `a`; `b` | `b`: line 2, column 1 |
| `a`, a line feed | `a` | the line feed: line 1, column 2 |
| a line feed | the empty text | the line feed: line 1, column 1 |
| two line feeds | the empty text; the empty text | the second line feed: line 2, column 1 |
| the empty text | none | none |
| U+FEFF | none | U+FEFF: no position |
| `ab`, a carriage return, a line feed, `c` | `ab`; `c` | the carriage return: line 1, column 3; the line feed: line 1, column 3; `c`: line 2, column 1 |
| `a`, a carriage return | `a`, a carriage return | the carriage return: line 1, column 2 |
| `a`, a carriage return, a carriage return, a line feed | `a`, a carriage return | the first carriage return: line 1, column 2; the second carriage return: line 1, column 3 |
| `a`, a carriage return, `b` | `a`, a carriage return, `b` | `b`: line 1, column 3 |
| U+FEFF, `x` | `x` | U+FEFF: no position; `x`: line 1, column 1 |
| `x`, U+FEFF | `x`, U+FEFF | U+FEFF: line 1, column 2 |
| U+FEFF, U+FEFF, `x` | U+FEFF, `x` | the first U+FEFF: no position; the second U+FEFF: line 1, column 1; `x`: line 1, column 2 |
| `é`, `x`, with `é` as U+00E9 | `é`, `x` | `x`: line 1, column 2 |
| `e`, U+0301, `x` | `e`, U+0301, `x` | `x`: line 1, column 3 |
| U+1F600, `x` | U+1F600, `x` | `x`: line 1, column 2 |
| a tab, `x` | a tab, `x` | `x`: line 1, column 2 |
| `a`, U+000B, `b` | `a`, U+000B, `b` | `b`: line 1, column 3 |
| `a`, U+000C, `b` | `a`, U+000C, `b` | `b`: line 1, column 3 |
| `a`, U+0085, `b` | `a`, U+0085, `b` | `b`: line 1, column 3 |
| `a`, U+2028, `b` | `a`, U+2028, `b` | `b`: line 1, column 3 |
| `a`, U+2029, `b` | `a`, U+2029, `b` | `b`: line 1, column 3 |

Each row below gives a text, a span of that text, and the start and the
end of the span.

| text | span | start | end |
|---|---|---|---|
| `abc` | `b` | line 1, column 2 | line 1, column 3 |
| `ab`, a line feed, `cd` | `b`, the line feed, `c` | line 1, column 2 | line 2, column 2 |
| `ab`, a carriage return, a line feed, `cd` | `ab`, the carriage return, the line feed | line 1, column 1 | line 1, column 3 |
| `ab`, a carriage return, a line feed, `cd`, a line feed | the whole text | line 1, column 1 | line 2, column 3 |
| a line feed, `x` | the whole text | line 1, column 1 | line 2, column 2 |
| `a`, a line feed, a line feed, `b` | `a`, the two line feeds | line 1, column 1 | line 1, column 2 |
| U+FEFF, `ab` | `ab` | line 1, column 1 | line 1, column 3 |
| `é`, `x`, with `é` as U+00E9 | `x` | line 1, column 2 | line 1, column 3 |

### 4.4 Globs

Each item gives a text and its result as a glob. For a valid glob, it
also gives paths that fit it, for which a conforming program gives the
result "fits", and paths that do not fit it, for which it gives the
result "does not fit".

- `Cargo.lock`: valid; fit: `Cargo.lock`; do not fit: `a/Cargo.lock`,
  `cargo.lock`.
- `**/Cargo.lock`: valid; fit: `Cargo.lock`, `a/b/Cargo.lock`; do not
  fit: `Cargo.lock.bak`.
- `*.md`: valid; fit: `a.md`, `.md`, `.notes.md`; do not fit: `a/b.md`,
  `a.txt`.
- `*`: valid; fit: `a`, `.gitignore`; do not fit: `a/b`.
- `**`: valid; fit: `a`, `a/b/c`, `.git/x`.
- `docs/**`: valid; fit: `docs/a.md`, `docs/a/b.md`; do not fit: `docs`,
  `a/docs/a.md`.
- `docs/`: valid; fit: `docs/a.md`, `docs/a/b.md`; do not fit: `docs`.
- `**/`: valid; fit: `a`, `a/b`.
- `a/**/b`: valid; fit: `a/b`, `a/x/b`, `a/x/y/b`; do not fit: `b`,
  `a/b/c`.
- `**/x/**`: valid; fit: `x/a`, `a/x/b`, `x/x/x`; do not fit: `x`, `a/x`.
- `docs/**/*.md`: valid; fit: `docs/a.md`, `docs/x/y/a.md`; do not fit:
  `a.md`, `docs/a.txt`.
- `a*b*c`: valid; fit: `abc`, `aXbYc`, `abbc`; do not fit: `ab`, `acb`.
- `*a*`: valid; fit: `a`, `bab`; do not fit: `b`.
- `.*`: valid; fit: `.env`, `...`; do not fit: `env`.
- `...`: valid; fit: `...`; do not fit: `a`.
- `Docs/*`: valid; fit: `Docs/a.md`; do not fit: `docs/a.md`.
- `café.md`, with `é` as U+00E9: valid; fit: `café.md`, with `é` as
  U+00E9; do not fit: `cafe`, U+0301, `.md`.
- `!x`: valid; fit: `!x`; do not fit: `x`.
- `a b`: valid; fit: `a b`; do not fit: `ab`.
- `a`, U+0000: valid; do not fit: `a`.
- the empty text: invalid: a glob holds at least one glob segment.
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

### 4.5 Path sets

Each item gives the members of a path set, in order, and its result
as a path set that a conforming program tests. When the glob of each
member is a valid glob, an item can also give paths that are in the
set, for which a conforming program gives the result "in the set", and
paths that are not in the set, for which it gives the result "not in
the set".

- no member: valid; not in the set: `a.md`.
- `docs/`: valid; in the set: `docs/a.md`; not in the set: `a.md`,
  `docs`.
- `docs/` and `!docs/old/`: valid; in the set: `docs/a.md`; not in the
  set: `docs/old/a.md`, `a.md`.
- `!docs/old/` and `docs/`: valid; in the set: `docs/a.md`; not in the
  set: `docs/old/a.md`.
- `**` and `!**/*.tmp`: valid; in the set: `a.md`, `x/b.md`; not in the
  set: `a.tmp`, `x/b.tmp`.
- `a` and `!a`: valid; not in the set: `a`.
- `**` and `!!x`: valid; in the set: `x`; not in the set: `!x`.
- `*.md`, `!a.md`, and `!b.md`: valid; in the set: `c.md`; not in the
  set: `a.md`, `b.md`.
- `!docs/`: invalid: no plain glob.
- `docs/` and `docs/`: invalid: two members are the same text.
- `a/` and `a/`: invalid: two members are the same text; in the set:
  `a/b`.
- `docs/` and `!`: invalid: the glob of `!` is the empty text, which is
  not a valid glob.
- `docs/` and `!/x`: invalid: the glob of `!/x` starts with `/`.
- `a?`: invalid: the glob of `a?` holds `?`.
