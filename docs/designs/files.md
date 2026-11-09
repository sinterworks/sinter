<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Files and paths
@design files=v1
@cites rfc/3629
@cites rfc/5234
@cites rfc/7405
@cites posix/2024
A program reads a regular file of a tree at a path as UTF-8 text with no symbolic link followed, tests paths against globs and path sets, and gives the line and the column of each character of a text.

A tree is a folder, its root, with the files and the folders under it. A
path, such as `docs/guide/a.md`, gives a file of a tree: the file names
that lead from the root to the file, joined by `/`. A glob, such as
`docs/**/*.md`, is a pattern for paths. A path set is a list of globs,
such as `docs/` and `!docs/old/`, that gives a set of paths. A position, such as line 3, column 7, gives the place of a
character in a text.

The productions in section 3 are written in ABNF, the notation of
RFC 5234. A production, such as `path = file-name *( "/" file-name )`,
gives the texts that its name matches. In a production, `/` separates
two alternatives. The quoted string `"/"` is the character `/`. `( )`
groups elements, and `[ ]` makes an element optional. `*` repeats the
element after it any number of times, `1*` repeats it one or more
times, and `3*` repeats it three or more times. `%x2F` is the character
U+002F, and `%x30-3E` is any one character from U+0030 to U+003E. In
RFC 5234, a quoted string such as `"a"` matches its letters in either
case. RFC 7405 adds the form `%s"…"`, which matches its letters only in
the same case.

From RFC 3629, the design takes UTF-8: how a sequence of bytes encodes
a text, and the rule `UTF8-octets`, which gives the sequences of bytes
that are UTF-8 text. From POSIX.1-2024, the design takes the file types
of a file system: a directory, a regular file, a symbolic link, and the
other types.

## 1. Terms

| term | meaning |
|---|---|
| conforming program | a program that meets every requirement of section 3 |
| must | states an obligation of a conforming program |
| ABNF | the notation for grammars of RFC 5234, with the case-sensitive strings of RFC 7405 |
| production | a rule of ABNF, such as `path = file-name *( "/" file-name )`, which gives the texts that its name matches |
| character | one Unicode scalar value: a code point that is not from U+D800 to U+DFFF |
| text | a sequence of characters |
| run | a sequence of characters that follow each other in a text, such as `cd` in `abcde`; a run can be empty |
| byte | an integer from 0 to 255 |
| byte sequence | a sequence of bytes |
| UTF-8 text | a byte sequence that encodes a text in UTF-8, by RFC 3629 |
| tree | a folder, its root, with the files and the folders under it |
| root | the folder at the top of a tree |
| file | a folder, a regular file, a symbolic link, or a file of another kind |
| folder | a file that holds entries; POSIX calls it a directory |
| entry | an entry name and a file, which a folder holds |
| entry name | the byte sequence that names an entry of a folder |
| regular file | a file that holds a content |
| content | the byte sequence that a regular file holds |
| symbolic link | a file that refers to another file, such as a link that `ln -s` makes |
| file of another kind | a file that is not a folder, a regular file, or a symbolic link, such as a pipe, a device, or a socket |
| path | one or more file names joined by `/`, such as `docs/a.md` |
| file name | a text that names one entry on a path, such as `docs` or `a.md` in `docs/a.md` |
| walk | the lookup of the file names of a path, one at a time, from the root |
| outcome | how a walk ends, such as "regular file" or "no entry" |
| byte order mark | the character U+FEFF when it is the first character of a text |
| body | a text without its byte order mark |
| line feed | the character U+000A |
| carriage return | the character U+000D |
| line ending | a line feed of a body, with the carriage return right before it when there is one |
| line | a run of a body between two line endings, or before the first or after the last; it holds no line feed |
| position | a line number and a column, such as line 3, column 7 |
| column | the place of a character on its line, counted in characters from 1 |
| span | a run of a body that holds a character of a line, given by its start and its end |
| glob | a pattern for paths, such as `docs/**/*.md` |
| glob segment | a part of a glob between two `/`, such as `**` or `*.md` in `docs/**/*.md` |
| fit | a path fits a glob when the path has the form that the glob gives |
| path set | a list of globs, each of them as a member, such as `docs/` and `!docs/old/` |
| member | one text of a path set |
| plain glob | a member that does not start with `!` |
| `!` glob | a member that starts with `!`, such as `!docs/old/` |
| result | what a conforming program gives for an input, such as "valid" or "found" |
| valid, invalid | the results of a conforming program for an input that it accepts and for an input that it rejects |

## 2. Files, paths, globs, and positions

### 2.1 Trees and files

A tree is a folder, called the root, together with every file that the
root holds, directly or through other folders. Each file is of one of
four kinds:

| kind | what the file holds |
|---|---|
| folder | entries: each entry has an entry name and a file |
| regular file | a content: a byte sequence |
| symbolic link | a reference to another file |
| another kind | something that is not a content or entries, such as the data of a pipe, a device, or a socket |

An entry name is a byte sequence. No two entries of one folder have the
same entry name. A folder gives at most one entry for a byte sequence.
On most file systems, it is the entry whose entry name is that byte
sequence. A file system that treats two different byte sequences as the
same name, such as a file system that ignores case, can also give the
entry whose entry name it treats as the same: on such a file system,
`A.md` can give the entry `a.md`.

On a file system, the kind of a file follows its file type, as
POSIX.1-2024 defines the file types. A directory is a folder. A regular
file is a regular file. A symbolic link is a symbolic link. A file of
each other type, such as a FIFO special file (a pipe), a character
special file, a block special file, or a socket, is a file of another
kind.

### 2.2 Paths

A path is one or more file names joined by `/`. A file name is a text
that is not empty, that holds no `/` and no U+0000, and that is not `.`
or `..`. So a path never starts or ends with `/`, and it never holds two
`/` together.

| text | path |
|---|---|
| `a.md` | valid: one file name |
| `docs/guide/a.md` | valid: three file names |
| `.github/workflows/ci.yml` | valid: a file name can start with `.` |
| `...` | valid: only `.` and `..` are excluded |
| `a b/c\d.md` | valid: a space and `\` are characters of a file name |
| the empty text | invalid |
| `/a.md` | invalid: it starts with `/` |
| `docs/` | invalid: it ends with `/` |
| `docs//a.md` | invalid: two `/` together |
| `./a.md`, `docs/../a.md` | invalid: `.` and `..` are not file names |

A path has one form. `/` is the only separator, so `a\b.md` is one file
name. A path is never resolved: `.` and `..` are not file names, so
`docs/../a.md` is not a path of `a.md`; it is not a path at all.

A path is a text, and a program compares two paths by their
characters. Case matters, so `Docs/a.md` and `docs/a.md` are two
different paths. No Unicode normalization applies, so a path with `é`
written as U+00E9 and a path with `e` and U+0301 are two different
paths, though they look the same.

### 2.3 Reading a file

To read a text as a path in a tree, a program first tests the text as a
path. For a text that is not a valid path, the read gives the result
"invalid", and the program looks up nothing.

For a valid path, the program walks the path. The walk takes the file
names of the path in order. It looks up the first file name in the
root, and each later file name in the folder that it found for the file
name before it. To look up a file name in a folder, the walk takes the
entry that the folder gives for the UTF-8 encoding of the file name. So
no path reaches an entry whose entry name is not UTF-8 text, except on a
file system that treats two different byte sequences as the same name.

For each file name, the walk takes the first row of this table whose
condition holds. When no row holds, the entry is a folder and the file
name is not the last; the walk then goes on to the next file name.

| outcome | condition |
|---|---|
| refused | the tree refuses to look up the file name, for example because the program has no permission to search the folder |
| no entry | the folder gives no entry for the file name |
| symbolic link | the file of the entry is a symbolic link |
| not a folder | the file name is not the last, and the file of the entry is a regular file or a file of another kind |
| regular file | the file name is the last, and the file of the entry is a regular file |
| not a regular file | the file name is the last, and the file of the entry is a folder or a file of another kind |

The walk ends at the first file name that gives an outcome. A regular
file is at a path when the walk of the path ends with the outcome
"regular file" and finds that file.

The walk never follows a symbolic link. A symbolic link ends the walk,
wherever it is on the path, and the program reads nothing that the link
refers to. So a path cannot lead out of the tree through a link.

The program reads the content from the regular file that the walk
found. It looks up no file name again, and it does not look up the path
again from the root. So a change to the tree during the read, such as a
folder of the path that another process replaces with a symbolic link,
cannot make the program read another file.

The program reads no byte from a file of another kind, and it does not
wait for another process. So a pipe that no process writes to does not
stop the read.

The read gives one of these results:

| outcome of the walk | content | result |
|---|---|---|
| refused | | cannot read |
| no entry | | no file |
| not a folder | | no file |
| symbolic link | | symbolic link |
| not a regular file | | not a regular file |
| regular file | the tree refuses to give it, for example because of an error of the device | cannot read |
| regular file | not UTF-8 text | not UTF-8 |
| regular file | UTF-8 text | found |

With the result "found", the read also gives the text of the content.
The text holds every character that the content encodes, in order. The
program adds no character, removes no character, and changes no
character. So the text keeps a byte order mark, keeps each carriage
return, and keeps each character in the form that the file writes, with
no Unicode normalization.

### 2.4 Lines and positions

A position gives the place of a character in a text as a line number
and a column, both counted from 1.

The byte order mark of a text is its first character when that
character is U+FEFF. The body of a text is the text without its byte
order mark. The byte order mark is on no line, so it has no position. A
U+FEFF at any other place is a character like any other.

A line ending is a line feed of the body, together with the carriage
return right before that line feed when there is one. The line endings
divide the body into runs: the run before the first line ending, the
run between each two line endings, and the run after the last line
ending. A body with no line ending is one run. The lines of the text are
these runs, in order, except the last run when it is empty. So a line
holds no line feed, a body that ends with a line feed has no empty line
after it, and the empty body has no line. A carriage return that no line
feed follows is a character of its line.

| text | lines |
|---|---|
| `a`, a line feed, `b` | `a`, then `b` |
| `a`, a line feed | `a` |
| a line feed | one empty line |
| the empty text | none |
| `ab`, a carriage return, a line feed, `c` | `ab`, then `c` |
| `a`, a carriage return | `a` and a carriage return |
| U+FEFF, `x` | `x` |

The column of a character of a line is 1 more than the number of
characters of the line before it. The characters of a line ending count
in no column. Each character of a line ending has the line number of
the line before the line ending, and the column after the last
character of that line. A column
counts characters, not bytes: `é` is one character, written in two
bytes of UTF-8. A tab is one character, so it counts as one column.

| text | character | position |
|---|---|---|
| `ab`, a line feed, `c` | `c` | line 2, column 1 |
| `ab`, a carriage return, a line feed, `c` | the carriage return | line 1, column 3 |
| `ab`, a carriage return, a line feed, `c` | the line feed | line 1, column 3 |
| `é`, `x` | `x` | line 1, column 2 |
| `e`, U+0301, `x` | `x` | line 1, column 3 |
| U+FEFF, `x` | `x` | line 1, column 1 |

A span is a run of the body that holds at least one character of a
line. The start of a span is the position of its first character. The
end of a span is one column past the last character of the span that is
a character of a line, on the line of that character. So the end of a
span never counts a line ending: a span that ends with a line ending
ends at the last character before that line ending. Example: in the text
`ab`, a carriage return, a line feed, `cd`, the span `b`, the carriage
return, the line feed, `c` starts at line 1, column 2, and ends at line
2, column 2.

### 2.5 Globs

A glob is a pattern for paths. A glob is one or more glob segments
joined by `/`, and it can end with `/`. A glob segment is `**`, or a
text in which `*` stands for any run of characters inside one file name.
A path fits a glob when the path has the form that the glob gives, by
these rules:

1. A glob fits the whole path, from its first file name. `Cargo.lock`
   fits only the path `Cargo.lock`. `**/Cargo.lock` fits `Cargo.lock`
   at any depth.
2. `*` fits any run of characters inside one file name, the empty run
   included. It never fits a `/`, because a file name holds none.
3. A glob segment `**` that is not the last glob segment fits any number
   of file names, zero included. So `**/x.md` fits `x.md` and
   `a/b/x.md`, and `a/**/b` fits `a/b`.
4. A glob segment `**` that is the last glob segment fits one or more
   file names: everything inside the folder before it. `docs/**` fits
   `docs/a.md` and `docs/a/b.md`. It does not fit the path `docs`.
5. A glob that ends with `/` has the glob segment `**` after that `/`.
   So `docs/` means `docs/**`.
6. `*` and `**` fit file names that start with `.`.
7. Every other character fits only itself. Case always matters, so
   `Docs/*` does not fit `docs/a.md`.

These texts are not globs:

- the empty text;
- a text that starts with `/`;
- a text with two `/` together;
- a text with a glob segment `.` or `..`;
- a text with `**` in a glob segment that holds other characters too,
  such as `src/**.ts`; `src/**/*.ts` is a glob;
- a text that holds `?`, `[`, `]`, `{`, `}`, or `\`.

| glob | paths that fit it | paths that do not fit it |
|---|---|---|
| `*.md` | `a.md`, `.md`, `.notes.md` | `a/b.md`, `a.txt` |
| `docs/**/*.md` | `docs/a.md`, `docs/x/y/a.md` | `a.md`, `docs/a.txt` |
| `a*b*c` | `abc`, `aXbYc` | `ab`, `acb` |

### 2.6 Path sets

A path set is a list of texts, its members. A member that starts with
`!` is a `!` glob, and the text after that `!` is its glob. Every other
member is a plain glob, and the member is its glob. A path is in a path
set when the glob of a plain glob fits the path, and the glob of no `!`
glob fits it. So a `!` glob takes paths out of the set. The order of the
members does not change the set.

A path set is valid when:

1. the glob of each member is a valid glob;
2. no two members are the same text;
3. a path set that holds at least one member holds at least one plain
   glob.

The empty path set is valid, and no path is in it.

Example: with the members `docs/` and `!docs/old/`, the path
`docs/a.md` is in the set, and `docs/old/a.md` and `a.md` are not. A
member `!!x` is a `!` glob whose glob is `!x`, which fits the path `!x`.

### 2.7 Results

A conforming program gives one result for each input that it tests:

| input | result |
|---|---|
| a text that it tests as a path | valid or invalid |
| a text that it tests as a glob | valid or invalid |
| a valid glob and a valid path that it tests together | fits or does not fit |
| a path set that it tests | valid or invalid |
| a path set that it accepts and a valid path that it tests together | in the set or not in the set |
| a text that it reads as a path in a tree | invalid, found, no file, symbolic link, not a regular file, not UTF-8, or cannot read |

## 3. Requirements

### 3.1 Characters and texts

@req characters=v1

A character is a Unicode scalar value: a code point from U+0000 to
U+D7FF, or from U+E000 to U+10FFFF. A text is a finite sequence of
characters. The empty text is the text of no characters. Two texts are
the same text when they have the same characters in the same order. A
run of a text is a sequence of characters that follow each other in the
text, and it can be empty. A line feed is U+000A, and a carriage return
is U+000D.

### 3.2 Notation

@req notation=v1
@cites rfc/5234
@cites rfc/7405
@cites #characters=v1

The productions of this design are rules of ABNF, the notation of
RFC 5234, with the case-sensitive strings of RFC 7405. They use the core
rules of RFC 5234, Appendix B.1. Each terminal value of a production of
this design is the code point of one character, so `%x2F` matches the
character `/`. A text matches a production when the production matches
the whole of the text.

### 3.3 Results

@req result-list=v1
@cites #characters=v1

The results are these twelve: "valid", "invalid", "fits", "does not
fit", "in the set", "not in the set", "found", "no file", "symbolic
link", "not a regular file", "not UTF-8", and "cannot read". To reject
an input is to give it the result "invalid". To accept an input is to
give it the result "valid".

### 3.4 UTF-8

@req utf-8=v1
@cites rfc/3629
@cites #characters=v1
@cites #notation=v1

A byte is an integer from 0 to 255. A byte sequence is a finite
sequence of bytes. A byte sequence is UTF-8 text when it matches the
rule `UTF8-octets` of RFC 3629, section 4, with each byte as one
terminal value of that rule. The text of a byte sequence that is UTF-8
text is the text that the byte sequence encodes in UTF-8, as RFC 3629,
section 3, defines the encoding. The UTF-8 encoding of a text is the
byte sequence that encodes the text in UTF-8.

### 3.5 Trees

@req trees=v1
@cites posix/2024
@cites #utf-8=v1

A tree is a folder, its root, together with each file that the root
holds and each file that a folder of the tree holds. Each file is of
exactly one of four kinds: a folder, a regular file, a symbolic link,
or a file of another kind. A folder holds entries. Each entry of a
folder has an entry name, which is a byte sequence, and a file. No two
entries of one folder have the same entry name. A regular file holds a
content, which is a byte sequence. A symbolic link refers to another
file. A folder gives at most one entry for each byte sequence: the entry
whose entry name is that byte sequence, or, on a file system that treats
two different byte sequences as the same name, the entry whose entry
name it treats as the same name as that byte sequence. On a file
system, a file whose file type, as POSIX.1-2024 defines
the file types, is a directory is a folder; a file of the type regular
file is a regular file; a file of the type symbolic link is a symbolic
link; and a file of each other type is a file of another kind.

### 3.6 The grammar of paths

@req paths=v1
@cites #characters=v1
@cites #notation=v1

These productions give the form of a path:

```
path       = file-name *( "/" file-name )
file-name  = *"." non-dot *name-char / 3*"."
name-char  = %x1-2E / %x30-D7FF / %xE000-10FFFF
non-dot    = %x1-2D / %x30-D7FF / %xE000-10FFFF
```

A valid path is a text that matches `path`. The file names of a valid
path are the texts that its `file-name` elements match, in order.

### 3.7 The form of a path

@req path-form=v1
@cites #characters=v1
@cites #notation=v1
@cites #result-list=v1
@cites #paths=v1

For each text that it tests as a path, a conforming program must give
the result "valid" when the text matches `path`, and the result
"invalid" when it does not.

### 3.8 The walk

@req walk=v1
@cites #characters=v1
@cites #utf-8=v1
@cites #trees=v1
@cites #paths=v1

The walk of a valid path in a tree takes the file names of the path in
order. For each file name, it looks up the entry that a folder gives for
the UTF-8 encoding of the file name: the root for the first file name,
and, for each other file name, the folder that the walk found for the
file name before it. For each file name, the outcome is
the first row of this table whose condition holds:

| outcome | condition |
|---|---|
| refused | the tree refuses to look up the file name in the folder |
| no entry | the folder gives no entry for the UTF-8 encoding of the file name |
| symbolic link | the file of the entry is a symbolic link |
| not a folder | the file name is not the last file name of the path, and the file of the entry is a regular file or a file of another kind |
| regular file | the file name is the last file name of the path, and the file of the entry is a regular file |
| not a regular file | the file name is the last file name of the path, and the file of the entry is a folder or a file of another kind |

When no row holds, the file of the entry is a folder, and the walk finds
that folder for the file name. The walk ends at the first file name that
has an outcome, and the outcome of the walk is that outcome. With the
outcome "regular file", the walk finds the regular file of the entry. A
regular file is at a valid path when the walk of the path in the tree
ends with the outcome "regular file" and finds that regular file.

### 3.9 Reading at a text that is not a path

@req read-paths=v1
@cites #characters=v1
@cites #notation=v1
@cites #result-list=v1
@cites #trees=v1
@cites #paths=v1

For each text that it reads as a path in a tree and that does not match
`path`, a conforming program must give the result "invalid", and it
must look up no entry name in the tree.

### 3.10 Reading by the walk

@req read-walk=v1
@cites #trees=v1
@cites #paths=v1
@cites #walk=v1

To read a valid path in a tree, a conforming program must look up each
file name of the path only in the folder in which the walk of the path
looks it up, and it must read the content only from the regular file
that it found for the last file name, with no further lookup of any
file name.

### 3.11 Symbolic links

@req read-links=v1
@cites #utf-8=v1
@cites #trees=v1
@cites #paths=v1
@cites #walk=v1

When it reads a path in a tree, a conforming program must follow no
symbolic link: it must look up no entry name in a file that a symbolic
link refers to, and it must read no byte from such a file.

### 3.12 Files of another kind

@req read-other-kinds=v1
@cites #utf-8=v1
@cites #trees=v1
@cites #paths=v1

When it reads a path in a tree, a conforming program must read no byte
from a file of another kind, and it must not wait for another process
to open, write, or close such a file.

### 3.13 The result of a read

@req read-results=v1
@cites #result-list=v1
@cites #utf-8=v1
@cites #trees=v1
@cites #paths=v1
@cites #walk=v1

For each valid path that it reads in a tree, a conforming program must
give the result that this table gives for the outcome of the walk of
the path and, for the outcome "regular file", for the content of the
regular file that the walk finds:

| outcome of the walk | content of the regular file | result |
|---|---|---|
| refused | | cannot read |
| no entry | | no file |
| not a folder | | no file |
| symbolic link | | symbolic link |
| not a regular file | | not a regular file |
| regular file | the tree refuses to give the content | cannot read |
| regular file | a byte sequence that is not UTF-8 text | not UTF-8 |
| regular file | a byte sequence that is UTF-8 text | found |

### 3.14 The text of a file

@req read-text=v1
@cites #characters=v1
@cites #result-list=v1
@cites #utf-8=v1
@cites #trees=v1
@cites #walk=v1

With the result "found", a conforming program must give the text of the
content of the regular file that the walk found, with every character
of that text in its order: it must add no character, remove no
character, and change no character.

### 3.15 Lines

@req lines=v1
@cites #characters=v1

The byte order mark of a text is its first character when that
character is U+FEFF. The body of a text is the text without its byte
order mark, or the whole text when the text has no byte order mark. A
line ending is a line feed of the body, together with the carriage
return right before that line feed when there is one. The line endings
divide the body into runs: the run before the first line ending, the
run between each two line endings that follow each other, and the run
after the last line ending; a body with no line ending is one run. The
lines of the text are these runs, in the order of the body, except the
last run when it is empty. The lines are numbered from 1. A character
of a line is a character of the body that the line holds.

### 3.16 Positions

@req positions=v1
@cites #characters=v1
@cites #lines=v1

A position is a pair of numbers: a line number and a column. The
position of a character of a line has the number of that line as its
line number, and 1 more than the number of characters of the line
before that character as its column. The position of a character of a
line ending has the number of the line right before that line ending as
its line number, and 1 more than the number of characters of that line
as its column.

### 3.17 Spans

@req spans=v1
@cites #characters=v1
@cites #lines=v1
@cites #positions=v1

A span of a text is a run of the body of the text that holds at least
one character of a line. The start of a span is the position of its
first character. The end of a span is the position whose line number is
the line number of the last character of the span that is a character
of a line, and whose column is 1 more than the column of that
character.

### 3.18 The positions that a program gives

@req position-values=v1
@cites #characters=v1
@cites #lines=v1
@cites #positions=v1

When a conforming program gives the position of a character of the
body of a text, it must give the position of that character.

### 3.19 The spans that a program gives

@req span-values=v1
@cites #characters=v1
@cites #lines=v1
@cites #positions=v1
@cites #spans=v1

When a conforming program gives the start and the end of a span of a
text, it must give the start of that span and the end of that span.

### 3.20 The grammar of globs

@req glob-grammar=v1
@cites #characters=v1
@cites #notation=v1

These productions give the form of a glob:

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

A valid glob is a text that matches `glob`. The glob segments of a
valid glob are the texts that its `glob-segment` elements match, in
order, and then the text `**` when the glob ends with `/`.

### 3.21 The form of a glob

@req glob-form=v1
@cites #characters=v1
@cites #notation=v1
@cites #result-list=v1
@cites #glob-grammar=v1

For each text that it tests as a glob, a conforming program must give
the result "valid" when the text matches `glob`, and the result
"invalid" when it does not.

### 3.22 The meaning of a glob

@req glob-meaning=v1
@cites #characters=v1
@cites #paths=v1
@cites #glob-grammar=v1

A valid path fits a valid glob when the file names of the path can be
divided into groups of file names that follow each other, one group for
each glob segment of the glob, in the order of the glob segments, such
that each group fits its glob segment:

- A group fits a glob segment `**` that is the last glob segment of the
  glob when the group holds one or more file names.
- A group fits a glob segment `**` that is not the last glob segment of
  the glob when the group holds zero or more file names.
- A group fits each other glob segment when the group holds exactly one
  file name, and that file name fits the glob segment.

A file name fits a glob segment other than `**` when the file name can
be divided into runs, one run for each character of the glob segment,
in order, such that each run fits its character. A run fits the
character `*`, whatever characters it holds, the empty run included. A
run fits each other character when the run is that one character.

### 3.23 Testing a path against a glob

@req glob-fit=v1
@cites #result-list=v1
@cites #paths=v1
@cites #glob-grammar=v1
@cites #glob-meaning=v1

For each valid glob and each valid path that it tests together, a
conforming program must give the result "fits" when the path fits the
glob, and the result "does not fit" when it does not.

### 3.24 Path sets

@req path-sets=v1
@cites #characters=v1
@cites #glob-grammar=v1

A path set is a finite sequence of texts, its members. A member whose
first character is `!` is a `!` glob, and the glob of that member is the
text of the member after that `!`. Each other member is a plain glob,
and the glob of that member is the member.

### 3.25 The members of a path set

@req path-set-members=v1
@cites #notation=v1
@cites #result-list=v1
@cites #glob-grammar=v1
@cites #path-sets=v1

A conforming program must reject each path set that it tests and that
holds a member whose glob does not match `glob`.

### 3.26 Repeated members

@req path-set-unique=v1
@cites #characters=v1
@cites #result-list=v1
@cites #path-sets=v1

A conforming program must reject each path set that it tests and in
which two members are the same text.

### 3.27 A plain glob in a path set

@req path-set-plain=v1
@cites #result-list=v1
@cites #path-sets=v1

A conforming program must reject each path set that it tests and that
holds at least one member and no plain glob.

### 3.28 Acceptance of a path set

@req path-set-acceptance=v1
@cites #result-list=v1
@cites #path-sets=v1
@cites #path-set-members=v1
@cites #path-set-unique=v1
@cites #path-set-plain=v1

A conforming program must accept each path set that it tests, unless
one of these requirements states that the program must reject it:
`path-set-members`, `path-set-unique`, and `path-set-plain`.

### 3.29 The meaning of a path set

@req path-set-meaning=v1
@cites #paths=v1
@cites #glob-grammar=v1
@cites #glob-meaning=v1
@cites #path-sets=v1

A valid path is in a path set whose members all have a valid glob when
the path fits the glob of at least one plain glob of the path set, and
the path fits the glob of no `!` glob of the path set.

### 3.30 Testing a path against a path set

@req path-set-membership=v1
@cites #result-list=v1
@cites #paths=v1
@cites #path-sets=v1
@cites #path-set-acceptance=v1
@cites #path-set-meaning=v1

For each path set that it accepts and each valid path that it tests
together, a conforming program must give the result "in the set" when
the path is in the path set, and the result "not in the set" when it is
not.

### 3.31 One result for each input

@req results=v1
@cites #characters=v1
@cites #result-list=v1
@cites #trees=v1
@cites #paths=v1
@cites #glob-grammar=v1
@cites #path-sets=v1

A conforming program must give exactly one result for each input of
this table that it tests or reads, and only a result that the table
lists for that input:

| input | result |
|---|---|
| a text that it tests as a path | valid or invalid |
| a text that it tests as a glob | valid or invalid |
| a valid glob and a valid path that it tests together | fits or does not fit |
| a path set that it tests | valid or invalid |
| a path set that it accepts and a valid path that it tests together | in the set or not in the set |
| a text that it reads as a path in a tree | invalid, found, no file, symbolic link, not a regular file, not UTF-8, or cannot read |

## 4. Conformance

A program conforms to this design when it meets every requirement of
section 3.

Each vector below gives an input and the result that a conforming
program gives for it. The text after "invalid:", or after a result in
the column of results, explains the result. A program does not give it.

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

Each row gives a tree on a file system, a text to read as a path in it,
and the result. The tree holds only the files that the row names. A
content written as a text is the UTF-8 encoding of that text. A content
written as bytes gives each byte in hexadecimal digits.

| tree | text | result |
|---|---|---|
| the regular file `a.md` with the content `hi` | `a.md` | found: the text `hi` |
| the folder `docs`, which holds the regular file `a.md` with the content `hi` | `docs/a.md` | found: the text `hi` |
| the regular file `a.md` with an empty content | `a.md` | found: the empty text |
| the regular file `a.md` with the content `hi` | `b.md` | no file |
| the regular file `a.md` with the content `hi` | `a.md/b.md` | no file: `a.md` is not a folder |
| the regular file `a.md` with the content `hi` | `A.md` | no file, on a file system that treats no two different byte sequences as the same name |
| the folder `docs` | `docs` | not a regular file |
| the pipe `p`, which no process opens | `p` | not a regular file, at once |
| the symbolic link `a.md`, which refers to the regular file `b.md`, and that regular file | `a.md` | symbolic link |
| the symbolic link `d`, which refers to the folder `docs`, and that folder, which holds the regular file `a.md` | `d/a.md` | symbolic link |
| the symbolic link `a.md`, which refers to no file | `a.md` | symbolic link |
| the folder whose entry name is the byte `E9`, which holds the regular file `x` | `é/x`, with `é` as U+00E9 | no file, on a file system that treats no two different byte sequences as the same name: the UTF-8 encoding of `é` is the bytes `C3 A9` |
| the regular file `a.md` with the content `FF FE` | `a.md` | not UTF-8 |
| the regular file `a.md` with the content `ED A0 80` | `a.md` | not UTF-8: these bytes write U+D800, which is not a character |
| the regular file `a.md` with the content `C0 AF` | `a.md` | not UTF-8: an overlong form |
| the regular file `a.md` with the content `EF BB BF 78` | `a.md` | found: the text U+FEFF, `x` |
| the regular file `a.md` with the content `61 0D 0A 62` | `a.md` | found: the text `a`, a carriage return, a line feed, `b` |
| the regular file `a.md` with the content `65 CC 81` | `a.md` | found: the text `e`, U+0301 |
| the folder `docs`, which the program has no permission to search, and which holds the regular file `a.md` | `docs/a.md` | cannot read |
| the regular file `a.md`, which the program has no permission to read | `a.md` | cannot read |
| any tree | `../a.md` | invalid |
| any tree | `/etc/passwd` | invalid |

### 4.3 Lines and positions

Each row gives a text, its lines, and the position of some of its
characters.

| text | lines | positions |
|---|---|---|
| `a`, a line feed, `b` | `a`; `b` | `b`: line 2, column 1 |
| `a`, a line feed | `a` | the line feed: line 1, column 2 |
| a line feed | the empty text | the line feed: line 1, column 1 |
| two line feeds | the empty text; the empty text | the second line feed: line 2, column 1 |
| the empty text | none | none |
| U+FEFF | none | none |
| `ab`, a carriage return, a line feed, `c` | `ab`; `c` | the carriage return: line 1, column 3; the line feed: line 1, column 3; `c`: line 2, column 1 |
| `a`, a carriage return | `a` and a carriage return | the carriage return: line 1, column 2 |
| `a`, a carriage return, a carriage return, a line feed | `a` and a carriage return | the first carriage return: line 1, column 2; the second carriage return: line 1, column 3 |
| `a`, a carriage return, `b` | `a`, a carriage return, `b` | `b`: line 1, column 3 |
| U+FEFF, `x` | `x` | `x`: line 1, column 1 |
| `x`, U+FEFF | `x` and U+FEFF | U+FEFF: line 1, column 2 |
| U+FEFF, U+FEFF, `x` | U+FEFF and `x` | the second U+FEFF: line 1, column 1; `x`: line 1, column 2 |
| `é`, `x`, with `é` as U+00E9 | `é` and `x` | `x`: line 1, column 2 |
| `e`, U+0301, `x` | `e`, U+0301, and `x` | `x`: line 1, column 3 |
| U+1F600, `x` | U+1F600 and `x` | `x`: line 1, column 2 |
| a tab, `x` | a tab and `x` | `x`: line 1, column 2 |

Each row below gives a text, a span of that text, and the start and the
end of the span.

| text | span | start | end |
|---|---|---|---|
| `abc` | `b` | line 1, column 2 | line 1, column 3 |
| `ab`, a line feed, `cd` | `b`, the line feed, `c` | line 1, column 2 | line 2, column 2 |
| `ab`, a carriage return, a line feed, `cd` | `ab`, the carriage return, the line feed | line 1, column 1 | line 1, column 3 |
| `ab`, a carriage return, a line feed, `cd`, a line feed | the whole text | line 1, column 1 | line 2, column 3 |
| a line feed, `x` | the whole text | line 1, column 1 | line 2, column 2 |
| `a`, a line feed, a line feed, `b` | `a` and the two line feeds | line 1, column 1 | line 1, column 2 |
| U+FEFF, `ab` | `ab` | line 1, column 1 | line 1, column 3 |
| `é`, `x` | `x` | line 1, column 2 | line 1, column 3 |

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

Each item gives the members of a path set, in order, and its result.
For a valid path set, it also gives paths that are in the set, for
which a conforming program gives the result "in the set", and paths
that are not in the set, for which it gives the result "not in the
set".

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
- `docs/` and `!`: invalid: the glob of `!` is the empty text, which is
  not a glob.
- `docs/` and `!/x`: invalid: the glob `/x` starts with `/`.
- `a?`: invalid: the glob `a?` holds `?`.
