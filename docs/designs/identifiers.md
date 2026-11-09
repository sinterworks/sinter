<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Identifiers
@design identifiers=v1
Each tag line, inline citation, and id pattern of Sinter has one written form, by which a parser accepts or rejects the text and gives the names and revisions that the text holds.

## 1. Terms

| term | meaning |
|---|---|
| conforming parser | a program that meets every requirement of section 4 |
| must | states an obligation of a conforming parser |
| character | one Unicode code point |
| printable ASCII character | a character from `!` to `~`; a space is not one |
| line | a sequence of characters with no line feed, which a parser reads as one unit |
| tag line | a line whose first character, after the spaces and tabs at its start, is `@` |
| tag word | the `@` at the start of a tag line, with the ASCII letters, ASCII digits, and `-` right after it, such as `@req` |
| Sinter tag word | one of the fifteen tag words of Sinter, such as `@req` and `@cites` |
| declaration | a tag line that declares a thing, such as `@req size-limit=v2` |
| citation | a tag line that cites a thing, such as `@cites packs#size-limit=v2` |
| status tag | a tag line with `@deferred`, `@deprecated`, or `@rejected`, which has no target |
| directive | a tag line with `@ack` or `@extern`, each of which has a form of its own |
| target | the run of characters after the tag word of a declaration, a citation, or an `@extern` line and the spaces after the tag word, which names a thing; also the destination of an inline citation after `sinter:` |
| inline description | the text of a tag line after its target, or after the tag word of a status tag; an `@ack` line has none |
| segment | a run of ASCII letters and ASCII digits, with one `-`, `_`, or `.` at most between two of them, such as `size-limit` |
| slug | one segment, or several segments joined by `/`, that names a thing of the repository, such as `packs` or `billing/auth` |
| custom namespace | the segments of a slug before its last segment, such as `billing` in `billing/auth` |
| part name | a segment that names one part of a thing, such as a requirement of a design or a section of an external document |
| full name | a slug, `#`, and a part name, such as `packs#descriptor` |
| name | a slug, a full name, or `#` and a part name |
| kind word | a word before `:` at the start of a target, which states what kind of thing the target names, such as `req` in `req:packs#size-limit=v2` |
| label | a run of printable ASCII characters other than `/`, `#`, `@`, `*`, and `=`, such as `v2`, that names one revision of a thing |
| revision | a label, or `*`, which stands for any revision; a target gives it after `=`, right after the name of the thing that it is a revision of |
| every-part target | a target such as `docs=v3#*`, which stands for every part of the thing that its slug names |
| external namespace | a name, such as `gh`, for a set of things outside the repository, such as the issues of a tracker |
| external id | the name of an external namespace, `/`, and an id, such as `gh/42`; the id names one thing of the external namespace |
| id pattern | a small regular expression that matches the ids of one external namespace |
| head | the text of a target without its kind word, up to its first `#` or `=` |
| external target | a target whose head starts with the name of an external namespace, followed by `/` or by the end of the head |
| inline citation | a markdown link whose destination starts with `sinter:` |
| destination | the address of a markdown link, such as `sinter:packs#size-limit=v2` in `[the limit](sinter:packs#size-limit=v2)` |
| link text | the text between the brackets of a markdown link, such as `the limit` in `[the limit](sinter:packs#size-limit=v2)` |
| parameter | an input of a parser that a program binds before the parser reads lines and links |
| binding | what a program binds a parameter to |
| valid, invalid | the results of a conforming parser for an input that it accepts and for an input that it rejects |
| value | what a conforming parser gives from a valid input, such as the slug of its target |

## 2. The written forms

### 2.1 Tag lines and tag words

A parser reads lines. A line is a sequence of characters with no line
feed. A line is a tag line when its first character, after the spaces
and tabs at its start, is `@`. Every such line is a tag line, whatever
its tag word is.

The tag word of a tag line is its `@` and the longest run of ASCII
letters, ASCII digits, and `-` right after that `@`. The run can be
empty.

| line | tag word |
|---|---|
| `@req size-limit=v2` | `@req` |
| `   @finding-class late-fee=v1` | `@finding-class` |
| `@foo-bar: text` | `@foo-bar` |
| `@param x The input.` | `@param` |
| `@ alone` | `@` |
| `see @req size-limit=v2` | none: the line is not a tag line |

Sinter has fifteen tag words. A tag word is a Sinter tag word only when
it has the characters of one of them, with the same case, so `@Req` is
not `@req`.
For a tag line whose tag word is not a Sinter tag word, a conforming
parser gives the result "other tag word" and the tag word, and nothing
more.

A Sinter tag word makes its tag line a declaration, a citation, a
status tag, or a directive. The tag word also sets the form of the line
and of its target:

| tag word | tag line | target | revision |
|---|---|---|---|
| `@decision`, `@design`, `@finding-class` | declaration | a slug | a label |
| `@req` | declaration | a slug or a full name | a label |
| `@spec` | declaration | a slug of one segment, or a full name | a label |
| `@cites` | citation | a name or an external id | a label or `*`; none after an external id |
| `@refines`, `@satisfies`, `@verifies` | citation | a name or an external id | a label; none after an external id |
| `@supersedes` | citation | a name, an external id, or an every-part target | a label; none after an external id |
| `@deferred`, `@deprecated`, `@rejected` | status tag | none | none |
| `@extern` | directive | a kind word, `:`, and a part name | none |
| `@ack` | directive | none; a form of its own (section 2.6) | none |

In a declaration, a citation, and an `@extern` line, one or more spaces
or tabs follow the tag word, and then the target. The target ends at
the next space or tab, or at the end of the line. The inline
description is the text after the target, without the spaces and tabs
at its start. A status tag has no target, and its inline description
is the text after its tag word, without the spaces and tabs at its
start. Example: in `@req size-limit=v2 A descriptor has at most 1 MiB.`,
the target is `size-limit=v2`, and the inline description is
`A descriptor has at most 1 MiB.`.

In a valid tag line, the character right after a Sinter tag word is a
space or a tab, or the line ends there. So `@req:size-limit=v2` and
`@deprecated.` are invalid.

### 2.2 Names

A segment is a run of ASCII letters and ASCII digits, with one `-`,
`_`, or `.` at most between two of them. Examples of segments: `packs`,
`size-limit`, `my_docs.v2`, `Auth`. The texts `-docs`, `docs-`,
`docs--x`, and `docs x` are not segments.

A slug is one segment, such as `packs`, or several segments joined by
`/`, such as `billing/auth`. The segments before the last one are the
custom namespace of the slug: `billing` in `billing/auth`.

A part name is one segment. A full name is a slug, `#`, and a part
name, such as `packs#descriptor` or `billing/auth#lockout`. A target
can also hold `#` and a part name with no slug before the `#`, as in
`#descriptor=v1`. Such a target names the part `descriptor` of the thing
whose text holds the target. A name is a slug, a full name, or `#` and
a part name.

A conforming parser gives each name as it is written, so
`Auth-Lockout` and `auth-lockout` stay two different texts.

### 2.3 Kind words

A kind word states what kind of thing a target names. The six kind
words are `decision`, `design`, `finding-class`, `req`, `spec`, and
`term`. A kind word stands at the start of a target, with a `:` after
it: `req:packs#size-limit=v2`, `spec:rfc/8259`.

The target of a citation and the target of an inline citation can start
with a kind word. The target of `@extern` always starts with one. The
target of a declaration holds no kind word, and an every-part target
holds none. A name holds no `:`. So the target `plan:upkeep=*` is
invalid: `plan` is not a kind word, and `plan:upkeep` is not a slug.

### 2.4 Revisions

A revision is a label or `*`. A label names one revision of a thing. A
label is a run of printable ASCII characters other than `/`, `#`, `@`,
`*`, and `=`, such as `v2`, `2026-11`, `v1.2.0`, or `rc1`. `*` stands
for any revision.

A revision follows the name of the thing that it is a revision of,
after `=`. A target holds one revision at most. In `docs#size=v2`, `v2`
is a revision of the part `size` of `docs`, and the target holds no
revision of `docs`.

| target | name | revision | a revision of |
|---|---|---|---|
| `docs=v3` | the slug `docs` | `v3` | `docs` |
| `billing/auth=v3` | the slug `billing/auth` | `v3` | `billing/auth` |
| `docs#size=v2` | the full name `docs#size` | `v2` | the part `size` of `docs` |
| `#size=v2` | `#` and the part name `size` | `v2` | the part `size` of the thing whose text holds the target |
| `docs=*` | the slug `docs` | `*` | `docs` |
| `docs#size=*` | the full name `docs#size` | `*` | the part `size` of `docs` |

The target of every declaration, citation, and inline citation carries
a revision, except an external target. The target of a declaration
carries a label. The target of `@cites` and the target of an inline
citation carry a label or `*`. The target of each other citation word
carries a label. An external target, the target of `@extern`, and an
`@ack` line carry no revision.

A revision has no default. So a declaration, a citation, or an inline
citation whose target is not external and carries no revision is
invalid. For example, `@cites billing/auth` and `@design billing/auth`
are invalid: each target is the slug `billing/auth`, which has two
segments, and carries no revision.

A label ends at the first space or tab, so a character right after a
target belongs to its label: in `@cites docs=v1, and more`, the label
is `v1,`. A label holds no `=`, so `@cites docs=v=1` is invalid.

An every-part target, such as `docs=v3#*`, stands for every part of
the thing that its slug names. Only the target of `@supersedes` can be
an every-part target. Its revision is a label, and it follows the slug,
before `#*`: in `docs=v3#*`, `v3` is a revision of `docs`. An
every-part target holds no kind word. So `@supersedes docs#*=v3` and
`@supersedes docs=*#*` are invalid.

### 2.5 External ids

The parameter `external-namespaces` (section 3) gives each external
namespace with its id pattern. An external id is the name of an
external namespace, `/`, and an id, such as `gh/42`. The id is a run of
printable ASCII characters other than `#`, `=`, and `@`, and the id
pattern of the external namespace matches the id. An external id can
take `#` and a part name, which names a part of the external thing, as
in `rfc/8259#section-6`. An external id carries no revision.

One rule decides whether a target holds an external id. The head of a
target is its text after its kind word and the `:` after the kind word,
and before its first `#` or `=`. When the head starts with the name of
an external namespace, followed by `/` or by the end of the head, the
target is an external target. A conforming parser reads an external
target only as an external id, with an optional `#` and part name after
it. It reads no other target as an external id.

So the binding of `external-namespaces` decides how a target reads.
When `gh` is an external namespace, `@cites gh/42` cites the external
id `gh/42`. When `gh` is not one, the target `gh/42` is the slug
`gh/42`: `@cites gh/42` is invalid, because it carries no revision, and
`@cites gh/42=v1` is valid. Under a binding with the external namespace
`gh`:

- `@cites gh/0` is invalid when the id pattern of `gh` does not match
  `0`.
- `@cites gh/42=v1` is invalid, because the target is external, and an
  id holds no `=`.
- `@cites gh` is invalid, because no `/` and id follow `gh`.
- `@cites gh=v1` is invalid: its head is `gh`, so the target is
  external, and no `/` and id follow `gh`.
- `@design gh=v1` is invalid, because the target is external, and the
  target of a declaration is never an external id.
- `@supersedes gh/42#*` is invalid, because the target is external and
  `*` is not a part name.

### 2.6 The directives `@extern` and `@ack`

The target of `@extern` is a kind word, `:`, and a part name, such as
`spec:descriptor`. It holds no slug, no `#`, and no revision.

An `@ack` line holds two or more runs of characters after `@ack`, with
spaces or tabs between them:

- The first is a slug.
- The last is the **hash**: from 8 to 64 lower-case hexadecimal digits,
  `0` to `9` and `a` to `f`.
- The text between these two, without the spaces and tabs at its two
  ends, is the **subject**. The subject can be empty, and it can hold
  any character, spaces and `@` included.

Spaces and tabs can follow the hash, and nothing else can. Example: in
`@ack retired docs#size=v2 3f2a9c1d`, the slug is `retired`, the subject
is `docs#size=v2`, and the hash is `3f2a9c1d`.

### 2.7 Inline citations

An inline citation is a markdown link whose destination starts with the
seven characters `sinter:`. A link is a link as CommonMark 0.31.2
defines it: an inline link, a reference link, or an autolink. An image
is not a link, so `![x](sinter:packs#size-limit=v2)` is not an inline
citation.

The destination of an inline link or a reference link is its link
destination as CommonMark gives it. The angle brackets around it go,
and each backslash escape, entity reference, and numeric character
reference becomes its character. No percent-decoding applies, so `%23`
is three characters and not `#`. So
`[x](sinter:packs\#size-limit=v2)` and
`[x](sinter:packs&#35;size-limit=v2)` both have the destination
`sinter:packs#size-limit=v2`, and `[x](sinter:packs%23size-limit=v2)`
is invalid. The destination of an autolink is its text between `<` and
`>`.

The target of an inline citation is its destination after `sinter:`.
The target is a name, `=`, and a revision, or an external id, with an
optional kind word before it. As in the target of `@cites`, the
revision is a label or `*`, and an external id carries no revision. So
`[auth](sinter:billing/auth=v3)` cites the slug `billing/auth` with the
revision `v3`, and `[auth](sinter:billing/auth)` is invalid. The rule
of external targets (section 2.5) applies as it applies in a tag line,
so `[x](sinter:gh/42=v2)` is invalid.

The link text is the text between the brackets of the link, as it
stands in the document: `*the* limit` in
`[*the* limit](sinter:packs#size-limit=v2)`. An inline citation whose
link text holds no characters, such as
`[](sinter:packs#size-limit=v2)`, is invalid. The link text of an
autolink, such as `<sinter:req:packs#size-limit=v2>`, is its text
between `<` and `>`.

### 2.8 Id patterns

An id pattern is a small regular expression. It matches an id only when
it matches the whole id. It is built from these elements:

| element | form | matches |
|---|---|---|
| literal | one printable ASCII character other than `\ . [ ] ( ) { } * + ? \| ^ $ # = @` | that character |
| character class | `[`, one or more members, `]` | one character that a member matches |
| member | a printable ASCII character other than `\ [ ] ^ - # = @` | that character |
| member | a range `x-y`: two digits, two upper-case letters, or two lower-case letters, with `x` not after `y` | each character from `x` to `y` |
| member | `-`, first or last in its character class | `-` |
| group | `(`, a pattern, `)` | what the pattern matches |
| sequence | elements one after another | what each element matches, one after another |
| alternation | `a\|b` | what `a` matches, or what `b` matches |
| quantifier | `?`, `*`, `+`, `{n}`, `{n,}`, or `{n,m}` after a literal, a character class, or a group | the element 0 or 1 times; 0 or more times; 1 or more times; `n` times; `n` or more times; from `n` to `m` times |

Alternation binds loosest, so `ab|c` matches `ab` and `c`. A quantifier
applies to the one literal, character class, or group before it, and an
element takes one quantifier at most. In a quantifier, `n` and `m` are
decimal numbers from 0 to 255, written with no leading zero, and `n` is
not greater than `m`. Case always matters. A character class can match
characters that a literal leaves out, such as `.` and `+`: `[.]`,
`[+]`.

These conditions also apply to an id pattern:

- It does not match the empty id. So `[0-9]*` is invalid.
- It holds 1,000 characters at most.
- Its size is 1,000 at most. The size counts the literals and the
  character classes of the pattern when each quantifier is written out
  as copies of its element. `{n}` counts as `n` copies, `{n,m}` counts
  as `m` copies, and each of them counts as one copy at least. `{n,}`
  counts as `n` copies and one more. `?`, `*`, and `+` count as one
  copy. Examples: `([0-9]{3}-){10}` has the size 40, and
  `((a{0,255}){0,255})b` has the size 65,026, so it is invalid.

| id pattern | ids that it matches |
|---|---|
| `[1-9][0-9]*` | the numbers of GitHub issues and pull requests, such as `42` |
| `[A-Z]+-[1-9][0-9]*` | Jira keys, such as `PROJ-1` |

A valid id pattern matches the same ids in POSIX extended regular
expressions in the POSIX locale, in RE2, and in ECMAScript without the
`v` flag, when each of them matches the id pattern against the whole
id.

### 2.9 Results and values

A conforming parser gives a result for every input, and it never stops
with an error. A line gets one of four results: not a tag line, other
tag word, valid, or invalid. A markdown link or image gets one of three
results: not an inline citation, valid, or invalid. An id pattern and a
binding of `external-namespaces` each get valid or invalid. For an id
pattern that it accepts and an id, the parser gives matches or does not
match.

For a valid input, the parser also gives its values, such as the kind
word, the slug, the custom namespace, the part name, the external
namespace and the id, the revision, the inline description, and the
link text. Each value that is a text is a run of the characters of the
input, as it is written.

## 3. Parameters

### 3.1 `external-namespaces`

The parameter `external-namespaces` gives the external namespaces and
their id patterns. Its binding is a finite set of pairs. Each pair
holds the name of one external namespace and the id pattern of that
external namespace. A program binds the parameter before the parser
reads lines and links. The binding can be the empty set, and then no
target is external.

The name of an external namespace is a run of lower-case ASCII letters
and ASCII digits that starts with a letter, with one `-` at most between
two of them, such as `gh` or `my-tracker`. No two pairs of a valid
binding have the same name, and each id pattern of a valid binding is
valid.

## 4. Requirements

### 4.1 Notation

@req notation=v1

A character is a Unicode code point. A space is U+0020, a tab is
U+0009, and a line feed is U+000A. A printable ASCII character is a
character from `!` (U+0021) to `~` (U+007E). An ASCII letter is a
character from `A` to `Z` or from `a` to `z`. An ASCII digit is a
character from `0` to `9`.

The grammars of this design are productions in this notation:

| form | matches |
|---|---|
| `x ::= A` | defines the production `x`, which matches what `A` matches |
| `"abc"` | the characters `abc`, in this order and with this case |
| `#x09` | the one character with the hexadecimal code 09 |
| `[a-z]` | one character whose code is from the code of `a` to the code of `z`, both included; `[A-Za-z0-9]` joins three such ranges |
| `char` | any one character |
| `A B` | what `A` matches, and right after it what `B` matches |
| `A \| B` | what `A` matches, or what `B` matches |
| `A - B` | what `A` matches, when `B` does not match the same text |
| `A?` | what `A` matches, 0 or 1 times |
| `A*` | what `A` matches, 0 or more times |
| `A+` | what `A` matches, 1 or more times |
| `A{n,m}` | what `A` matches, from `n` to `m` times |
| `( A )` | what `A` matches |

`?`, `*`, `+`, and `{n,m}` bind tightest, then `-`, then a sequence
`A B`, and `|` binds loosest. So `A B | C` matches what `A B` matches,
or what `C` matches. A text matches a production when the production
matches the whole of the text.

### 4.2 Tag lines

@req tag-lines=v1
@cites #notation=v1

A line is a sequence of characters that holds no line feed. A tag line
is a line whose first character after the spaces and tabs at its start
is `@`. The tag word of a tag line is that `@` and the longest run of
ASCII letters, ASCII digits, and `-` right after it. The run can be
empty.

### 4.3 Tag words

@req tag-words=v1
@cites #tag-lines=v1

The Sinter tag words are these fifteen tag words, in four sets:

- the declaration words: `@decision`, `@design`, `@finding-class`,
  `@req`, and `@spec`;
- the citation words: `@cites`, `@refines`, `@satisfies`,
  `@supersedes`, and `@verifies`;
- the status words: `@deferred`, `@deprecated`, and `@rejected`;
- the directive words: `@ack` and `@extern`.

A tag word is a Sinter tag word when, and only when, it has the
characters of one of these fifteen words, in the same order and with
the same case. A declaration is a tag line whose tag word is a
declaration word. A citation is a tag line whose tag word is a citation
word. A status tag is a tag line whose tag word is a status word. A
directive is a tag line whose tag word is a directive word. An `@ack`
line is a tag line whose tag word is `@ack`, and an `@extern` line is a
tag line whose tag word is `@extern`.

### 4.4 Spaces, targets, and inline descriptions

@req line-layout=v1
@cites #notation=v1
@cites #tag-lines=v1
@cites #tag-words=v1

These productions give the spaces and tabs of a tag line:

```
indent  ::= ( " " | #x09 )*
gap     ::= ( " " | #x09 )+
rest    ::= ( gap char* )?
```

The target of a declaration, a citation, or an `@extern` line is the
text that starts after the spaces and tabs that follow its tag word,
and that ends before the next space or tab, or at the end of the line.
The inline description of a declaration, a citation, or an `@extern`
line is the text of the line after its target, without the spaces and
tabs at its start. The inline description of a status tag is the text
of the line after its tag word, without the spaces and tabs at its
start. An inline description can be empty.

### 4.5 Segments and names

@req segments=v1
@cites #notation=v1

These productions give the forms of names:

```
alnum      ::= [A-Za-z0-9]
segment    ::= alnum+ ( ( "-" | "_" | "." ) alnum+ )*
slug       ::= segment ( "/" segment )*
part-name  ::= segment
full-name  ::= slug "#" part-name
name       ::= slug | full-name | "#" part-name
```

The custom namespace of a slug that holds a `/` is the text of the slug
before its last `/`.

### 4.6 Kind words

@req kind-words=v1
@cites #notation=v1

The kind words are the texts that this production matches:

```
kind-word  ::= "decision" | "design" | "finding-class" | "req"
             | "spec" | "term"
```

### 4.7 Revisions

@req revisions=v1
@cites #notation=v1

These productions give the forms of a label and of a revision:

```
label     ::= ( [!-~] - ( "/" | "#" | "@" | "*" | "=" ) )+
revision  ::= label | "*"
```

### 4.8 The grammar of id patterns

@req id-pattern-grammar=v1
@cites #notation=v1

A conforming parser must reject an id pattern that does not match the
production `pattern`:

```
pattern     ::= branch ( "|" branch )*
branch      ::= piece+
piece       ::= atom quantifier?
atom        ::= literal | char-class | "(" pattern ")"
literal     ::= [!-~] - ( "\" | "." | "[" | "]" | "(" | ")" | "{" | "}"
                        | "*" | "+" | "?" | "|" | "^" | "$" | "#" | "="
                        | "@" )
char-class  ::= "[" ( "-" member* | member+ ) "-"? "]"
member      ::= range | single
range       ::= [0-9] "-" [0-9] | [A-Z] "-" [A-Z] | [a-z] "-" [a-z]
single      ::= [!-~] - ( "\" | "[" | "]" | "^" | "-" | "#" | "=" | "@" )
quantifier  ::= "?" | "*" | "+" | "{" count "}" | "{" count ",}"
              | "{" count "," count "}"
count       ::= "0" | [1-9] [0-9]*
```

The number of a `count` is the decimal number that its digits write.
The quantifiers `{n}`, `{n,}`, and `{n,m}` are the forms
`"{" count "}"`, `"{" count ",}"`, and `"{" count "," count "}"`, where
`n` is the number of the first `count`, and `m` is the number of the
second `count`.

### 4.9 Ranges in id patterns

@req id-pattern-ranges=v1
@cites #notation=v1
@cites #id-pattern-grammar=v1

A conforming parser must reject an id pattern that holds a `range`
whose first character has a greater code than its last character.

### 4.10 Counts in id patterns

@req id-pattern-counts=v1
@cites #id-pattern-grammar=v1

A conforming parser must reject an id pattern that holds a `count`
whose number is greater than 255, or a quantifier `{n,m}` in which `n`
is greater than `m`.

### 4.11 The meaning of id patterns

@req id-pattern-meaning=v1
@cites #notation=v1
@cites #id-pattern-grammar=v1

A text that matches `pattern` matches an id when, and only when, the
text matches the whole id with these meanings:

- A `literal` matches the one character that it is.
- A `char-class` matches one character that one of its members matches.
  A `range` matches each character whose code is from the code of its
  first character to the code of its last character, both included. A
  `single` matches the one character that it is. A `-` right after the
  `[` or right before the `]` of a `char-class` matches the character
  `-`.
- An `atom` of the form `"(" pattern ")"` matches what its inner
  `pattern` matches.
- A `piece` with no `quantifier` matches what its `atom` matches. A
  `piece` with a `quantifier` matches a text that is a sequence of
  texts that its `atom` matches, one after another. The number of texts
  in the sequence is 0 or 1 for `?`, 0 or more for `*`, 1 or more for
  `+`, exactly `n` for `{n}`, `n` or more for `{n,}`, and from `n` to
  `m` for `{n,m}`. Two texts of the sequence can differ.
- A `branch` matches a text when its pieces, in their order, match
  texts that together make that text, one after another.
- A `pattern` matches a text when one of its branches matches that
  text.

For an id pattern that it accepts and an id, a conforming parser must
give the result "matches" when the id pattern matches the id, and the
result "does not match" when it does not.

### 4.12 The empty id

@req id-pattern-empty=v1
@cites #id-pattern-meaning=v1

The empty id is the id of no characters. A conforming parser must
reject an id pattern that matches the empty id.

### 4.13 The size of an id pattern

@req id-pattern-size=v1
@cites #id-pattern-grammar=v1

The size of a text that matches `pattern` is a number that these rules
give:

- A `literal` and a `char-class` each have the size 1.
- An `atom` of the form `"(" pattern ")"` has the size of its inner
  `pattern`.
- A `piece` with no `quantifier` has the size of its `atom`. A `piece`
  with a `quantifier` has the size of its `atom`, times a number of
  copies. The number of copies is 1 for `?`, `*`, and `+`. It is `n`
  for `{n}` and `m` for `{n,m}`, or 1 when that number is 0. It is `n`
  plus 1 for `{n,}`.
- A `branch` has the sum of the sizes of its pieces.
- A `pattern` has the sum of the sizes of its branches.

A conforming parser must reject an id pattern whose size is greater
than 1,000.

### 4.14 The length of an id pattern

@req id-pattern-length=v1
@cites #notation=v1

A conforming parser must reject an id pattern that holds more than
1,000 characters.

### 4.15 External namespaces

@req external-namespaces=v1

`external-namespaces` is a parameter: an input that a program binds
before a conforming parser reads lines and links. A binding of
`external-namespaces` is a finite set of pairs. Each pair holds a name
and an id pattern. The external namespaces are the names of the pairs
of the binding, and the id pattern of an external namespace is the id
pattern of its pair.

### 4.16 The binding of external namespaces

@req namespace-binding=v1
@cites #notation=v1
@cites #external-namespaces=v1
@cites #id-pattern-grammar=v1
@cites #id-pattern-ranges=v1
@cites #id-pattern-counts=v1
@cites #id-pattern-empty=v1
@cites #id-pattern-size=v1
@cites #id-pattern-length=v1

A conforming parser must reject a binding of `external-namespaces` in
each of these cases:

1. A name of the binding does not match `namespace-name`:

   ```
   namespace-name  ::= [a-z] [a-z0-9]* ( "-" [a-z0-9]+ )*
   ```

2. Two pairs of the binding have the same name.
3. An id pattern of the binding is an id pattern that a conforming
   parser must reject.

### 4.17 External ids

@req external-ids=v1
@cites #notation=v1
@cites #segments=v1
@cites #kind-words=v1
@cites #line-layout=v1
@cites #inline-citations=v1
@cites #external-namespaces=v1
@cites #id-pattern-meaning=v1

These productions give the form of an external id. In them,
`namespace` matches the name of each external namespace, and no other
text.

```
external-ref  ::= external-id ( "#" part-name )?
external-id   ::= namespace "/" id
id            ::= ( [!-~] - ( "#" | "=" | "@" ) )+
```

An `external-id` matches a text only when the id pattern of its
`namespace` matches its `id`.

A target starts with a kind word when the text of the target before its
first `:` matches `kind-word`. The head of a target is the text of the
target after that kind word and that `:`, when the target starts with a
kind word, and before the first character of the target that is `#` or
`=`, when the target holds one. The target of a declaration, a
citation, or an inline citation is external when the text of its head
before the first `/` of the head, or the whole head when the head holds
no `/`, is the name of an external namespace. When the target of a line
or of a destination is external, a production matches that line or that
destination only by a match in which `external-ref` matches the target,
without its kind word and the `:` after it when the target starts with
a kind word.

### 4.18 Declarations

@req declarations=v1
@cites #notation=v1
@cites #tag-words=v1
@cites #line-layout=v1
@cites #segments=v1
@cites #revisions=v1
@cites #external-ids=v1

A conforming parser must reject a declaration that does not match
`declaration-line`:

```
declaration-line  ::= indent ( "@decision" | "@design" | "@finding-class" )
                      gap slug "=" label rest
                    | indent "@spec" gap ( segment | full-name ) "=" label rest
                    | indent "@req" gap ( slug | full-name ) "=" label rest
```

### 4.19 Citations

@req citations=v1
@cites #notation=v1
@cites #tag-words=v1
@cites #line-layout=v1
@cites #segments=v1
@cites #kind-words=v1
@cites #revisions=v1
@cites #external-ids=v1

A conforming parser must reject a citation that does not match
`citation-line`:

```
citation-line  ::= indent "@cites" gap
                   ( kind-word ":" )? ( name "=" revision | external-ref ) rest
                 | indent ( "@refines" | "@satisfies" | "@supersedes"
                          | "@verifies" ) gap
                   ( kind-word ":" )? ( name "=" label | external-ref ) rest
                 | indent "@supersedes" gap every-part rest
every-part     ::= slug "=" label "#*"
```

An every-part target is a target that matches `every-part`.

### 4.20 Status tags

@req status-tags=v1
@cites #notation=v1
@cites #tag-words=v1
@cites #line-layout=v1

A conforming parser must reject a status tag that does not match
`status-line`:

```
status-line  ::= indent ( "@deferred" | "@deprecated" | "@rejected" ) rest
```

### 4.21 The directive `@extern`

@req extern=v1
@cites #notation=v1
@cites #tag-words=v1
@cites #line-layout=v1
@cites #segments=v1
@cites #kind-words=v1

A conforming parser must reject an `@extern` line that does not match
`extern-line`:

```
extern-line  ::= indent "@extern" gap kind-word ":" part-name rest
```

### 4.22 The directive `@ack`

@req ack=v1
@cites #notation=v1
@cites #tag-words=v1
@cites #line-layout=v1
@cites #segments=v1

A conforming parser must reject an `@ack` line that does not match
`ack-line`:

```
ack-line  ::= indent "@ack" gap slug ( gap subject )? gap hash ( " " | #x09 )*
subject   ::= ( char - ( " " | #x09 ) ) ( char* ( char - ( " " | #x09 ) ) )?
hash      ::= [0-9a-f]{8,64}
```

### 4.23 Inline citations

@req inline-citations=v1
@cites #notation=v1

A link is a link of a markdown document as CommonMark 0.31.2 defines
it: an inline link, a full, collapsed, or shortcut reference link, or
an autolink. An image is not a link.

The destination of an inline link or a reference link is its link
destination as CommonMark 0.31.2 gives it: without the angle brackets
that enclose it, with each backslash escape resolved, and with each
entity reference and numeric character reference replaced by its
character. No percent-decoding applies to a destination, so a `%` is a
character of the destination. The destination of an autolink is its
text between `<` and `>`.

An inline citation is a link whose destination starts with the seven
characters `sinter:`. The target of an inline citation is the text of
its destination after `sinter:`. The link text of an inline link or a
reference link is the text of the document between the `[` and the `]`
that delimit its link text in CommonMark 0.31.2. The link text of an
autolink is its text between `<` and `>`.

### 4.24 The targets of inline citations

@req inline-targets=v1
@cites #notation=v1
@cites #inline-citations=v1
@cites #segments=v1
@cites #kind-words=v1
@cites #revisions=v1
@cites #external-ids=v1

A conforming parser must reject an inline citation whose destination
does not match `inline-destination`:

```
inline-destination  ::= "sinter:" ( kind-word ":" )?
                        ( name "=" revision | external-ref )
```

### 4.25 The link text of inline citations

@req inline-link-text=v1
@cites #inline-citations=v1

A conforming parser must reject an inline citation whose link text
holds no characters.

### 4.26 Values

@req values=v1
@cites #tag-lines=v1
@cites #tag-words=v1
@cites #line-layout=v1
@cites #segments=v1
@cites #kind-words=v1
@cites #revisions=v1
@cites #external-ids=v1
@cites #declarations=v1
@cites #citations=v1
@cites #extern=v1
@cites #ack=v1
@cites #inline-citations=v1
@cites #inline-targets=v1

The match of an input is the match of the input by one production:
`declaration-line` for a declaration, `citation-line` for a citation,
`extern-line` for an `@extern` line, `ack-line` for an `@ack` line, and
`inline-destination` for the destination of an inline citation.

For each tag line, a conforming parser must give its tag word. For each
declaration, citation, status tag, directive, and inline citation that
it accepts, it must also give each value of this table that the input
holds, and no other value:

| value | input that holds the value | the value |
|---|---|---|
| declaration, citation, status tag, or directive | a tag line with a Sinter tag word | which of these four the tag line is |
| the kind word | an input whose match holds `kind-word` | the text that `kind-word` matches |
| the slug | an input whose match holds `slug` | the text that `slug` matches |
| the slug | a declaration with the tag word `@spec` whose target holds no `#` | the text that `segment` matches |
| the custom namespace | an input with a slug that holds a `/` | the custom namespace of the slug |
| the part name | an input whose match holds `part-name` | the text that `part-name` matches |
| every part | a citation whose target is an every-part target | no text |
| the external namespace | an input whose match holds `external-id` | the text that `namespace` matches |
| the id | an input whose match holds `external-id` | the text that `id` matches |
| the revision | an input whose match holds `label` or `revision` | the text that `label` or `revision` matches, as a revision of the part that the part name names, when the match holds `part-name`, and as a revision of the thing that the slug names, when it does not |
| the inline description | a declaration, a citation, a status tag, or an `@extern` line | its inline description |
| the subject | an `@ack` line | the text that `subject` matches, or the empty text when the match holds no `subject` |
| the hash | an `@ack` line | the text that `hash` matches |
| the link text | an inline citation | its link text |

Each value that is a text is a run of the characters of the line, of
the destination, or of the document, without a change.

### 4.27 Results

@req results=v1
@cites #tag-lines=v1
@cites #tag-words=v1
@cites #inline-citations=v1
@cites #external-namespaces=v1
@cites #id-pattern-meaning=v1

A conforming parser must give one result for each input of this table,
and only a result that the table lists for that input:

| input | result |
|---|---|
| a line that is not a tag line | not a tag line |
| a tag line whose tag word is not a Sinter tag word | other tag word |
| a declaration, a citation, a status tag, or a directive | valid or invalid |
| a link or an image of a markdown document that is not an inline citation | not an inline citation |
| an inline citation | valid or invalid |
| an id pattern, which is any sequence of characters | valid or invalid |
| a binding of `external-namespaces` | valid or invalid |
| an id pattern that the parser accepts, and an id, which is any sequence of characters | matches or does not match |

The parser reads a line, a link, and an image under a binding of
`external-namespaces` that it accepts. It must not stop with an error on
any input.

To reject an input is to give it the result "invalid". To accept an
input is to give it the result "valid". The parser must reject an input
when a requirement of this design states that the parser must reject
it, and it must accept each other input whose result is valid or
invalid.

## 5. Conformance

A parser conforms to this design when it meets every requirement of
section 4. So a conforming parser gives a result for every input, and
it never stops with an error.

Each vector below gives an input and the result that a conforming
parser gives for it. These conventions apply:

- In sections 5.1 and 5.2, the parser reads each input under a binding
  of `external-namespaces` with two pairs: `gh` with the id pattern
  `[1-9][0-9]*`, and `rfc` with the id pattern `[1-9][0-9]*`.
- For a valid input, a row names every value that the parser gives,
  with two exceptions: the tag word of a tag line, and an inline
  description that is empty.

### 5.1 Tag lines

| line | result |
|---|---|
| `@req size-limit=v2 A descriptor has at most 1 MiB.` | valid declaration: slug `size-limit`, revision `v2`, inline description `A descriptor has at most 1 MiB.` |
| `   @design identifiers=v1` | valid declaration: slug `identifiers`, revision `v1` |
| `@req`, a tab, and `size-limit=v2` | valid declaration: slug `size-limit`, revision `v2` |
| `see @req size-limit=v2` | not a tag line |
| `@param x The input.` | other tag word: `@param` |
| `@Req size-limit=v2` | other tag word: `@Req` |
| `@ alone` | other tag word: `@` |
| `@req:size-limit=v2` | invalid: no space or tab after `@req` |
| `@deprecated.` | invalid: no space or tab after `@deprecated` |
| `@deprecated` and a carriage return, U+000D | invalid: a carriage return is not a space or a tab |
| `@req` | invalid: no target |
| `@deprecated` | valid status tag |
| `@deferred Waits for a measurement.` | valid status tag: inline description `Waits for a measurement.` |
| `@rejected Replaced by the size limit.` | valid status tag: inline description `Replaced by the size limit.` |
| `@design billing/auth=v2` | valid declaration: slug `billing/auth`, custom namespace `billing`, revision `v2` |
| `@design billing/auth` | invalid: no revision; the `/` joins the two segments of the slug `billing/auth` |
| `@design docs#size=v1` | invalid: the target of `@design` is a slug |
| `@design gh=v1` | invalid: the target is external, and the target of a declaration is never an external id |
| `@spec descriptor=v2` | valid declaration: slug `descriptor`, revision `v2` |
| `@spec packs#descriptor=v3` | valid declaration: slug `packs`, part name `descriptor`, revision `v3` |
| `@spec a/b=v1` | invalid: with no `#`, the target of `@spec` holds a slug of one segment |
| `@req ledger#chunk-size=v1` | valid declaration: slug `ledger`, part name `chunk-size`, revision `v1` |
| `@req size-limit` | invalid: no revision |
| `@req size-limit=*` | invalid: the revision of a declaration is a label |
| `@req req:size-limit=v1` | invalid: the target of a declaration holds no kind word |
| `@decision layered-designs=v1` | valid declaration: slug `layered-designs`, revision `v1` |
| `@finding-class billing/late-fee=v1` | valid declaration: slug `billing/late-fee`, custom namespace `billing`, revision `v1` |
| `@cites -docs=v1` | invalid: `-docs` is not a segment |
| `@cites docs--x=v1` | invalid: `docs--x` is not a segment |
| `@cites my_docs.v2=v1` | valid citation: slug `my_docs.v2`, revision `v1` |
| `@cites docs=*` | valid citation: slug `docs`, revision `*` |
| `@cites docs#size=v2` | valid citation: slug `docs`, part name `size`, revision `v2` |
| `@cites docs#size=*` | valid citation: slug `docs`, part name `size`, revision `*` |
| `@cites #size=v2` | valid citation: part name `size`, revision `v2` |
| `@cites req:#size=v2` | valid citation: kind word `req`, part name `size`, revision `v2` |
| `@cites billing/auth=v3` | valid citation: slug `billing/auth`, custom namespace `billing`, revision `v3` |
| `@cites billing/auth` | invalid: no revision; the `/` joins the two segments of the slug `billing/auth` |
| `@cites docs` | invalid: no revision |
| `@cites docs=` | invalid: no label after `=` |
| `@cites docs=v1.2.0` | valid citation: slug `docs`, revision `v1.2.0` |
| `@cites docs=v1, and more` | valid citation: slug `docs`, revision `v1,`, inline description `and more` |
| `@cites docs=v@1` | invalid: a label holds no `@` |
| `@cites docs=v=1` | invalid: a label holds no `=` |
| `@cites docs=v3#size=v2` | invalid: a target holds one revision at most |
| `@cites docs@3f2a9c=*` | invalid: a slug holds no `@` |
| `@cites docs=v3#size` | invalid: the revision of the part `size` follows `size`, and a label holds no `#` |
| `@cites docs#a/b=v1` | invalid: `a/b` is not a part name |
| `@cites docs#a#b=v1` | invalid: a second `#` |
| `@cites plan:upkeep=*` | invalid: `plan` is not a kind word, and a slug holds no `:` |
| `@cites spec:docs=v2` | valid citation: kind word `spec`, slug `docs`, revision `v2` |
| `@refines docs#size=v2` | valid citation: slug `docs`, part name `size`, revision `v2` |
| `@refines docs=*` | invalid: only `@cites` takes the revision `*` |
| `@satisfies docs#size=*` | invalid: only `@cites` takes the revision `*` |
| `@verifies spec:docs#size=v1` | valid citation: kind word `spec`, slug `docs`, part name `size`, revision `v1` |
| `@supersedes docs=v3#*` | valid citation: slug `docs`, revision `v3`, every part |
| `@supersedes docs#*=v3` | invalid: in an every-part target, the revision follows the slug |
| `@supersedes docs=*#*` | invalid: the revision of an every-part target is a label |
| `@cites docs=v3#*` | invalid: only `@supersedes` takes an every-part target |
| `@supersedes design:docs=v3#*` | invalid: an every-part target holds no kind word |
| `@cites gh/42` | valid citation: external namespace `gh`, id `42` |
| `@verifies gh/42` | valid citation: external namespace `gh`, id `42` |
| `@cites spec:rfc/8259#section-6` | valid citation: kind word `spec`, external namespace `rfc`, id `8259`, part name `section-6` |
| `@cites gh/0` | invalid: the id pattern of `gh` does not match `0` |
| `@cites gh/42=v1` | invalid: the target is external, and an id holds no `=` |
| `@cites gh` | invalid: the target is external, and no `/` and id follow `gh` |
| `@cites gh=v1` | invalid: the head is `gh`, so the target is external, and no `/` and id follow `gh` |
| `@supersedes gh/42#*` | invalid: the target is external, and `*` is not a part name |
| `@cites jira/PROJ-1=*` | valid citation: slug `jira/PROJ-1`, custom namespace `jira`, revision `*` |
| `@extern spec:descriptor` | valid directive: kind word `spec`, part name `descriptor` |
| `@extern spec:descriptor=v1` | invalid: the target of `@extern` carries no revision |
| `@extern descriptor` | invalid: no kind word |
| `@extern spec:packs#descriptor` | invalid: the target of `@extern` holds no slug |
| `@ack retired docs#size=v2 3f2a9c1d` | valid directive: slug `retired`, subject `docs#size=v2`, hash `3f2a9c1d` |
| `@ack unexercised 3f2a9c1d0b7e` | valid directive: slug `unexercised`, empty subject, hash `3f2a9c1d0b7e` |
| `@ack retired a @b 3f2a9c1d` | valid directive: slug `retired`, subject `a @b`, hash `3f2a9c1d` |
| `@ack retired 3f2a9c1d`, then two spaces | valid directive: slug `retired`, empty subject, hash `3f2a9c1d` |
| `@ack retired 3F2A9C1D` | invalid: the hash holds upper-case digits |
| `@ack retired 3f2a9c` | invalid: the hash has fewer than 8 digits |
| `@ack 3f2a9c1d` | invalid: no slug before the hash |

### 5.2 Inline citations

Each row gives a markdown document that holds one link or one image.

| document | result |
|---|---|
| `[the size limit](sinter:req:packs#size-limit=v2)` | valid: link text `the size limit`, kind word `req`, slug `packs`, part name `size-limit`, revision `v2` |
| `[the size limit](sinter:req:packs#size-limit)` | invalid: no revision |
| `[any revision](sinter:packs#size-limit=*)` | valid: link text `any revision`, slug `packs`, part name `size-limit`, revision `*` |
| `[](sinter:packs#size-limit=v2)` | invalid: the link text holds no characters |
| `[the limit](sinter:#size-limit=v2)` | valid: link text `the limit`, part name `size-limit`, revision `v2` |
| `[RFC 8259](sinter:spec:rfc/8259)` | valid: link text `RFC 8259`, kind word `spec`, external namespace `rfc`, id `8259` |
| `[x](sinter:gh/42=v2)` | invalid: the target is external, and an id holds no `=` |
| `[auth](sinter:billing/auth=v3)` | valid: link text `auth`, slug `billing/auth`, custom namespace `billing`, revision `v3` |
| `[auth](sinter:billing/auth)` | invalid: no revision; the `/` joins the two segments of the slug `billing/auth` |
| `[auth][r]`, and the line `[r]: sinter:billing/auth=v3` | valid: link text `auth`, slug `billing/auth`, custom namespace `billing`, revision `v3` |
| `<sinter:req:packs#size-limit=v2>` | valid: link text `sinter:req:packs#size-limit=v2`, kind word `req`, slug `packs`, part name `size-limit`, revision `v2` |
| `[*the* limit](sinter:packs#size-limit=v2)` | valid: link text `*the* limit`, slug `packs`, part name `size-limit`, revision `v2` |
| `[x](sinter:packs\#size-limit=v2)` | valid: link text `x`, slug `packs`, part name `size-limit`, revision `v2` |
| `[x](sinter:packs&#35;size-limit=v2)` | valid: link text `x`, slug `packs`, part name `size-limit`, revision `v2` |
| `[x](sinter:packs%23size-limit=v2)` | invalid: `%23` is three characters, and a segment holds no `%` |
| `[x](sinter:docs=v3#*)` | invalid: only `@supersedes` takes an every-part target |
| `[x](sinter:)` | invalid: no target |
| `[x](sinter:plan:upkeep=v1)` | invalid: `plan` is not a kind word, and a slug holds no `:` |
| `[x](sinter:docs@3f2a9c=v1)` | invalid: a slug holds no `@` |
| `[x](sinter:gh)` | invalid: the target is external, and no `/` and id follow `gh` |
| `[x](Sinter:req:packs#size-limit=v2)` | not an inline citation: the destination does not start with `sinter:` |
| `![x](sinter:packs#size-limit=v2)` | not an inline citation: an image is not a link |

### 5.3 Id patterns

Each item gives an id pattern and its result. For a valid id pattern,
it also gives ids that the id pattern matches and ids that it does not
match.

- `[1-9][0-9]*`: valid; matches `42`; does not match `0` or `042`.
- `[A-Z]+-[1-9][0-9]*`: valid; matches `PROJ-1`; does not match
  `proj-1`.
- `[.]x`: valid; matches `.x`; does not match `ax`.
- `[a-]+`: valid; matches `a-a`.
- `ab|c`: valid; matches `ab` and `c`; does not match `ac`.
- `a{0}b`: valid; matches `b`; does not match `ab`.
- `([0-9]{3}-){10}`: valid; its size is 40.
- the character class `[0123456789]` written 83 times, which is 996
  characters: valid.
- `^[0-9]+$`: invalid: `^` and `$` are not literals.
- `.+`: invalid: `.` is not a literal.
- `[#0-9]+`: invalid: `#` is not a member of a character class.
- `x=[0-9]+`: invalid: `=` is not a literal.
- `[0-9=]+`: invalid: `=` is not a member of a character class.
- `()`: invalid: a group holds a pattern.
- `[a-c-e]`: invalid: the second `-` is not first or last in the
  character class, and it is not the `-` of a range.
- `[z-a]`: invalid: the first character of the range comes after its
  last character.
- `x{3,2}`: invalid: in the quantifier `{n,m}`, `n` is greater than
  `m`.
- `[0-9]{256}`: invalid: a count has a number greater than 255.
- `a{01}`: invalid: a count other than `0` does not start with `0`.
- `a**`: invalid: a second quantifier.
- `a|`: invalid: an empty branch.
- `[0-9]*`: invalid: it matches the empty id.
- `((a{0,255}){0,255})b`: invalid: its size is 65,026.
- the character class `[0123456789]` written 84 times, which is 1,008
  characters: invalid: it holds more than 1,000 characters.

### 5.4 Bindings of `external-namespaces`

| binding | result |
|---|---|
| the empty set | valid |
| `gh` with `[1-9][0-9]*` | valid |
| `my-tracker` with `[A-Z]+-[1-9][0-9]*` | valid |
| `GH` with `[1-9][0-9]*` | invalid: `GH` does not match `namespace-name` |
| `my--tracker` with `[1-9][0-9]*` | invalid: `my--tracker` does not match `namespace-name` |
| `9ns` with `[1-9][0-9]*` | invalid: `9ns` does not match `namespace-name` |
| `gh` with `[1-9][0-9]*`, and `gh` with `[a-z]+` | invalid: two pairs with the name `gh` |
| `gh` with `[0-9]*` | invalid: the id pattern matches the empty id |
