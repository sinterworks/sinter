<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Identifiers
@design identifiers=v1
@cites rfc/5234
@cites rfc/7405
@cites commonmark/0.31.2
A parser reads tag lines, inline citations, id patterns, and bindings of external namespaces, and gives a result and the values for each of them.

A tag line starts, after any spaces and tabs, with a tag word such as
`@req`. A declaration, such as `@req size-limit=v2`, is a tag line that
gives a name and a revision. A citation, such as
`@cites packs#size-limit=v2`, is a tag line that gives the name and the
revision of what it cites. An inline citation is a link of a markdown
document that cites in the same way. An id pattern gives the form of
the ids of an external namespace, such as the issue numbers of a
tracker.

The productions in section 4 are written in ABNF, the notation of
RFC 5234. A production, such as `slug = segment *( "/" segment )`,
gives the texts that its name matches. In a production, `/` separates
two alternatives. The quoted string `"/"` is the character `/`. `( )`
groups elements, and `[ ]` makes an element optional. `*` repeats the
element after it any number of times, `1*` repeats it one or more
times, and `8*64` repeats it from 8 to 64 times. `%x41` is the
character U+0041, and `%x30-39` is any one character from U+0030 to
U+0039. In RFC 5234, a quoted string such as `"a"` matches its letters
in either case. RFC 7405 adds the form `%s"…"`, which matches its
letters only in the same case, as in `%s"@req"`.

From CommonMark 0.31.2, the design takes what a link is, its
destination and its link text, and the inline elements of a link text.

## 1. Terms

| term | meaning |
|---|---|
| conforming parser | a program that meets every requirement of section 4 |
| must | states an obligation of a conforming parser |
| ABNF | the notation for grammars of RFC 5234, with the case-sensitive strings of RFC 7405 |
| production | a rule of ABNF, such as `slug = segment *( "/" segment )`, which gives the texts that its name matches |
| character | one Unicode scalar value: a code point that is not from U+D800 to U+DFFF |
| text | a sequence of characters |
| printable ASCII character | a character from `!` to `~`; a space is not one |
| line | a text with no line feed, which a parser reads as one unit |
| tag line | a line whose first character, after the spaces and tabs at its start, is `@` |
| tag word | the `@` that starts a tag line after its spaces and tabs, with the ASCII letters, ASCII digits, and `-` right after it, such as `@req` |
| Sinter tag word | one of the fifteen tag words of Sinter, such as `@req` and `@cites` |
| declaration | a tag line whose tag word is `@decision`, `@design`, `@finding-class`, `@req`, or `@spec`, such as `@req size-limit=v2` |
| citation | a tag line whose tag word is `@cites`, `@refines`, `@satisfies`, `@supersedes`, or `@verifies`, such as `@cites packs#size-limit=v2` |
| status tag | a tag line with `@deferred`, `@deprecated`, or `@rejected`, which has no target |
| directive | a tag line with `@ack` or `@extern`, each of which has a form of its own |
| target | the run of characters after the tag word of a declaration, a citation, or an `@extern` line and the spaces and tabs after the tag word, up to the next space or tab or the end of the line; also the destination of an inline citation after `sinter:` |
| inline description | the text of a tag line after its target, or after the tag word of a status tag; an `@ack` line has none |
| segment | a run of ASCII letters and ASCII digits, with one `-`, `_`, or `.` at most between two of them, such as `size-limit` |
| slug | one segment, or several segments joined by `/`, such as `packs` or `billing/auth` |
| custom namespace | the text of a slug before its last `/`, such as `billing` in `billing/auth` and `a/b` in `a/b/c` |
| part name | the segment after `#` in a name, such as `descriptor` in `packs#descriptor` |
| full name | a slug, `#`, and a part name, such as `packs#descriptor` |
| name | a slug, a full name, or `#` and a part name |
| kind word | one of six words, such as `req`, that can stand with a `:` at the start of a target, as in `req:packs#size-limit=v2` |
| label | a run of printable ASCII characters other than `/`, `#`, `@`, `*`, and `=`, such as `v2` |
| revision | a label, or `*`, which stands for any label; in a target it follows a name and `=`, as `v2` in `docs#size=v2` and `v3` in `docs=v3#*` |
| every-part target | a slug, `=`, a label, and `#*`, such as `docs=v3#*` |
| external namespace | one pair of the binding of `external-namespaces`: a namespace name and an id pattern |
| namespace name | the name of an external namespace, such as `gh` |
| external id | a namespace name, `/`, and an id, such as `gh/42` |
| id | a text that a parser tests against an id pattern, such as `42` in `gh/42` |
| id pattern | a small regular expression, which gives the form of the ids of one external namespace |
| fit | an id fits an id pattern when the id has the form that the id pattern gives, such as `42` for `[1-9][0-9]*` |
| head | the text of a target without its kind word and the `:` after it, up to its first `#` or `=` |
| external target | the target of a declaration, a citation, or an inline citation whose head starts with a namespace name, followed by `/` or by the end of the head |
| link | an inline link, a reference link, or an autolink of a markdown document, as CommonMark 0.31.2 defines them; an image is not a link |
| inline citation | a link whose destination starts with `sinter:` |
| destination | the address of a link, such as `sinter:packs#size-limit=v2` in `[the limit](sinter:packs#size-limit=v2)` |
| link text | the text between the brackets of a link, such as `the limit` in `[the limit](sinter:packs#size-limit=v2)` |
| plain string content | the text that a link text shows without its markup, such as `the limit` for `*the* limit` |
| white space character | a space, a tab, a line feed, a form feed, a carriage return, or another space character of Unicode, such as U+00A0, the no-break space |
| parameter | an input of a parser that holds for every line, link, and image that the parser reads |
| binding | the input that a program gives for a parameter, such as a set of pairs for `external-namespaces` |
| result | what a conforming parser gives for an input, such as "valid", "not a tag line", or "fits" |
| valid, invalid | the results of a conforming parser for an input that it accepts and for an input that it rejects |
| value | a text or a fact that a conforming parser gives for an input together with its result, such as the tag word of a tag line or the slug of a target |

## 2. The written forms

### 2.1 Tag lines and tag words

A parser reads lines. A line is a text with no line feed. A line is a
tag line when its first character, after the spaces and tabs at its
start, is `@`. Every such line is a tag line, whatever its tag word is.

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
not `@req`. For a tag line whose tag word is not a Sinter tag word, a
conforming parser gives the result "other tag word" and the tag word,
and nothing more.

A Sinter tag word makes its tag line a declaration, a citation, a
status tag, or a directive. The tag word also sets the form of the line
and of its target:

| tag word | tag line | target | revision |
|---|---|---|---|
| `@decision`, `@design`, `@finding-class` | declaration | a slug | a label |
| `@req` | declaration | a slug or a full name | a label |
| `@spec` | declaration | a slug of one segment, or a full name | a label |
| `@cites` | citation | an optional kind word and `:`, then a name, or an external id with an optional `#` and part name | a label or `*`; none after an external id |
| `@refines`, `@satisfies`, `@verifies` | citation | an optional kind word and `:`, then a name, or an external id with an optional `#` and part name | a label; none after an external id |
| `@supersedes` | citation | an optional kind word and `:`, then a name, or an external id with an optional `#` and part name; or an every-part target | a label; none after an external id |
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
`/`, such as `billing/auth`. The text of a slug before its last `/` is
the custom namespace of the slug: `billing` in `billing/auth`, and
`a/b` in `a/b/c`.

A part name is one segment. A full name is a slug, `#`, and a part
name, such as `packs#descriptor` or `billing/auth#lockout`. A target
can also hold `#` and a part name with no slug before the `#`, as in
`#descriptor=v1`. A name is a slug, a full name, or `#` and a part
name.

A conforming parser gives each name with its case unchanged, so
`Auth-Lockout` and `auth-lockout` stay two different texts.

### 2.3 Kind words

The six kind words are `decision`, `design`, `finding-class`, `req`,
`spec`, and `term`. A kind word stands at the start of a target, with a
`:` after it: `req:packs#size-limit=v2`, `spec:rfc/8259`.

The target of a citation and the target of an inline citation can start
with a kind word. The target of `@extern` always starts with one. The
target of a declaration holds no kind word, and an every-part target
holds none. A name holds no `:`. So the target `plan:upkeep=*` is
invalid: `plan` is not a kind word, and `plan:upkeep` is not a slug.

### 2.4 Revisions

A revision is a label or `*`. A label is a run of printable ASCII
characters other than `/`, `#`, `@`, `*`, and `=`, such as `v2`,
`2026-11`, `v1.2.0`, or `rc1`. `*` stands for any label.

A revision follows a name, after `=`. A target carries one revision at
most.

| target | name | revision |
|---|---|---|
| `docs=v3` | the slug `docs` | `v3` |
| `billing/auth=v3` | the slug `billing/auth` | `v3` |
| `docs#size=v2` | the full name `docs#size` | `v2` |
| `#size=v2` | `#` and the part name `size` | `v2` |
| `docs=*` | the slug `docs` | `*` |
| `docs#size=*` | the full name `docs#size` | `*` |

The target of every declaration, citation, and inline citation carries
a revision, except an external target. The target of a declaration
carries a label. The target of `@cites` and the target of an inline
citation carry a label or `*`. The target of a citation whose tag word
is `@refines`, `@satisfies`, `@supersedes`, or `@verifies` carries a
label. The target of `@extern` and an `@ack` line carry no revision.

A revision has no default. So a declaration, a citation, or an inline
citation whose target is not external and carries no revision is
invalid. For example, `@cites billing/auth` and `@design billing/auth`
are invalid: neither target carries a revision.

The target ends at the first space or tab, so in
`@cites docs=v1, and more` the label is `v1,`. A label holds no `=`, so
`@cites docs=v=1` is invalid.

An every-part target is a slug, `=`, a label, and `#*`, such as
`docs=v3#*`. Only the target of `@supersedes` can be an every-part
target. The revision of an every-part target follows the slug, and it
is a label. So `@supersedes docs#*=v3` and `@supersedes docs=*#*` are
invalid. An every-part target holds no kind word, so
`@supersedes design:docs=v3#*` is invalid.

### 2.5 External ids

The parameter `external-namespaces` (section 3) gives the external
namespaces. Each external namespace has a namespace name, such as `gh`,
and an id pattern. An external id is a namespace name, `/`, and an id,
such as `gh/42`. The id is a run of printable ASCII characters other
than `#`, `/`, `=`, and `@`, and it fits the id pattern of the external
namespace. An external id can take `#` and a part name, as in
`rfc/8259#section-6`. An external id carries no revision.

One rule decides whether the target of a declaration, a citation, or an
inline citation holds an external id. The head of the target is its
text after its kind word and the `:` after the kind word, and before
its first `#` or `=`. When the head starts with a namespace name,
followed by `/` or by the end of the head, the target is an external
target. A conforming parser reads an external target only as an
external id, with an optional `#` and part name after it. It reads no
other target as an external id. The target of `@extern` is never an
external target, so `@extern spec:gh` is valid under a binding with
the external namespace `gh`.

So the binding of `external-namespaces` decides how a target reads.
When `gh` is a namespace name of the binding, `@cites gh/42` cites the
external id `gh/42`. When it is not, the target `gh/42` is the slug
`gh/42`: `@cites gh/42` is invalid, because it carries no revision, and
`@cites gh/42=v1` is valid. Under a binding with the external namespace
`gh`:

- `@cites gh/0` is invalid when `0` does not fit the id pattern of
  `gh`.
- `@cites gh/42=v1` is invalid, because the target is external, and an
  id holds no `=`.
- `@cites gh/42/x` is invalid, because the target is external, and an
  id holds no `/`.
- `@cites gh` is invalid, because no `/` and id follow `gh`.
- `@cites gh=v1` is invalid: its head is `gh`, so the target is
  external, and no `/` and id follow `gh`.
- `@design gh=v1` is invalid, because the target is external, and the
  target of a declaration is never an external id.
- `@supersedes gh/42#*` is invalid, because the target is external and
  `*` is not a part name.

### 2.6 The directives `@extern` and `@ack`

The target of `@extern` is a kind word, `:`, and a part name, such as
`spec:descriptor`. It holds no `#`, so no slug comes before the part
name. It holds no revision.

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

An inline citation is a link whose destination starts with the seven
characters `sinter:`. A link is an inline link, a reference link, or an
autolink of a markdown document, as CommonMark 0.31.2 defines them. An
image is not a link, so `![x](sinter:packs#size-limit=v2)` is not an
inline citation.

The destination of an inline link or a reference link is its link
destination as CommonMark gives it. The destination holds no angle
brackets that enclose it, and each backslash escape, entity reference,
and numeric character reference in it is replaced by its character. No
percent-encoding and no percent-decoding applies to a destination, so
`%23` is three characters and not `#`. So
`[x](sinter:packs\#size-limit=v2)` and
`[x](sinter:packs&#35;size-limit=v2)` both have the destination
`sinter:packs#size-limit=v2`, and `[x](sinter:packs%23size-limit=v2)`
is invalid. The destination of an autolink is its text between `<` and
`>`.

The target of an inline citation is its destination after `sinter:`.
The target is an optional kind word and `:`, and then either a name,
`=`, and a revision, or an external id with an optional `#` and part
name. As in the target of `@cites`, the revision is a label or `*`, and
an external id carries no revision. So `[auth](sinter:billing/auth=v3)`
cites the slug `billing/auth` with the revision `v3`, and
`[auth](sinter:billing/auth)` is invalid. The rule of external targets
(section 2.5) applies as it applies in a tag line. So under a binding
with the external namespace `gh`, `[x](sinter:gh/42=v2)` is invalid.

The link text of an inline link or a reference link is the text between
its brackets, as it stands in the raw content of the paragraph or the
heading that holds the link. CommonMark gives this raw content without
the markers of block quotes and list items, and without the spaces and
tabs at the start of each line. So in a block quote, the lines `> [the`
and `> limit](sinter:packs#size-limit=v2)` give the link text `the`, a
line feed, and `limit`. The link text keeps its markup, such as
`*the* limit` in `[*the* limit](sinter:packs#size-limit=v2)`. The link
text of an autolink, such as `<sinter:req:packs#size-limit=v2>`, is its
text between `<` and `>`.

An inline citation is invalid when the plain string content of its
link text holds no character other than white space characters. The
plain string content is the text that the inline elements of the link
text give without their markup, in their order and joined together:

- Textual content gives its characters, after its escapes and
  references resolve, so `&nbsp;` gives U+00A0.
- A code span gives its content.
- Emphasis and strong emphasis give the plain string content of what
  they hold, so `*the* limit` gives `the limit`.
- An image gives the plain string content of its description.
- An autolink gives its text between `<` and `>`.
- A line break gives a line feed.
- Raw HTML, such as `<!-- -->`, gives no characters.

So `[](sinter:packs#size-limit=v2)`, `[ ](sinter:packs#size-limit=v2)`,
`[&nbsp;](sinter:packs#size-limit=v2)`, and
`[<!-- -->](sinter:packs#size-limit=v2)` are invalid. But
`[**](sinter:packs#size-limit=v2)` is valid, because `**` that opens no
emphasis is text. `[<https://example.com>](sinter:packs#size-limit=v2)`
is valid too. The outer link is a link, because the CommonMark
algorithm for links and images builds it around the autolink. The
autolink stays a link of its own inside the link text, and it gives
`https://example.com` to the plain string content. The plain string content of
the link text of an autolink is that link text.

### 2.8 Id patterns

An id pattern is a small regular expression. An id fits an id pattern
when the whole id, and not only a part of it, has the form that the id
pattern gives. An id pattern is built from these elements:

| element | form | texts that fit it |
|---|---|---|
| literal | one printable ASCII character other than `\ . [ ] ( ) { } * + ? \| ^ $ # / = @` | that character |
| character class | `[`, members, `]`, with a `-` that can also stand right after the `[` or right before the `]`; it holds one member or such a `-` at least | one character that fits a member; also `-` when the class holds a `-` right after its `[` or right before its `]` |
| member | a printable ASCII character other than `\ [ ] ^ - # / = @` | that character |
| member | a range `x-y`: two digits, two upper-case letters, or two lower-case letters, with `x` not after `y` | each character from `x` to `y` |
| group | `(`, an id pattern, `)` | the texts that fit that id pattern |
| sequence | elements one after another | texts that fit each element, one after another |
| alternation | `a\|b` | the texts that fit `a`, and the texts that fit `b` |
| quantifier | `?`, `*`, `+`, `{n}`, `{n,}`, or `{n,m}` after a literal, a character class, or a group | texts that fit the element, 0 or 1 times; 0 or more times; 1 or more times; `n` times; `n` or more times; from `n` to `m` times |

Alternation binds loosest, so the ids `ab` and `c` fit `ab|c`. A
quantifier applies to the one literal, character class, or group
before it. An element takes one quantifier at most. In a quantifier,
`n` and `m` are decimal numbers from 0 to 255, written with no leading
zero, and `n` is not greater than `m`. Case always matters.
A character class can hold characters that a literal leaves out, such
as `.` and `+`: `[.]`, `[+]`.

These conditions also apply to an id pattern:

- The empty id does not fit it. So `[0-9]*` is invalid.
- It holds 1,000 characters at most.
- Its size is 1,000 at most. The size counts the literals and the
  character classes of the pattern when each quantifier is written out
  as copies of its element. `{n}` counts as `n` copies, `{n,m}` counts
  as `m` copies, and each of them counts as one copy at least. `{n,}`
  counts as `n` copies and one more. `?`, `*`, and `+` count as one
  copy. Examples: `([0-9]{3}-){10}` has the size 40,
  `([0-9]{250}){4}` has the size 1,000, and `([0-9]{143}){7}` has the
  size 1,001, so it is invalid.

| id pattern | ids that fit it |
|---|---|
| `[1-9][0-9]*` | the numbers of GitHub issues and pull requests, such as `42` |
| `[A-Z]+-[1-9][0-9]*` | Jira keys whose project key holds only letters, such as `PROJ-1` |

A valid id pattern is also a POSIX extended regular expression in the
POSIX locale, an RE2 expression, and an ECMAScript expression without
the `v` flag. Each of these, anchored at the start and the end of the
id, finds exactly the ids that fit the id pattern.

### 2.9 Results and values

A conforming parser gives one result for each id pattern, for each
binding of `external-namespaces`, and for each id pattern that it
accepts together with an id. The id patterns of a binding get no
results of their own: the binding gets one result. Under a binding that
the parser accepts, it also gives one result for each line, link, and
image. Under a binding that it rejects, it gives no result and no value
for a line, a link, or an image.

A line gets one of four results: not a tag line, other tag word, valid,
or invalid. A link or an image gets one of three results: not an inline
citation, valid, or invalid. An id pattern and a binding of
`external-namespaces` each get valid or invalid. An id pattern that the
parser accepts, together with an id, gets fits or does not fit.

For a tag line, the parser gives the tag word. For a valid input, it
also gives the values that the input holds, such as the kind word, the
slug, the custom namespace, the part name, the namespace name and the
id, the revision, the inline description, the subject and the hash,
and the link text. For each other input, it gives no value other than
the tag word of a tag line. Each value of a tag line is a run of the
characters of the line. Each value of a target of an inline citation is
a run of the characters of the destination, after the escapes and
references of the destination resolve. The link text is a run of the
characters of the raw content of a paragraph or a heading, or of the
destination of an autolink.

## 3. Parameters

### 3.1 `external-namespaces`

The parameter `external-namespaces` gives the external namespaces. Its
binding is a finite set of pairs. Each pair is one external namespace:
a namespace name and an id pattern. The binding can be the empty set,
and then no target is external.

A namespace name is a run of lower-case ASCII letters and ASCII digits
that starts with a letter, with one `-` at most between two of them,
such as `gh` or `my-tracker`. No two pairs of a valid binding have the
same namespace name. Each id pattern of a valid binding is valid.

## 4. Requirements

### 4.1 Characters and texts

@req characters=v1

A character is a Unicode scalar value: a code point from U+0000 to
U+D7FF, or from U+E000 to U+10FFFF. A text is a sequence of characters.
The empty text is the text of no characters. A space is U+0020, a tab
is U+0009, and a line feed is U+000A. One character comes before
another in code point order, and the other comes after it, when the
code point of the one is less than the code point of the other.

### 4.2 Notation

@req notation=v1
@cites rfc/5234
@cites rfc/7405
@cites #characters=v1

The productions of this design are rules of ABNF, the notation of
RFC 5234, with the case-sensitive strings of RFC 7405. They use the core
rules of RFC 5234, Appendix B.1. Each terminal value of a production is
the code point of one character, so `%x41` matches the character
U+0041. A text matches a production when the production matches the
whole of the text.

The production `any-char` matches each character:

```
any-char  = %x0-D7FF / %xE000-10FFFF
```

### 4.3 Results and values

@req result-list=v1
@cites #characters=v1

The results are these seven: "not a tag line", "other tag word", "not
an inline citation", "valid", "invalid", "fits", and "does not fit". To
reject an input is to give it the result "invalid". To accept an input
is to give it the result "valid". A value is a text or a fact that a
conforming parser gives for an input together with its result.

### 4.4 Tag lines

@req tag-lines=v1
@cites #characters=v1
@cites #notation=v1

A line is a text that holds no line feed. A tag line is a line whose
first character after the spaces and tabs at its start is `@`. The tag
word of a tag line is the longest text that starts at that `@` and that
matches `tag-word`:

```
tag-word  = "@" *( ALPHA / DIGIT / "-" )
```

### 4.5 Tag words

@req tag-words=v1
@cites #characters=v1
@cites #tag-lines=v1

The Sinter tag words are these fifteen tag words, in four sets:

- the declaration words: `@decision`, `@design`, `@finding-class`,
  `@req`, and `@spec`;
- the citation words: `@cites`, `@refines`, `@satisfies`,
  `@supersedes`, and `@verifies`;
- the status words: `@deferred`, `@deprecated`, and `@rejected`;
- the directive words: `@ack` and `@extern`.

A tag word is a Sinter tag word when, and only when, it has the
characters of one of these fifteen words, in the same order. A
declaration is a tag line whose tag word is a declaration word. A
citation is a tag line whose tag word is a citation word. A status tag
is a tag line whose tag word is a status word. A directive is a tag
line whose tag word is a directive word. An `@ack` line is a tag line
whose tag word is `@ack`, and an `@extern` line is a tag line whose tag
word is `@extern`.

### 4.6 Spaces, targets, and inline descriptions

@req line-layout=v1
@cites #characters=v1
@cites #notation=v1
@cites #tag-lines=v1
@cites #tag-words=v1

These productions give the spaces and tabs of a tag line:

```
indent  = *WSP
gap     = 1*WSP
rest    = [ gap *any-char ]
```

The target of a declaration, a citation, or an `@extern` line is the
text that starts after the spaces and tabs that follow its tag word,
and that ends before the next space or tab, or at the end of the line.
The inline description of a declaration, a citation, or an `@extern`
line is the text of the line after its target, without the spaces and
tabs at its start. The inline description of a status tag is the text
of the line after its tag word, without the spaces and tabs at its
start. An inline description can be empty.

### 4.7 Segments and names

@req segments=v1
@cites #characters=v1
@cites #notation=v1

These productions give the forms of names:

```
alnum      = ALPHA / DIGIT
segment    = 1*alnum *( ( "-" / "_" / "." ) 1*alnum )
slug       = segment *( "/" segment )
part-name  = segment
full-name  = slug "#" part-name
name       = slug / full-name / "#" part-name
```

The custom namespace of a slug that holds a `/` is the text of the slug
before its last `/`.

### 4.8 Kind words

@req kind-words=v1
@cites #characters=v1
@cites #notation=v1

The kind words are the texts that this production matches:

```
kind-word  = %s"decision" / %s"design" / %s"finding-class" / %s"req"
           / %s"spec" / %s"term"
```

### 4.9 Revisions

@req revisions=v1
@cites #notation=v1

These productions give the forms of a label and of a revision:

```
label     = 1*( %x21-22 / %x24-29 / %x2B-2E / %x30-3C / %x3E-3F
              / %x41-7E )
revision  = label / "*"
```

### 4.10 The grammar of id patterns

@req id-pattern-grammar=v1
@cites #characters=v1
@cites #notation=v1

An id pattern is a text that a conforming parser reads as a pattern for
ids. An id is a text that a conforming parser tests against an id
pattern. These productions give the form of an id pattern:

```
pattern     = branch *( "|" branch )
branch      = 1*piece
piece       = atom [ quantifier ]
atom        = literal / char-class / "(" pattern ")"
literal     = %x21-22 / %x25-27 / %x2C-2D / %x30-3C / %x3E / %x41-5A
            / %x5F-7A / %x7E
char-class  = "[" ( edge-dash *member / 1*member ) [ edge-dash ] "]"
edge-dash   = "-"
member      = range / single
range       = %x30-39 "-" %x30-39 / %x41-5A "-" %x41-5A
            / %x61-7A "-" %x61-7A
single      = %x21-22 / %x24-2C / %x2E / %x30-3C / %x3E-3F / %x41-5A
            / %x5F-7E
quantifier  = "?" / "*" / "+" / "{" count "}" / "{" count ",}"
            / "{" count "," count "}"
count       = "0" / %x31-39 *DIGIT
```

The number of a `count` is the decimal number that its digits write.
The quantifiers `{n}`, `{n,}`, and `{n,m}` are the forms
`"{" count "}"`, `"{" count ",}"`, and `"{" count "," count "}"`, where
`n` is the number of the first `count`, and `m` is the number of the
second `count`.

### 4.11 The form of an id pattern

@req id-pattern-syntax=v1
@cites #notation=v1
@cites #result-list=v1
@cites #id-pattern-grammar=v1

A conforming parser must reject an id pattern that does not match the
production `pattern`.

### 4.12 Ranges in id patterns

@req id-pattern-ranges=v1
@cites #characters=v1
@cites #notation=v1
@cites #result-list=v1
@cites #id-pattern-grammar=v1

A conforming parser must reject an id pattern that holds a `range`
whose first character comes after its last character in code point
order.

### 4.13 Counts in id patterns

@req id-pattern-counts=v1
@cites #notation=v1
@cites #result-list=v1
@cites #id-pattern-grammar=v1

A conforming parser must reject an id pattern that holds a `count`
whose number is greater than 255.

### 4.14 Bounds in id patterns

@req id-pattern-bounds=v1
@cites #notation=v1
@cites #result-list=v1
@cites #id-pattern-grammar=v1

A conforming parser must reject an id pattern that holds a quantifier
`{n,m}` in which `n` is greater than `m`.

### 4.15 The meaning of id patterns

@req id-pattern-meaning=v1
@cites #characters=v1
@cites #notation=v1
@cites #id-pattern-grammar=v1

An id fits an id pattern that matches `pattern` when the whole id fits
that `pattern`. These rules state when a run of characters of the id,
which can be the whole id or the empty run, fits a part of the id
pattern:

- A run fits a `literal` when it is the one character of the
  `literal`.
- A run fits a `char-class` when it fits one of the `member` elements
  or one of the `edge-dash` elements of the `char-class`.
- A run fits a `range` when it is one character that comes neither
  before the first character of the `range` nor after its last
  character in code point order. A run fits a `single` when it is the
  one character of the `single`. A run fits an `edge-dash` when it is
  the character `-`.
- A run fits an `atom` of the form `"(" pattern ")"` when it fits the
  inner `pattern`.
- A run fits a `piece` with no `quantifier` when it fits the `atom` of
  the `piece`. A run fits a `piece` with a `quantifier` when it is a
  sequence of runs that each fit the `atom`, one after another, and the
  number of runs is 0 or 1 for `?`, 0 or more for `*`, 1 or more for
  `+`, exactly `n` for `{n}`, `n` or more for `{n,}`, and from `n` to
  `m` for `{n,m}`. The runs of the sequence can differ.
- A run fits a `branch` when it is a sequence of runs, one for each
  `piece` of the `branch` in their order, and each run fits its
  `piece`.
- A run fits a `pattern` when it fits one of the branches of the
  `pattern`.

### 4.16 Testing ids

@req id-pattern-fit=v1
@cites #result-list=v1
@cites #id-pattern-grammar=v1
@cites #id-pattern-meaning=v1

For an id pattern that it accepts and an id, a conforming parser must
give the result "fits" when the id fits the id pattern, and the result
"does not fit" when it does not.

### 4.17 The empty id

@req id-pattern-empty=v1
@cites #characters=v1
@cites #result-list=v1
@cites #id-pattern-grammar=v1
@cites #id-pattern-meaning=v1

A conforming parser must reject an id pattern when the empty text, as
an id, fits it.

### 4.18 The size of an id pattern

@req id-pattern-size=v1
@cites #characters=v1
@cites #notation=v1
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

### 4.19 The limit on the size of an id pattern

@req id-pattern-size-limit=v1
@cites #result-list=v1
@cites #id-pattern-grammar=v1
@cites #id-pattern-size=v1

A conforming parser must reject an id pattern whose size is greater
than 1,000.

### 4.20 The length of an id pattern

@req id-pattern-length=v1
@cites #characters=v1
@cites #result-list=v1
@cites #id-pattern-grammar=v1

A conforming parser must reject an id pattern that holds more than
1,000 characters.

### 4.21 External namespaces

@req external-namespaces=v1
@cites #characters=v1
@cites #notation=v1
@cites #id-pattern-grammar=v1

`external-namespaces` is an input of a conforming parser. A binding of
`external-namespaces` is a finite set of pairs. Each pair holds a
namespace name, which is a text, and an id pattern. The external
namespaces are the pairs of the binding. This production gives the form
of a namespace name:

```
namespace-name  = %x61-7A *( %x61-7A / DIGIT )
                  *( "-" 1*( %x61-7A / DIGIT ) )
```

### 4.22 The form of namespace names

@req namespace-name-form=v1
@cites #notation=v1
@cites #result-list=v1
@cites #external-namespaces=v1

A conforming parser must reject a binding of `external-namespaces` that
holds a namespace name that does not match `namespace-name`.

### 4.23 Unique namespace names

@req namespace-name-unique=v1
@cites #result-list=v1
@cites #external-namespaces=v1

A conforming parser must reject a binding of `external-namespaces` in
which two pairs have the same namespace name.

### 4.24 The id patterns of a binding

@req namespace-patterns=v1
@cites #result-list=v1
@cites #external-namespaces=v1
@cites #id-pattern-grammar=v1
@cites #id-pattern-syntax=v1
@cites #id-pattern-ranges=v1
@cites #id-pattern-counts=v1
@cites #id-pattern-bounds=v1
@cites #id-pattern-empty=v1
@cites #id-pattern-size-limit=v1
@cites #id-pattern-length=v1

A conforming parser must reject a binding of `external-namespaces` that
holds an id pattern that one of these requirements states that the
parser must reject: `id-pattern-syntax`, `id-pattern-ranges`,
`id-pattern-counts`, `id-pattern-bounds`, `id-pattern-empty`,
`id-pattern-size-limit`, and `id-pattern-length`.

### 4.25 A rejected binding

@req rejected-binding=v1
@cites commonmark/0.31.2
@cites #result-list=v1
@cites #tag-lines=v1
@cites #external-namespaces=v1
@cites #inline-citations=v1

Under a binding of `external-namespaces` that it rejects, a conforming
parser must give no result and no value for a line, a link, or an
image.

### 4.26 Inline citations

@req inline-citations=v1
@cites commonmark/0.31.2
@cites #characters=v1

A link is an inline link, a full, collapsed, or shortcut reference
link, or an autolink of a markdown document, each as CommonMark 0.31.2
defines it. An image is not a link. An inline link or a reference link
whose link text holds an autolink is a link, as the CommonMark 0.31.2
algorithm for links and images builds it.

The destination of an inline link or a reference link is its link
destination as CommonMark 0.31.2 gives it: without the angle brackets
that enclose it, with each backslash escape resolved, and with each
entity reference and numeric character reference replaced by its
character. No percent-encoding and no percent-decoding applies to a
destination, so a `%` is a character of the destination. The
destination of an autolink is its text between `<` and `>`.

An inline citation is a link whose destination starts with the seven
characters `sinter:`. The target of an inline citation is the text of
its destination after `sinter:`. The link text of an inline link or a
reference link is the text between the `[` and the `]` that delimit its
link text, in the raw content of the paragraph or the heading that
holds the link, as CommonMark 0.31.2 gives that raw content. The link
text of an autolink is its text between `<` and `>`.

### 4.27 White space characters

@req white-space=v1
@cites #characters=v1

A white space character is one of these characters: U+0009, U+000A,
U+000C, U+000D, U+0020, U+00A0, U+1680, each character from U+2000 to
U+200A, U+202F, U+205F, and U+3000.

### 4.28 Plain string content

@req plain-string-content=v1
@cites commonmark/0.31.2
@cites #characters=v1
@cites #inline-citations=v1

The plain string content of a sequence of inline elements, as
CommonMark 0.31.2 parses them, is a text. It joins, in the order of the
elements, the texts that these rules give for the elements:

- Textual content gives its characters, with each backslash escape,
  entity reference, and numeric character reference replaced by its
  character.
- A code span gives its content.
- Emphasis and strong emphasis give the plain string content of their
  inline elements.
- An inline link and a reference link give the plain string content of
  the inline elements of their link text.
- An autolink gives its text between `<` and `>`.
- An image gives the plain string content of the inline elements of its
  image description.
- A soft line break and a hard line break each give a line feed.
- Raw HTML gives the empty text.

The plain string content of the link text of an inline link or a
reference link is the plain string content of the inline elements of
that link text. The plain string content of the link text of an
autolink is that link text.

### 4.29 External ids

@req external-ids=v1
@cites #characters=v1
@cites #notation=v1
@cites #segments=v1
@cites #id-pattern-grammar=v1
@cites #id-pattern-meaning=v1
@cites #external-namespaces=v1

These productions give the form of an external id:

```
external-ref  = external-id [ "#" part-name ]
external-id   = namespace-name "/" id-text
id-text       = 1*( %x21-22 / %x24-2E / %x30-3C / %x3E-3F / %x41-7E )
```

In `external-id`, a text matches `namespace-name` only when it is the
namespace name of an external namespace. A text matches `external-id`
only when the text that its `id-text` matches, as an id, fits the id
pattern of the external namespace whose namespace name its
`namespace-name` matches.

### 4.30 External targets

@req external-targets=v1
@cites #characters=v1
@cites #notation=v1
@cites #tag-lines=v1
@cites #tag-words=v1
@cites #line-layout=v1
@cites #kind-words=v1
@cites #external-namespaces=v1
@cites #inline-citations=v1
@cites #external-ids=v1

A target starts with a kind word when it holds a `:` and the text
before its first `:` matches `kind-word`. The head of a target is the
text of the target after that kind word and that `:`, when the target
starts with a kind word, and before the first character of the target
that is `#` or `=`, when the target holds one. The target of a
declaration, a citation, or an inline citation is external when the
text of its head before the first `/` of the head, or the whole head
when the head holds no `/`, is the namespace name of an external
namespace. When the target of a declaration or a citation is external,
a production matches the line only by a match in which `external-ref`
matches the target, without its kind word and the `:` after it when the
target starts with a kind word. When the target of an inline citation
is external, a production matches the destination only by such a
match.

### 4.31 The grammar of declarations

@req declaration-grammar=v1
@cites #notation=v1
@cites #tag-words=v1
@cites #line-layout=v1
@cites #segments=v1
@cites #revisions=v1
@cites #external-targets=v1

This production gives the form of a declaration:

```
declaration-line  = indent ( %s"@decision" / %s"@design"
                           / %s"@finding-class" )
                    gap slug "=" label rest
                  / indent %s"@spec" gap ( segment / full-name )
                    "=" label rest
                  / indent %s"@req" gap ( slug / full-name )
                    "=" label rest
```

### 4.32 Declarations

@req declarations=v1
@cites #notation=v1
@cites #result-list=v1
@cites #tag-words=v1
@cites #external-namespaces=v1
@cites #declaration-grammar=v1

Under a binding of `external-namespaces` that it accepts, a conforming
parser must reject a declaration that does not match
`declaration-line`.

### 4.33 The grammar of citations

@req citation-grammar=v1
@cites #notation=v1
@cites #tag-words=v1
@cites #line-layout=v1
@cites #segments=v1
@cites #kind-words=v1
@cites #revisions=v1
@cites #external-ids=v1
@cites #external-targets=v1

These productions give the form of a citation:

```
citation-line  = indent %s"@cites" gap [ kind-word ":" ]
                 ( name "=" revision / external-ref ) rest
               / indent ( %s"@refines" / %s"@satisfies"
                        / %s"@supersedes" / %s"@verifies" )
                 gap [ kind-word ":" ] ( name "=" label / external-ref )
                 rest
               / indent %s"@supersedes" gap every-part rest
every-part     = slug "=" label "#*"
```

An every-part target is a target that matches `every-part`.

### 4.34 Citations

@req citations=v1
@cites #notation=v1
@cites #result-list=v1
@cites #tag-words=v1
@cites #external-namespaces=v1
@cites #citation-grammar=v1

Under a binding of `external-namespaces` that it accepts, a conforming
parser must reject a citation that does not match `citation-line`.

### 4.35 The grammar of status tags

@req status-grammar=v1
@cites #notation=v1
@cites #tag-words=v1
@cites #line-layout=v1

This production gives the form of a status tag:

```
status-line  = indent ( %s"@deferred" / %s"@deprecated" / %s"@rejected" )
               rest
```

### 4.36 Status tags

@req status-tags=v1
@cites #notation=v1
@cites #result-list=v1
@cites #tag-words=v1
@cites #external-namespaces=v1
@cites #status-grammar=v1

Under a binding of `external-namespaces` that it accepts, a conforming
parser must reject a status tag that does not match `status-line`.

### 4.37 The grammar of `@extern`

@req extern-grammar=v1
@cites #notation=v1
@cites #tag-words=v1
@cites #line-layout=v1
@cites #segments=v1
@cites #kind-words=v1

This production gives the form of an `@extern` line:

```
extern-line  = indent %s"@extern" gap kind-word ":" part-name rest
```

### 4.38 The directive `@extern`

@req extern=v1
@cites #notation=v1
@cites #result-list=v1
@cites #tag-words=v1
@cites #external-namespaces=v1
@cites #extern-grammar=v1

Under a binding of `external-namespaces` that it accepts, a conforming
parser must reject an `@extern` line that does not match `extern-line`.

### 4.39 The grammar of `@ack`

@req ack-grammar=v1
@cites #characters=v1
@cites #notation=v1
@cites #tag-words=v1
@cites #line-layout=v1
@cites #segments=v1

These productions give the form of an `@ack` line:

```
ack-line  = indent %s"@ack" gap slug [ gap subject ] gap hash *WSP
subject   = non-wsp [ *any-char non-wsp ]
non-wsp   = %x0-8 / %xA-1F / %x21-D7FF / %xE000-10FFFF
hash      = 8*64( %x30-39 / %x61-66 )
```

### 4.40 The directive `@ack`

@req ack=v1
@cites #notation=v1
@cites #result-list=v1
@cites #tag-words=v1
@cites #external-namespaces=v1
@cites #ack-grammar=v1

Under a binding of `external-namespaces` that it accepts, a conforming
parser must reject an `@ack` line that does not match `ack-line`.

### 4.41 The grammar of inline citations

@req inline-grammar=v1
@cites #notation=v1
@cites #segments=v1
@cites #kind-words=v1
@cites #revisions=v1
@cites #inline-citations=v1
@cites #external-ids=v1
@cites #external-targets=v1

This production gives the form of the destination of an inline
citation:

```
inline-destination  = %s"sinter:" [ kind-word ":" ]
                      ( name "=" revision / external-ref )
```

### 4.42 The targets of inline citations

@req inline-targets=v1
@cites #notation=v1
@cites #result-list=v1
@cites #external-namespaces=v1
@cites #inline-citations=v1
@cites #inline-grammar=v1

Under a binding of `external-namespaces` that it accepts, a conforming
parser must reject an inline citation whose destination does not match
`inline-destination`.

### 4.43 The link text of inline citations

@req inline-link-text=v1
@cites #characters=v1
@cites #result-list=v1
@cites #external-namespaces=v1
@cites #inline-citations=v1
@cites #white-space=v1
@cites #plain-string-content=v1

Under a binding of `external-namespaces` that it accepts, a conforming
parser must reject an inline citation when the plain string content of
its link text holds no character other than white space characters.

### 4.44 The match of an input

@req input-matches=v1
@cites #notation=v1
@cites #tag-words=v1
@cites #inline-citations=v1
@cites #declaration-grammar=v1
@cites #citation-grammar=v1
@cites #status-grammar=v1
@cites #extern-grammar=v1
@cites #ack-grammar=v1
@cites #inline-grammar=v1

A match of an input is a match of the input by one production:
`declaration-line` for a declaration, `citation-line` for a citation,
`status-line` for a status tag, `extern-line` for an `@extern` line,
`ack-line` for an `@ack` line, and `inline-destination` for the
destination of an inline citation.

### 4.45 The tag word

@req tag-word-value=v1
@cites #result-list=v1
@cites #tag-lines=v1
@cites #external-namespaces=v1

Under a binding of `external-namespaces` that it accepts, a conforming
parser must give the tag word of each tag line as a value.

### 4.46 Values

@req values=v1
@cites #characters=v1
@cites #notation=v1
@cites #result-list=v1
@cites #tag-lines=v1
@cites #tag-words=v1
@cites #line-layout=v1
@cites #inline-citations=v1
@cites #segments=v1
@cites #kind-words=v1
@cites #revisions=v1
@cites #external-namespaces=v1
@cites #external-ids=v1
@cites #citation-grammar=v1
@cites #ack-grammar=v1
@cites #input-matches=v1

Under a binding of `external-namespaces` that it accepts, a conforming
parser must give each value of this table whose second column describes
the input, for each declaration, citation, status tag, directive, and
inline citation that it accepts. It must give no other value for such
an input, except the tag word of a tag line.

| value | input | the value |
|---|---|---|
| declaration, citation, status tag, or directive | a tag line with a Sinter tag word | which of these four the tag line is |
| the kind word | an input whose match holds `kind-word` | the text that `kind-word` matches |
| the slug | an input whose match holds `slug` | the text that `slug` matches |
| the slug | a declaration with the tag word `@spec` whose target holds no `#` | the text that `segment` matches |
| the custom namespace | an input whose match holds `slug`, when the text that `slug` matches holds a `/` | the custom namespace of that text |
| the part name | an input whose match holds `part-name` | the text that `part-name` matches |
| every part | a citation whose target is an every-part target | no text |
| the namespace name | an input whose match holds `external-id` | the text that `namespace-name` matches in `external-id` |
| the id | an input whose match holds `external-id` | the text that `id-text` matches |
| the revision | an input whose match holds `revision` or `label` | the text that `revision` matches, or the text that `label` matches when the match holds no `revision` |
| the inline description | a declaration, a citation, a status tag, or an `@extern` line | its inline description |
| the subject | an `@ack` line | the text that `subject` matches, or the empty text when the match holds no `subject` |
| the hash | an `@ack` line | the text that `hash` matches |
| the link text | an inline citation | its link text |

Each value that is a text is a run of the characters of the line, of
the destination, or of the raw content that holds the link text,
without a change.

### 4.47 No other values

@req no-other-values=v1
@cites commonmark/0.31.2
@cites #result-list=v1
@cites #tag-lines=v1
@cites #inline-citations=v1
@cites #id-pattern-grammar=v1
@cites #external-namespaces=v1

A conforming parser must give no value for a line, a link, an image, an
id pattern, or a binding of `external-namespaces` that it does not
accept, except the tag word of a tag line.

### 4.48 Results

@req results=v1
@cites commonmark/0.31.2
@cites #result-list=v1
@cites #tag-lines=v1
@cites #tag-words=v1
@cites #inline-citations=v1
@cites #id-pattern-grammar=v1
@cites #external-namespaces=v1

A conforming parser must give exactly one result for each input of this
table, and only a result that the table lists for that input. For a
line, a link, and an image, this obligation holds under a binding of
`external-namespaces` that the parser accepts. An id pattern of a
binding is not an input of this table apart from the binding.

| input | result |
|---|---|
| a line that is not a tag line | not a tag line |
| a tag line whose tag word is not a Sinter tag word | other tag word |
| a declaration, a citation, a status tag, or a directive | valid or invalid |
| a link or an image of a markdown document that is not an inline citation | not an inline citation |
| an inline citation | valid or invalid |
| an id pattern | valid or invalid |
| a binding of `external-namespaces` | valid or invalid |
| an id pattern that the parser accepts, and an id | fits or does not fit |

### 4.49 Acceptance

@req acceptance=v1
@cites #result-list=v1
@cites #tag-words=v1
@cites #inline-citations=v1
@cites #id-pattern-grammar=v1
@cites #external-namespaces=v1
@cites #id-pattern-syntax=v1
@cites #id-pattern-ranges=v1
@cites #id-pattern-counts=v1
@cites #id-pattern-bounds=v1
@cites #id-pattern-empty=v1
@cites #id-pattern-size-limit=v1
@cites #id-pattern-length=v1
@cites #namespace-name-form=v1
@cites #namespace-name-unique=v1
@cites #namespace-patterns=v1
@cites #declarations=v1
@cites #citations=v1
@cites #status-tags=v1
@cites #extern=v1
@cites #ack=v1
@cites #inline-targets=v1
@cites #inline-link-text=v1

A conforming parser must accept each declaration, citation, status tag,
directive, inline citation, id pattern, and binding of
`external-namespaces`, unless one of these requirements states that the
parser must reject it: `id-pattern-syntax`, `id-pattern-ranges`,
`id-pattern-counts`, `id-pattern-bounds`, `id-pattern-empty`,
`id-pattern-size-limit`, `id-pattern-length`, `namespace-name-form`,
`namespace-name-unique`, `namespace-patterns`, `declarations`,
`citations`, `status-tags`, `extern`, `ack`, `inline-targets`, and
`inline-link-text`. For a declaration, a citation, a status tag, a
directive, and an inline citation, this obligation holds under a binding
of `external-namespaces` that the parser accepts.

## 5. Conformance

A parser conforms to this design when it meets every requirement of
section 4.

Each vector below gives an input and the result that a conforming
parser gives for it. These conventions apply:

- In sections 5.1 and 5.2, the parser reads each input under a binding
  of `external-namespaces` with two pairs: `gh` with the id pattern
  `[1-9][0-9]*`, and `rfc` with the id pattern `[1-9][0-9]*`.
- For a valid input, a row names every value that the parser gives,
  with two exceptions: the tag word of a tag line, and an inline
  description that is empty.
- For an input that is not valid, the parser gives no value, except the
  tag word of a tag line. A row of a tag line with another tag word
  names that tag word.
- The text after "invalid:" or "not an inline citation:" explains the
  result. A parser does not give it.

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
| `@design billing/auth` | invalid: no revision |
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
| `@cites billing/auth` | invalid: no revision |
| `@cites docs` | invalid: no revision |
| `@cites docs=` | invalid: no label after `=` |
| `@cites docs=v1.2.0` | valid citation: slug `docs`, revision `v1.2.0` |
| `@cites docs=v1, and more` | valid citation: slug `docs`, revision `v1,`, inline description `and more` |
| `@cites docs=v@1` | invalid: a label holds no `@` |
| `@cites docs=v=1` | invalid: a label holds no `=` |
| `@cites docs=v3#size=v2` | invalid: a target carries one revision at most |
| `@cites docs@3f2a9c=*` | invalid: a slug holds no `@` |
| `@cites docs=v3#size` | invalid: the revision of the part name `size` follows `size`, and a label holds no `#` |
| `@cites docs#a/b=v1` | invalid: `a/b` is not a part name |
| `@cites docs#a#b=v1` | invalid: a second `#` |
| `@cites plan:upkeep=*` | invalid: `plan` is not a kind word, and a slug holds no `:` |
| `@cites spec:docs=v2` | valid citation: kind word `spec`, slug `docs`, revision `v2` |
| `@cites term:docs#segment=v1` | valid citation: kind word `term`, slug `docs`, part name `segment`, revision `v1` |
| `@refines docs#size=v2` | valid citation: slug `docs`, part name `size`, revision `v2` |
| `@refines docs=*` | invalid: only `@cites` takes the revision `*` |
| `@satisfies docs#size=*` | invalid: only `@cites` takes the revision `*` |
| `@verifies spec:docs#size=v1` | valid citation: kind word `spec`, slug `docs`, part name `size`, revision `v1` |
| `@supersedes docs=v3#*` | valid citation: slug `docs`, revision `v3`, every part |
| `@supersedes docs#*=v3` | invalid: in an every-part target, the revision follows the slug |
| `@supersedes docs=*#*` | invalid: the revision of an every-part target is a label |
| `@cites docs=v3#*` | invalid: only `@supersedes` takes an every-part target |
| `@supersedes design:docs=v3#*` | invalid: an every-part target holds no kind word |
| `@cites gh/42` | valid citation: namespace name `gh`, id `42` |
| `@verifies gh/42` | valid citation: namespace name `gh`, id `42` |
| `@cites spec:rfc/8259#section-6` | valid citation: kind word `spec`, namespace name `rfc`, id `8259`, part name `section-6` |
| `@cites gh/0` | invalid: `0` does not fit the id pattern of `gh` |
| `@cites gh/42=v1` | invalid: the target is external, and an id holds no `=` |
| `@cites gh/42/x` | invalid: the target is external, and an id holds no `/` |
| `@cites gh` | invalid: the target is external, and no `/` and id follow `gh` |
| `@cites gh=v1` | invalid: the head is `gh`, so the target is external, and no `/` and id follow `gh` |
| `@supersedes gh/42#*` | invalid: the target is external, and `*` is not a part name |
| `@cites jira/PROJ-1=*` | valid citation: slug `jira/PROJ-1`, custom namespace `jira`, revision `*` |
| `@extern spec:descriptor` | valid directive: kind word `spec`, part name `descriptor` |
| `@extern spec:gh` | valid directive: kind word `spec`, part name `gh` |
| `@extern spec:descriptor=v1` | invalid: the target of `@extern` carries no revision |
| `@extern descriptor` | invalid: no kind word |
| `@extern spec:packs#descriptor` | invalid: the target of `@extern` holds no `#` |
| `@ack retired docs#size=v2 3f2a9c1d` | valid directive: slug `retired`, subject `docs#size=v2`, hash `3f2a9c1d` |
| `@ack unexercised 3f2a9c1d0b7e` | valid directive: slug `unexercised`, empty subject, hash `3f2a9c1d0b7e` |
| `@ack retired a @b 3f2a9c1d` | valid directive: slug `retired`, subject `a @b`, hash `3f2a9c1d` |
| `@ack retired 3f2a9c1d`, then two spaces | valid directive: slug `retired`, empty subject, hash `3f2a9c1d` |
| `@ack retired docs#size=v2`, two spaces, and `3f2a9c1d` | valid directive: slug `retired`, subject `docs#size=v2`, hash `3f2a9c1d` |
| `@ack retired`, a space, and `0123456789abcdef` written 4 times | valid directive: slug `retired`, empty subject, hash `0123456789abcdef` written 4 times |
| `@ack retired`, a space, `0123456789abcdef` written 4 times, and `0` | invalid: the hash has more than 64 digits |
| `@ack retired 3F2A9C1D` | invalid: the hash holds upper-case letters |
| `@ack retired 3f2a9c` | invalid: the hash has fewer than 8 digits |
| `@ack 3f2a9c1d` | invalid: `3f2a9c1d` is the slug, and no hash follows it |

### 5.2 Inline citations

Each row gives a markdown document that holds one link or one image.
When a row holds a link inside the link text of another link, the
result is the result of the outer link.

| document | result |
|---|---|
| `[the size limit](sinter:req:packs#size-limit=v2)` | valid: link text `the size limit`, kind word `req`, slug `packs`, part name `size-limit`, revision `v2` |
| `[the size limit](sinter:req:packs#size-limit)` | invalid: no revision |
| `[any revision](sinter:packs#size-limit=*)` | valid: link text `any revision`, slug `packs`, part name `size-limit`, revision `*` |
| `[](sinter:packs#size-limit=v2)` | invalid: the plain string content of the link text is empty |
| `[ ](sinter:packs#size-limit=v2)` | invalid: the plain string content of the link text is one space |
| `[&nbsp;](sinter:packs#size-limit=v2)` | invalid: the plain string content of the link text is U+00A0, a white space character |
| `[<!-- -->](sinter:packs#size-limit=v2)` | invalid: raw HTML gives no plain string content |
| `> [`, a line feed, and `> ](sinter:packs#size-limit=v2)` | invalid: the plain string content of the link text is a line feed |
| `> [the`, a line feed, and `> limit](sinter:packs#size-limit=v2)` | valid: link text `the`, a line feed, and `limit`, slug `packs`, part name `size-limit`, revision `v2` |
| `[<https://example.com>](sinter:packs#size-limit=v2)` | valid: link text `<https://example.com>`, slug `packs`, part name `size-limit`, revision `v2` |
| `[`, U+200B, and `](sinter:packs#size-limit=v2)` | valid: link text U+200B, slug `packs`, part name `size-limit`, revision `v2` |
| `[**](sinter:packs#size-limit=v2)` | valid: link text `**`, slug `packs`, part name `size-limit`, revision `v2` |
| `[the limit](sinter:#size-limit=v2)` | valid: link text `the limit`, part name `size-limit`, revision `v2` |
| `[RFC 8259](sinter:spec:rfc/8259)` | valid: link text `RFC 8259`, kind word `spec`, namespace name `rfc`, id `8259` |
| `[x](sinter:gh/42=v2)` | invalid: the target is external, and an id holds no `=` |
| `[auth](sinter:billing/auth=v3)` | valid: link text `auth`, slug `billing/auth`, custom namespace `billing`, revision `v3` |
| `[auth](sinter:billing/auth)` | invalid: no revision |
| `[auth][r]`, a blank line, and the line `[r]: sinter:billing/auth=v3` | valid: link text `auth`, slug `billing/auth`, custom namespace `billing`, revision `v3` |
| `<sinter:req:packs#size-limit=v2>` | valid: link text `sinter:req:packs#size-limit=v2`, kind word `req`, slug `packs`, part name `size-limit`, revision `v2` |
| `[*the* limit](sinter:packs#size-limit=v2)` | valid: link text `*the* limit`, slug `packs`, part name `size-limit`, revision `v2` |
| `[x](sinter:packs\#size-limit=v2)` | valid: link text `x`, slug `packs`, part name `size-limit`, revision `v2` |
| `[x](sinter:packs&#35;size-limit=v2)` | valid: link text `x`, slug `packs`, part name `size-limit`, revision `v2` |
| `[x](sinter:&#65;uth=v1)` | valid: link text `x`, slug `Auth`, revision `v1` |
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
it also gives ids that fit it, for which the parser gives the result
"fits", and ids that do not fit it, for which the parser gives the
result "does not fit".

- `[1-9][0-9]*`: valid; ids that fit: `42`; ids that do not fit: `0`,
  `042`, `４２`.
- `[A-Z]+-[1-9][0-9]*`: valid; ids that fit: `PROJ-1`; ids that do not
  fit: `proj-1`.
- `[.]x`: valid; ids that fit: `.x`; ids that do not fit: `ax`.
- `[a-]+`: valid; ids that fit: `a-a`, `-`; ids that do not fit: `b`.
- `[-]`: valid; ids that fit: `-`; ids that do not fit: `a`.
- `ab|c`: valid; ids that fit: `ab`, `c`; ids that do not fit: `ac`.
- `a{0}b`: valid; ids that fit: `b`; ids that do not fit: `ab`.
- `([0-9]{3}-){10}`: valid; ids that fit:
  `123-123-123-123-123-123-123-123-123-123-`; ids that do not fit:
  `123-`.
- `([0-9]{250}){4}`: valid.
- the character class `[0123456789]` written 83 times, then `[01]`,
  which is 1,000 characters: valid.
- `^[0-9]+$`: invalid: `^` and `$` are not literals.
- `.+`: invalid: `.` is not a literal.
- `é+`: invalid: `é` is not a literal.
- `[#0-9]+`: invalid: `#` is not a member of a character class.
- `x=[0-9]+`: invalid: `=` is not a literal.
- `[0-9=]+`: invalid: `=` is not a member of a character class.
- `[a-z]+/[1-9]`: invalid: `/` is not a literal.
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
- `[0-9]*`: invalid: the empty id fits it.
- `([0-9]{143}){7}`: invalid: its size is 1,001.
- `((a{0,255}){0,255})b`: invalid: its size is 65,026.
- the character class `[0123456789]` written 83 times, then `[01]0`,
  which is 1,001 characters: invalid: it holds more than 1,000
  characters.

### 5.4 Bindings of `external-namespaces`

| binding | result |
|---|---|
| the empty set | valid |
| `gh` with `[1-9][0-9]*` | valid |
| `my-tracker` with `[A-Z]+-[1-9][0-9]*` | valid |
| `GH` with `[1-9][0-9]*` | invalid: `GH` does not match `namespace-name` |
| `my--tracker` with `[1-9][0-9]*` | invalid: `my--tracker` does not match `namespace-name` |
| `9ns` with `[1-9][0-9]*` | invalid: `9ns` does not match `namespace-name` |
| `gh` with `[1-9][0-9]*`, and `gh` with `[a-z]+` | invalid: two pairs with the namespace name `gh` |
| `gh` with `[0-9]*` | invalid: the empty id fits the id pattern |
