<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Identifiers
@design identifiers=v1
@cites rfc/5234
@cites rfc/7405
@cites commonmark/0.31.2
A parser reads lines, links, images, id patterns, ids, and bindings of `external-namespaces`; it gives a result for each input, and values for some inputs.

A tag line starts, after any spaces and tabs, with a tag word such as
`@req`. A declaration, such as `@req size-limit=v2`, is a tag line that
gives a name and a revision. A citation, such as
`@cites packs#size-limit=v2`, is a tag line that gives what it cites:
a name and a revision, or an external id. A citation can also cite
several things in a target list or a scoped list, such as
`@cites {#notation=v1, gh/42}` and
`@cites packs#{size=v1, descriptor=v2}`. An inline citation is a link
of a markdown document that cites in the same way. An id pattern gives
the form of the ids of an external namespace, such as the issue
numbers of a tracker.

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
destination and its link text, the inline elements of a link text, and
the Unicode whitespace characters.

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
| link | an inline link, a reference link, or an autolink of a markdown document, as CommonMark 0.31.2 defines them; an image is not a link |
| destination | the address of a link, such as `sinter:packs#size-limit=v2` in `[the limit](sinter:packs#size-limit=v2)` |
| link text | the text between the brackets of a link, such as `the limit` in `[the limit](sinter:packs#size-limit=v2)` |
| raw content | the lines of a paragraph or a heading, joined by line feeds, without the markers of block quotes and list items, and without the spaces and tabs at the start of each line |
| inline citation | a link whose destination starts with `sinter:` |
| target | the run of characters after the tag word of a declaration, a citation, or an `@extern` line and the spaces and tabs after the tag word, up to the next space or tab outside braces, or up to the end of the line or of its last continuation line; also the destination of an inline citation after `sinter:` |
| inline description | the text of a tag line after its target, or after the tag word of a status tag, without the spaces and tabs at its start; an `@ack` line has none |
| segment | a run of ASCII letters and ASCII digits, with one `-`, `_`, or `.` at most between two of them, such as `size-limit` |
| slug | one segment, or several segments joined by `/`, such as `packs` or `billing/auth` |
| custom namespace | the text of a slug before its last `/`, such as `billing` in `billing/auth` and `a/b` in `a/b/c` |
| part name | the segment after `#` in a name, such as `descriptor` in `packs#descriptor` |
| full name | a slug, `#`, and a part name, such as `packs#descriptor` |
| name | a slug, a full name, or `#` and a part name |
| kind word | one of six words, such as `req`, that can stand with a `:` at the start of a target, as in `req:packs#size-limit=v2` |
| label | a run of printable ASCII characters other than `/`, `#`, `@`, `*`, `=`, `,`, `{`, and `}`, such as `v2` |
| revision | a label, or `*`, which stands for any label; in a target it follows a name and `=`, as `v2` in `docs#size=v2` and `v3` in `docs=v3#*` |
| every-part target | a slug, `=`, a label, and `#*`, such as `docs=v3#*` |
| scoped list | an optional kind word and `:`, an optional slug, `#{`, part names with their revisions separated by `,`, and `}`, such as `packs#{size=v1, descriptor=v2}`, which stands for `packs#size=v1` and `packs#descriptor=v2` |
| target list | `{`, one or more single targets or scoped lists separated by `,`, and `}`: a target of a citation, such as `{#notation=v1, gh/42}` |
| single target | a target that is neither a target list nor a scoped list, such as `packs#size=v1` |
| entry | a single target of a citation, or a single target for which a part name of a scoped list stands |
| continuation line | a line that continues the target list or the scoped list of a citation on a line before it, up to the line that holds its closing `}` |
| parameter | a name, such as `external-namespaces`, for which a program gives a binding, under which a parser reads lines, links, and images |
| binding | what a program gives for a parameter, such as a set of pairs for `external-namespaces` |
| external namespace | one pair of the binding of `external-namespaces`: a namespace name and an id pattern |
| namespace name | the name of an external namespace, such as `gh` |
| external id | a namespace name, `/`, and an id, such as `gh/42` |
| id | a text that a parser tests against an id pattern, such as `42` in `gh/42` |
| id pattern | a small regular expression, which gives the form of the ids of one external namespace |
| fit | an id fits an id pattern when the id has the form that the id pattern gives, such as `42` for `[1-9][0-9]*` |
| head | the text of a target or an entry without its kind word and the `:` after it, up to its first `#` or `=` |
| external target | the target of a declaration or of an inline citation, or an entry of a citation, whose head starts with a namespace name, followed by `/` or by the end of the head |
| plain string content | the text that a link text shows without its markup, such as `the limit` for `*the* limit` |
| blank character | a character that shows no text: a Unicode whitespace character of CommonMark 0.31.2, such as a space, a tab, a line feed, or U+00A0, the no-break space; or one of U+200B, U+200C, U+200D, U+2060, and U+FEFF, such as U+200B, the zero width space |
| input | a line, a link, or an image that a parser reads, or an id pattern, a binding of `external-namespaces`, or a pair of an id pattern and an id that a program gives to the parser |
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
it is the same text as one of them, so `@Req` and `@reqs` are not
Sinter tag words. For a tag line whose tag word is not a Sinter tag
word, a conforming parser gives the result "other tag word" and the tag
word, and nothing more.

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
| `@ack` | directive | none; a form of its own (section 2.7) | none |

In a declaration, a citation, and an `@extern` line, one or more spaces
or tabs follow the tag word, and then the target. The target ends at
the next space or tab, or at the end of the line. The target of a
citation can also be a target list or a scoped list, which can hold
spaces, tabs, and line breaks between its braces, and can continue on
the lines that follow (section 2.6). The inline
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
characters other than `/`, `#`, `@`, `*`, `=`, `,`, `{`, and `}`, such
as `v2`, `2026-11`, `v1.2.0`, or `rc1`. `*` stands for any label.

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
`@cites docs=v1; and more` the label is `v1;`. A label holds no `=`,
`,`, `{`, or `}`, so `@cites docs=v=1` and `@cites docs=v1, and more`
are invalid.

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
than `#`, `/`, `=`, `@`, `,`, `{`, and `}`, and it fits the id pattern
of the external namespace. An external id can take `#` and a part name,
as in `rfc/8259#section-6`. An external id carries no revision.

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

### 2.6 Target lists and scoped lists

A citation can cite several things on one line. Its target can be a
target list, a scoped list, or a target list that holds scoped lists.

A target list is `{`, one or more single targets or scoped lists
separated by `,`, and `}`, such as `{#notation=v1, gh/42}`. A single
target is a target of the forms of sections 2.1 to 2.5: a target that
is neither a target list nor a scoped list.

A scoped list is an optional kind word and `:`, an optional slug, `#{`,
one or more part names separated by `,`, each with `=` and a revision,
and `}`, such as `packs#{size=v1, descriptor=v2}`. Each part name of a
scoped list, with its `=` and its revision, stands for a single target:
the kind word and the `:` of the scoped list, its slug, `#`, the part
name, `=`, and the revision. So `req:packs#{size=v1, descriptor=v2}`
stands for `req:packs#size=v1` and `req:packs#descriptor=v2`. A scoped
list with no slug, such as `#{notation=v1, characters=v1}`, stands for
`#notation=v1` and `#characters=v1`. A scoped list holds no kind word
between its braces, and it holds no target list.

Spaces and tabs can stand after each `{`, before and after each `,`,
and before each `}`. A space or a tab between a `{` and the `}` that
closes it does not end the target. One `,` can also stand right before
a `}`, so `{docs=v1, docs#size=v2,}` and `packs#{size=v1,}` are valid.
After the target, the line ends, or one or more spaces or tabs and an
inline description follow. Example: in
`@cites {#notation=v1, packs#{size=v1, descriptor=v2}} The limits.`,
the inline description is `The limits.`.

A target list or a scoped list can continue over the lines that follow
its citation. When a space or a tab follows the tag word of a citation,
and its line ends before the `}` that closes a `{` of its target, the
next line continues the target. The lines continue in this way up to
the line that holds that `}`. Each of these lines is a continuation
line of the citation, and the spaces and tabs at its start do not
count. A line break counts as a space or a tab: it can stand after
each `{`, before and after each `,`, and before each `}`, and nowhere
else. So an entry does not break across lines. After the closing `}`,
the rest of its line can hold an inline description. Example:

```
@cites #{
    notation=v1, characters=v1,
    segments=v1,
}
```

These four lines are one citation with the entries `#notation=v1`,
`#characters=v1`, and `#segments=v1`. A tag line and an empty line, a
line that holds nothing or only spaces and tabs, are never continuation
lines. When no line follows, or a tag line or an empty line follows,
before the closing `}`, the citation is invalid, and the line that
follows is an input of its own.

The entries of a citation are its single targets and the single
targets for which the part names of its scoped lists stand, in their
order. A citation whose target is a single target has one entry: its
target. Each entry follows the rules of a single target of the tag word
of its citation:

- An entry of `@cites` carries a label or `*`. An entry of `@refines`,
  `@satisfies`, `@supersedes`, or `@verifies` carries a label.
- An entry that is an external id carries no revision. The rule of
  external targets (section 2.5) applies to each entry. So under a
  binding with the external namespace `gh`, `@cites gh#{size=v1}` is
  invalid: it stands for `gh#size=v1`, whose head is `gh`.
- Only a single target of `@supersedes` can be an every-part target. A
  scoped list stands for no every-part target.

The name of an entry is its slug, its full name, its `#` and part name,
or its external id with its `#` and part name. No two entries of a
citation have the same name, whatever their kind words and revisions.
So `@cites {docs=v1, docs#size=v2}` and
`@cites {identifiers#{segments=v1, notation=v1}, gh/42}` are valid, and
these citations are invalid when no line follows them:

- `@cites {}`, because a target list holds one single target or scoped
  list at least;
- `@cites {docs=v1,,}`, because a single target or a scoped list stands
  between each two `,`;
- `@cites {docs=v1 docs#size=v2}`, because a `,` separates two single
  targets;
- `@cites {#a=v1, req:#a=v2}`, because its two entries have the name
  `#a`;
- `@cites {packs#size=v1, packs#{size=v2}}`, because its two entries
  have the name `packs#size`;
- `@refines packs#{size=*}`, because only an entry of `@cites` carries
  `*`;
- `@cites {{docs=v1}}`, because a target list holds no target list;
- `@cites {docs=v1,`, because no line follows to close the target list;
- `@design {docs=v1}`, because only a citation has a target list.

An inline citation cites one target, so `[x](sinter:{docs=v1})` and
`[x](sinter:packs#{size=v1})` are invalid.

For a valid citation, a conforming parser gives the values of each
entry as one group, in the order of the entries. It gives the tag word
and the inline description of the line once.

### 2.7 The directives `@extern` and `@ack`

The target of `@extern` is a kind word, `:`, and a part name, such as
`spec:descriptor`. It holds no `#`, so no slug comes before the part
name. It holds no revision.

An `@ack` line holds two or more runs of characters other than spaces
and tabs after `@ack`, with spaces or tabs between them:

- The first is a slug.
- The last is the **hash**: from 8 to 64 lower-case hexadecimal digits,
  `0` to `9` and `a` to `f`.
- The text between these two, without the spaces and tabs at its two
  ends, is the **subject**. The subject can be empty, and it can hold
  any character, spaces and `@` included.

Spaces and tabs can follow the hash, and nothing else can. Example: in
`@ack retired docs#size=v2 3f2a9c1d`, the slug is `retired`, the subject
is `docs#size=v2`, and the hash is `3f2a9c1d`.

### 2.8 Inline citations

An inline citation is a link whose destination starts with the seven
characters `sinter:`. A link is an inline link, a reference link, or an
autolink of a markdown document, as CommonMark 0.31.2 defines them. An
image is not a link, so `![x](sinter:packs#size-limit=v2)` is not an
inline citation.

The destination of an inline link or a reference link is its link
destination as CommonMark gives it. The destination holds no angle
brackets that enclose it, and each backslash escape, entity reference,
and numeric character reference in it is replaced by the characters
that CommonMark 0.31.2 gives for it. No percent-encoding and no
percent-decoding applies to a destination, so `%23` is three characters
and not `#`. So
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
heading that holds the link. The raw content holds the lines of the
paragraph or the heading, joined by line feeds. Each line of the raw
content is without the markers and the indentation of block quotes and
list items, and without the spaces and tabs at its start. So in a block
quote, the lines `> [the` and `> limit](sinter:packs#size-limit=v2)`
give the link text `the`, a line feed, and `limit`. The line `[the`,
followed by a line that holds three spaces and then
`limit](sinter:packs#size-limit=v2)`, gives the same link text. The
link text keeps its markup, such as
`*the* limit` in `[*the* limit](sinter:packs#size-limit=v2)`. The link
text of an autolink, such as `<sinter:req:packs#size-limit=v2>`, is its
text between `<` and `>`.

An inline citation is invalid when the plain string content of its
link text holds no character other than blank characters. A blank
character is a Unicode whitespace character of CommonMark 0.31.2, or
one of the characters U+200B, U+200C, U+200D, U+2060, and U+FEFF, which
show no text. The plain string content of the link text of an autolink
is that link text.
The plain string content of the link text of an inline link or a
reference link is the text that the inline elements of the link text
give without their markup, in their order and joined together:

- Textual content gives its characters, with each backslash escape,
  entity reference, and numeric character reference replaced by the
  characters that CommonMark 0.31.2 gives for it, so `&nbsp;` gives
  U+00A0.
- A code span gives its content.
- Emphasis and strong emphasis give the plain string content of what
  they hold, so `*the* limit` gives `the limit`.
- An image gives the plain string content of its description.
- An autolink gives its text between `<` and `>`.
- A line break gives a line feed.
- Raw HTML, such as `<!-- -->`, gives no characters.

So `[](sinter:packs#size-limit=v2)`, `[ ](sinter:packs#size-limit=v2)`,
`[&nbsp;](sinter:packs#size-limit=v2)`,
`[&#x200B;](sinter:packs#size-limit=v2)`, and
`[<!-- -->](sinter:packs#size-limit=v2)` are invalid. But
`[**](sinter:packs#size-limit=v2)` is valid, because `**` that opens no
emphasis is text.

The link text of an inline link or a reference link can hold an
autolink. Section 6.3 of CommonMark 0.31.2 says that a link holds no
other link, but the parsing strategy in the appendix of CommonMark
0.31.2 builds both links, and a conforming parser follows the parsing
strategy. So the text
`[<https://example.com>](sinter:packs#size-limit=v2)` is a link, and
the autolink inside it is a link too. This inline citation is valid:
the autolink gives `https://example.com` to the plain string content of
its link text.

### 2.9 Id patterns

An id pattern is a small regular expression. An id fits an id pattern
when the whole id, and not only a part of it, has the form that the id
pattern gives. An id pattern is built from these elements:

| element | form | texts that fit it |
|---|---|---|
| literal | one printable ASCII character other than `\ . [ ] ( ) { } * + ? \| ^ $ # / = @ ,` | that character |
| character class | `[`, members, `]`, with a `-` that can also stand right after the `[` or right before the `]`; it holds one member or such a `-` at least | one character that fits a member; also `-` when the class holds a `-` right after its `[` or right before its `]` |
| member | a printable ASCII character other than `\ [ ] ^ - # / = @ , { }` | that character |
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

The elements of an id pattern are written as in POSIX extended regular
expressions, RE2, and ECMAScript, so a reader who knows one of these
can read an id pattern. Only the requirements in section 4 decide which
ids fit an id pattern.

### 2.10 Inputs, results, and values

The inputs of a conforming parser are the lines, the links, and the
images that it reads, and the id patterns, the bindings of
`external-namespaces`, and the pairs of an id pattern and an id that a
program gives to it. The parser reads the lines in the order in which
a program gives them to it, so the lines that follow a line are the
lines after it in that order. A citation and its continuation lines
are one input, and a continuation line gets no result of its own. An
id pattern is an input only when a program
gives it on its own, and not in a binding. A pair is an input only when
its id pattern is an input that the parser accepts. A conforming parser
gives one result for each input, and no result for anything that is
not an input. So the id patterns of a binding get no results of their
own: the binding gets one result. The parser also gives no result when
it tests the id of an external target against an id pattern of the
binding.

A line gets one of four results: not a tag line, other tag word, valid,
or invalid. A link or an image gets one of three results: not an inline
citation, valid, or invalid. An id pattern and a binding of
`external-namespaces` each get valid or invalid. A pair of an id
pattern and an id gets fits or does not fit. Under a binding that the
parser rejects, the parser gives no result and no value for a line, a
link, or an image.

For a tag line, the parser gives the tag word. For a valid declaration,
citation, status tag, directive, or inline citation, it also gives the
values that the input holds, such as the kind word, the slug, the
custom namespace, the part name, the namespace name and the id, the
revision, the inline description, the subject and the hash, and the
link text. For a citation, it gives the values of each entry as one
group, in the order of the entries. It gives each value together with
its name, such as "the slug". For each other input, it gives no value
other than the tag word of a tag line. Each value of a tag line that is
a text is a run of the characters of the line. Each value of the target
of an inline citation is a run of the characters of the destination,
so `[x](sinter:&#65;uth=v1)` gives the slug `Auth`. The link text is
the text that section 2.8 describes.

## 3. Parameters

### 3.1 `external-namespaces`

The parameter `external-namespaces` gives the external namespaces. Its
binding is a finite set of pairs. A conforming parser reads each line,
link, and image under one binding. The external namespaces of that
line, link, or image are the pairs of that binding: each pair is one
external namespace, with a namespace name and an id pattern. The
binding can be the empty set, and then no target is external.

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
@cites {rfc/5234, rfc/7405, #{characters=v1}}

The productions of this design are rules of ABNF, the notation of
RFC 5234, with the case-sensitive strings of RFC 7405. They use the core
rules of RFC 5234, Appendix B.1. Each terminal value of a production is
the code point of one character, so `%x41` matches the character
U+0041. A text matches a production when the production matches the
whole of the text.

### 4.3 Results and values

@req result-list=v1
@cites #{characters=v1}

The results are these seven: "not a tag line", "other tag word", "not
an inline citation", "valid", "invalid", "fits", and "does not fit". To
reject is to give the result "invalid". To accept is to give the result
"valid". A value is a text or a fact that a conforming parser gives
together with a result.

### 4.4 Tag lines

@req tag-lines=v1
@cites #{characters=v1, notation=v1}

A line is a text that holds no line feed. A tag line is a line whose
first character after the spaces and tabs at its start is `@`. The tag
word of a tag line is the longest text that starts at that `@` and that
matches `tag-word`:

```
tag-word  = "@" *( ALPHA / DIGIT / "-" )
```

### 4.5 Tag words

@req tag-words=v1
@cites #{tag-lines=v1, characters=v1}

The Sinter tag words are these fifteen tag words, in four sets:

- the declaration words: `@decision`, `@design`, `@finding-class`,
  `@req`, and `@spec`;
- the citation words: `@cites`, `@refines`, `@satisfies`,
  `@supersedes`, and `@verifies`;
- the status words: `@deferred`, `@deprecated`, and `@rejected`;
- the directive words: `@ack` and `@extern`.

A tag word is a Sinter tag word when, and only when, it is the same
text as one of these fifteen words. A declaration is a tag line whose
tag word is a declaration word. A citation is a tag line whose tag word
is a citation word. A status tag is a tag line whose tag word is a
status word. A directive is a tag line whose tag word is a directive
word. An `@ack` line is a tag line whose tag word is `@ack`, and an
`@extern` line is a tag line whose tag word is `@extern`.

### 4.6 Continuation lines

@req continuation=v1
@cites #{tag-lines=v1, tag-words=v1, characters=v1}

A conforming parser reads the lines that a program gives to it in their
order. For a citation in which a space or a tab follows the tag word,
these steps give its text and its continuation lines:

1. The text starts as the line of the citation. A count starts at the
   first character after the spaces and tabs that follow the tag word.
   The count goes through the text, one character after another, and
   keeps the number of `{` and the number of `}` that it has passed.
2. When the count comes to a space or a tab, or to the end of the text,
   and it has passed no more `{` than `}`, the text is complete.
3. When the count comes to the end of the text and it has passed more
   `{` than `}`, and the line that follows the last line of the text is
   neither a tag line nor an empty line, that line is a continuation
   line of the citation. The parser adds a line feed and that line,
   without the spaces and tabs at its start, to the end of the text,
   and the count goes on from the line feed.
4. When the count comes to the end of the text and it has passed more
   `{` than `}`, and no line follows the last line of the text, or the
   line that follows it is a tag line or an empty line, the text is
   complete.

An empty line is a line that holds no character other than spaces and
tabs. The text of each other tag line is its line.

### 4.7 Spaces, targets, and inline descriptions

@req line-layout=v1
@cites #{
    notation=v1, characters=v1, tag-lines=v1, tag-words=v1,
    continuation=v1,
}

The production `any-char` matches each character, and the other
productions give the spaces and tabs of a tag line:

```
any-char  = %x0-D7FF / %xE000-10FFFF
indent    = *WSP
gap       = 1*WSP
rest      = [ gap *any-char ]
```

The target of a declaration, a citation, or an `@extern` line is the
text that starts after the spaces and tabs that follow its tag word in
the text of the tag line. The target ends before the first space or tab
that has no more `{` than `}` of the target before it, or at the end of
the text of the tag line when no such space or tab follows. The inline
description of a declaration, a citation, or an `@extern` line is the
text of the tag line after its target, without the spaces and tabs at
its start. The inline description of a status tag is the text of the
tag line after its tag word, without the spaces and tabs at its start.
An inline description can be empty.

### 4.8 Segments and names

@req segments=v1
@cites #{notation=v1, characters=v1}

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

### 4.9 Kind words

@req kind-words=v1
@cites #{characters=v1, notation=v1}

The kind words are the texts that this production matches:

```
kind-word  = %s"decision" / %s"design" / %s"finding-class" / %s"req"
           / %s"spec" / %s"term"
```

### 4.10 Revisions

@req revisions=v1
@cites #{notation=v1}

These productions give the forms of a label and of a revision:

```
label     = 1*( %x21-22 / %x24-29 / %x2B / %x2D-2E / %x30-3C
              / %x3E-3F / %x41-7A / %x7C / %x7E )
revision  = label / "*"
```

### 4.11 Links

@req links=v1
@cites commonmark/0.31.2

A link is an inline link, a full, collapsed, or shortcut reference
link, or an autolink of a markdown document, each as CommonMark 0.31.2
defines it. An image is not a link. An inline link or a reference link
can hold an autolink among the inline elements that its square
brackets enclose. Then the inline link or the reference link is a link,
and the autolink is a link too, as the parsing strategy in the appendix
of CommonMark 0.31.2 builds them. For such an autolink, this rule takes
precedence over the rule in section 6.3 of CommonMark 0.31.2 that a
link holds no other link.

### 4.12 Destinations and inline citations

@req destinations=v1
@cites {#{links=v1, characters=v1}, commonmark/0.31.2}

The destination of an inline link or a reference link is its link
destination as CommonMark 0.31.2 gives it: without the angle brackets
that enclose it, and with each backslash escape, entity reference, and
numeric character reference replaced by the characters that CommonMark
0.31.2 gives for it. No percent-encoding and no percent-decoding
applies to a destination, so a `%` is a character of the destination.
The destination of an autolink is its text between `<` and `>`. An
inline citation is a link whose destination starts with the seven
characters `sinter:`. The target of an inline citation is the text of
its destination after `sinter:`.

### 4.13 Link text

@req link-text=v1
@cites {#{characters=v1, tag-lines=v1, links=v1}, commonmark/0.31.2}

The raw content of a paragraph or a heading is the text that these
steps give:

1. Take the lines of the paragraph or the heading, in their order, as
   CommonMark 0.31.2 gives them. Leave out the underline of a setext
   heading.
2. From each line, remove the markers and the indentation of the block
   quotes and the list items that hold the paragraph or the heading, as
   CommonMark 0.31.2 gives them. From the line of an ATX heading, also
   remove its opening sequence of `#` and its closing sequence of `#`.
3. From each line, remove the spaces and tabs at its start.
4. Join the lines, with a line feed between each two lines that follow
   one another.
5. Remove the spaces and tabs at the end of the text.

The link text of an inline link or a reference link is the text between
the `[` and the `]` that delimit its link text, in the raw content of
the paragraph or the heading that holds the link. The link text of an
autolink is its text between `<` and `>`.

### 4.14 Blank characters

@req blank-characters=v1
@cites {#{characters=v1}, commonmark/0.31.2}

A blank character is one of these characters:

- each Unicode whitespace character of CommonMark 0.31.2: U+0009,
  U+000A, U+000C, U+000D, U+0020, U+00A0, U+1680, each character from
  U+2000 to U+200A, U+202F, U+205F, and U+3000;
- U+200B, U+200C, U+200D, U+2060, and U+FEFF.

### 4.15 Plain string content

@req plain-string-content=v1
@cites {commonmark/0.31.2, #{characters=v1, links=v1, link-text=v1}}

The plain string content of a sequence of inline elements, as
CommonMark 0.31.2 parses them, is a text. It joins, in the order of the
elements, the texts that these rules give for the elements:

- Textual content gives its characters, with each backslash escape,
  entity reference, and numeric character reference replaced by the
  characters that CommonMark 0.31.2 gives for it.
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

### 4.16 The grammar of id patterns

@req id-pattern-grammar=v1
@cites #{characters=v1, notation=v1}

An id pattern is a text that a conforming parser reads as a pattern for
ids. An id is a text that a conforming parser tests against an id
pattern. These productions give the form of an id pattern:

```
pattern     = branch *( "|" branch )
branch      = 1*piece
piece       = atom [ quantifier ]
atom        = literal / char-class / "(" pattern ")"
literal     = %x21-22 / %x25-27 / %x2D / %x30-3C / %x3E / %x41-5A
            / %x5F-7A / %x7E
char-class  = "[" ( edge-dash *member / 1*member ) [ edge-dash ] "]"
edge-dash   = "-"
member      = range / single
range       = %x30-39 "-" %x30-39 / %x41-5A "-" %x41-5A
            / %x61-7A "-" %x61-7A
single      = %x21-22 / %x24-2B / %x2E / %x30-3C / %x3E-3F / %x41-5A
            / %x5F-7A / %x7C / %x7E
quantifier  = "?" / "*" / "+" / "{" count "}" / "{" count ",}"
            / "{" count "," count "}"
count       = "0" / %x31-39 *DIGIT
```

The number of a `count` is the decimal number that its digits write.
The quantifiers `{n}`, `{n,}`, and `{n,m}` are the forms
`"{" count "}"`, `"{" count ",}"`, and `"{" count "," count "}"`, where
`n` is the number of the first `count`, and `m` is the number of the
second `count`.

### 4.17 The meaning of id patterns

@req id-pattern-meaning=v1
@cites #{id-pattern-grammar=v1, notation=v1, characters=v1}

An id fits an id pattern that matches `pattern` when the whole id fits
that `pattern`. These rules state when a run of characters of the id,
which can be the whole id or the empty run, fits an element of the id
pattern:

- A run fits a `literal` when it is the one character of the
  `literal`.
- A run fits a `range` when it is one character that comes neither
  before the first character of the `range` nor after its last
  character in code point order. A run fits a `single` when it is the
  one character of the `single`. A run fits an `edge-dash` when it is
  the character `-`.
- A run fits a `member` when it fits the `range` or the `single` of the
  `member`.
- A run fits a `char-class` when it fits one of the `member` elements
  or one of the `edge-dash` elements of the `char-class`.
- A run fits an `atom` that is a `literal` or a `char-class` when it
  fits that `literal` or that `char-class`. A run fits an `atom` of the
  form `"(" pattern ")"` when it fits the inner `pattern`.
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

### 4.18 External namespaces

@req external-namespaces=v1
@cites #{
    characters=v1, id-pattern-grammar=v1, tag-lines=v1, links=v1,
    notation=v1,
}

A binding of `external-namespaces` is a finite set of pairs. Each pair
holds a namespace name, which is a text, and an id pattern. A
conforming parser reads each line, link, and image under one binding of
`external-namespaces`. The external namespaces of a line, a link, or an
image are the pairs of the binding under which the parser reads it.
This production gives the form of a namespace name:

```
namespace-name  = %x61-7A *( %x61-7A / DIGIT )
                  *( "-" 1*( %x61-7A / DIGIT ) )
```

### 4.19 Inputs

@req inputs=v1
@cites #{
    tag-lines=v1, links=v1, continuation=v1, tag-words=v1,
    id-pattern-grammar=v1, external-namespaces=v1, result-list=v1,
}

The inputs of a conforming parser are these:

- each line, link, and image that the parser reads, except a
  continuation line: a citation and its continuation lines are one
  input;
- each id pattern that a program gives to the parser on its own, and
  not in a binding of `external-namespaces`;
- each binding of `external-namespaces` that a program gives to the
  parser;
- each pair of an id pattern and an id that a program gives to the
  parser, when that id pattern is an input that the parser accepts.

### 4.20 The form of an id pattern

@req reject-unmatched-id-patterns=v1
@cites #{result-list=v1, id-pattern-grammar=v1, inputs=v1, notation=v1}

A conforming parser must reject each id pattern that is an input and
that does not match the production `pattern`.

### 4.21 Ranges in id patterns

@req reject-reversed-ranges=v1
@cites #{
    result-list=v1, id-pattern-grammar=v1, inputs=v1, characters=v1,
    notation=v1,
}

A conforming parser must reject each id pattern that is an input and
that holds a `range` whose first character comes after its last
character in code point order.

### 4.22 Counts in id patterns

@req reject-large-counts=v1
@cites #{result-list=v1, id-pattern-grammar=v1, inputs=v1, notation=v1}

A conforming parser must reject each id pattern that is an input and
that holds a `count` whose number is greater than 255.

### 4.23 Bounds in id patterns

@req reject-reversed-bounds=v1
@cites #{result-list=v1, id-pattern-grammar=v1, inputs=v1, notation=v1}

A conforming parser must reject each id pattern that is an input and
that holds a quantifier `{n,m}` in which `n` is greater than `m`.

### 4.24 Testing ids

@req test-ids=v1
@cites #{
    inputs=v1, id-pattern-grammar=v1, result-list=v1,
    id-pattern-meaning=v1,
}

For each input that is a pair of an id pattern and an id, a conforming
parser must give the result "fits" when the id fits the id pattern, and
the result "does not fit" when it does not.

### 4.25 The empty id

@req reject-empty-id-fit=v1
@cites #{
    result-list=v1, id-pattern-grammar=v1, inputs=v1, characters=v1,
    id-pattern-meaning=v1,
}

A conforming parser must reject each id pattern that is an input and
that the empty text, as an id, fits.

### 4.26 The size of an id pattern

@req id-pattern-size=v1
@cites #{characters=v1, notation=v1, id-pattern-grammar=v1}

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

### 4.27 The limit on the size of an id pattern

@req reject-oversized-id-patterns=v1
@cites #{
    result-list=v1, id-pattern-grammar=v1, inputs=v1,
    id-pattern-size=v1,
}

A conforming parser must reject each id pattern that is an input and
whose size is greater than 1,000.

### 4.28 The length of an id pattern

@req reject-long-id-patterns=v1
@cites #{
    result-list=v1, id-pattern-grammar=v1, inputs=v1, characters=v1,
}

A conforming parser must reject each id pattern that is an input and
that holds more than 1,000 characters.

### 4.29 The form of namespace names

@req reject-malformed-namespace-names=v1
@cites #{result-list=v1, external-namespaces=v1, notation=v1}

A conforming parser must reject a binding of `external-namespaces` that
holds a namespace name that does not match `namespace-name`.

### 4.30 Unique namespace names

@req reject-repeated-namespace-names=v1
@cites #{result-list=v1, external-namespaces=v1}

A conforming parser must reject a binding of `external-namespaces` in
which two pairs have the same namespace name.

### 4.31 The id patterns of a binding

@req reject-invalid-binding-patterns=v1
@cites #{
    result-list=v1, external-namespaces=v1, id-pattern-grammar=v1,
    inputs=v1, reject-unmatched-id-patterns=v1,
    reject-reversed-ranges=v1, reject-large-counts=v1,
    reject-reversed-bounds=v1, reject-empty-id-fit=v1,
    reject-oversized-id-patterns=v1, reject-long-id-patterns=v1,
}

A conforming parser must reject a binding of `external-namespaces` that
holds an id pattern that, as an input, the parser must reject under one
of these requirements: `reject-unmatched-id-patterns`, `reject-reversed-ranges`,
`reject-large-counts`, `reject-reversed-bounds`, `reject-empty-id-fit`,
`reject-oversized-id-patterns`, and `reject-long-id-patterns`.

### 4.32 A rejected binding

@req give-no-results-under-rejected-bindings=v1
@cites #{external-namespaces=v1, result-list=v1, tag-lines=v1, links=v1}

Under a binding of `external-namespaces` that it rejects, a conforming
parser must give no result for a line, a link, or an image.

### 4.33 External ids

@req external-ids=v1
@cites #{
    id-pattern-grammar=v1, notation=v1, segments=v1,
    external-namespaces=v1, characters=v1, id-pattern-meaning=v1,
}

These productions give the form of an external id:

```
external-ref  = external-id [ "#" part-name ]
external-id   = namespace-name "/" id-text
id-text       = 1*( %x21-22 / %x24-2B / %x2D-2E / %x30-3C / %x3E-3F
                    / %x41-7A / %x7C / %x7E )
```

In `external-id`, a text matches `namespace-name` only when it is the
namespace name of an external namespace. A text matches `external-id`
only when the text that its `id-text` matches, as an id, fits the id
pattern of the external namespace whose namespace name its
`namespace-name` matches.

### 4.34 External targets

@req external-targets=v1
@cites #{
    entries=v1, characters=v1, notation=v1, kind-words=v1, tag-words=v1,
    destinations=v1, external-namespaces=v1, line-layout=v1,
}

A target or an entry starts with a kind word when it holds a `:` and
the text before its first `:` matches `kind-word`. The head of a target
or an entry is its text after that kind word and that `:`, when it
starts with a kind word, and before its first character that is `#` or
`=`, when it holds one. The target of a declaration, the target of an
inline citation, and an entry of a citation are each external when the
text of its head before the first `/` of that head, or the whole head
when that head holds no `/`, is the namespace name of an external
namespace.

### 4.35 The grammar of declarations

@req declaration-grammar=v1
@cites #{
    tag-words=v1, notation=v1, line-layout=v1, segments=v1,
    revisions=v1,
}

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

### 4.36 The grammar of citations

@req citation-grammar=v1
@cites #{
    characters=v1, continuation=v1, tag-words=v1, notation=v1,
    line-layout=v1, kind-words=v1, segments=v1, revisions=v1,
    external-ids=v1,
}

These productions give the form of the text of a citation:

```
citation-line      = indent %s"@cites" gap ( cites-target / cites-list )
                     rest
                   / indent ( %s"@refines" / %s"@satisfies"
                            / %s"@verifies" )
                     gap ( fixed-target / fixed-list ) rest
                   / indent %s"@supersedes" gap
                     ( supersedes-target / supersedes-list ) rest
cites-list         = "{" list-space cites-target
                     *( comma cites-target ) [ list-space "," ]
                     list-space "}"
fixed-list         = "{" list-space fixed-target
                     *( comma fixed-target ) [ list-space "," ]
                     list-space "}"
supersedes-list    = "{" list-space supersedes-target
                     *( comma supersedes-target ) [ list-space "," ]
                     list-space "}"
cites-target       = cites-single / cites-scoped
fixed-target       = fixed-single / fixed-scoped
supersedes-target  = supersedes-single / fixed-scoped
cites-single       = [ kind-word ":" ] ( name "=" revision / external-ref )
fixed-single       = [ kind-word ":" ] ( name "=" label / external-ref )
supersedes-single  = [ kind-word ":" ] ( name "=" label / external-ref )
                   / every-part
every-part         = slug "=" label "#*"
cites-scoped       = [ kind-word ":" ] [ slug ] "#{" list-space
                     part-name "=" revision
                     *( comma part-name "=" revision )
                     [ list-space "," ] list-space "}"
fixed-scoped       = [ kind-word ":" ] [ slug ] "#{" list-space
                     part-name "=" label *( comma part-name "=" label )
                     [ list-space "," ] list-space "}"
comma              = list-space "," list-space
list-space         = *( WSP / LF )
```

An every-part target is a text that `every-part` matches.

### 4.37 Single targets and scoped lists

@req scoped-lists=v1
@cites #{
    notation=v1, characters=v1, continuation=v1, tag-words=v1,
    citation-grammar=v1, segments=v1, revisions=v1,
}

In a match of the text of a citation by `citation-line`, a single
target is a text that `cites-single`, `fixed-single`, or
`supersedes-single` matches, and a scoped list is a text that
`cites-scoped` or `fixed-scoped` matches. In a scoped list, each
`part-name`, with the `=` after it and the `revision` or the `label`
after that `=`, stands for a single target: the text of the scoped list
before its `{`, and then that `part-name`, that `=`, and that
`revision` or `label`.

### 4.38 Entries

@req entries=v1
@cites #{
    notation=v1, characters=v1, continuation=v1, tag-words=v1,
    citation-grammar=v1, scoped-lists=v1, tag-lines=v1, segments=v1,
    external-ids=v1,
}

The entries of a match of the text of a citation by `citation-line`
are, in their order in that text, its single targets and the single
targets for which the part names of its scoped lists stand. The match
of an entry is its match by `cites-single` when the tag word of the
citation is `@cites`, by `supersedes-single` when it is `@supersedes`,
and by `fixed-single` for each other citation word. The name of an
entry is the text that `name` or `external-ref` matches in the match of
the entry, or the text that `slug` matches in it when `every-part`
matches the entry.

### 4.39 The grammar of status tags

@req status-grammar=v1
@cites #{tag-words=v1, notation=v1, line-layout=v1}

This production gives the form of a status tag:

```
status-line  = indent ( %s"@deferred" / %s"@deprecated" / %s"@rejected" )
               rest
```

### 4.40 The grammar of `@extern`

@req extern-grammar=v1
@cites #{
    notation=v1, line-layout=v1, kind-words=v1, segments=v1,
    tag-words=v1,
}

This production gives the form of an `@extern` line:

```
extern-line  = indent %s"@extern" gap kind-word ":" part-name rest
```

### 4.41 The grammar of `@ack`

@req ack-grammar=v1
@cites #{
    notation=v1, line-layout=v1, segments=v1, characters=v1,
    tag-words=v1,
}

These productions give the form of an `@ack` line:

```
ack-line  = indent %s"@ack" gap slug [ gap subject ] gap hash *WSP
subject   = non-wsp [ *any-char non-wsp ]
non-wsp   = %x0-8 / %xA-1F / %x21-D7FF / %xE000-10FFFF
hash      = 8*64( %x30-39 / %x61-66 )
```

### 4.42 The grammar of inline citations

@req inline-grammar=v1
@cites #{
    destinations=v1, notation=v1, kind-words=v1, segments=v1,
    revisions=v1, external-ids=v1,
}

This production gives the form of the destination of an inline
citation:

```
inline-destination  = %s"sinter:" [ kind-word ":" ]
                      ( name "=" revision / external-ref )
```

### 4.43 The match of an input

@req input-matches=v1
@cites #{
    notation=v1, inputs=v1, characters=v1, continuation=v1,
    tag-lines=v1, destinations=v1, declaration-grammar=v1, tag-words=v1,
    citation-grammar=v1, status-grammar=v1, extern-grammar=v1,
    ack-grammar=v1, inline-grammar=v1, external-targets=v1,
    external-ids=v1, entries=v1, line-layout=v1, kind-words=v1,
}

A match of an input is a match of the text of a tag line, or of the
destination of an inline citation, by one of these productions:

- `declaration-line` for a declaration;
- `citation-line` for a citation;
- `status-line` for a status tag;
- `extern-line` for an `@extern` line;
- `ack-line` for an `@ack` line;
- `inline-destination` for the destination of an inline citation.

A match is a match of the input only when each of these texts that is
external matches `external-ref`, without its kind word and the `:`
after it when it starts with a kind word: the target of a declaration,
the target of an inline citation, and each entry of the match of a
citation.

### 4.44 Inputs with no match

@req reject-unmatched-inputs=v1
@cites #{
    external-namespaces=v1, result-list=v1, tag-words=v1,
    destinations=v1, notation=v1, external-ids=v1, external-targets=v1,
    input-matches=v1,
}

Under a binding of `external-namespaces` that it accepts, a conforming
parser must reject each declaration, citation, status tag, directive,
and inline citation that has no match.

### 4.45 Unique entries

@req reject-repeated-entries=v1
@cites #{
    external-namespaces=v1, result-list=v1, tag-words=v1, notation=v1,
    entries=v1, input-matches=v1,
}

Under a binding of `external-namespaces` that it accepts, a conforming
parser must reject a citation that has a match in which two entries
have the same name.

### 4.46 The link text of inline citations

@req reject-blank-link-text=v1
@cites #{
    external-namespaces=v1, result-list=v1, destinations=v1,
    plain-string-content=v1, link-text=v1, characters=v1,
    blank-characters=v1,
}

Under a binding of `external-namespaces` that it accepts, a conforming
parser must reject an inline citation when the plain string content of
its link text holds no character other than blank characters.

### 4.47 The tag word

@req give-tag-words=v1
@cites #{external-namespaces=v1, result-list=v1, tag-lines=v1}

Under a binding of `external-namespaces` that it accepts, a conforming
parser must give the tag word of each tag line as a value, with the
name "the tag word".

### 4.48 Values

@req give-values=v1
@cites #{
    external-namespaces=v1, result-list=v1, tag-words=v1,
    destinations=v1, inputs=v1, entries=v1, notation=v1, tag-lines=v1,
    characters=v1, ack-grammar=v1, link-text=v1, kind-words=v1,
    segments=v1, citation-grammar=v1, external-ids=v1, revisions=v1,
    line-layout=v1, input-matches=v1,
}

Under a binding of `external-namespaces` that it accepts, a conforming
parser must give these values for each declaration, citation, status
tag, directive, and inline citation that it accepts, each together with
its name in the first column of its table:

- each value of the first table whose second column describes the
  input;
- for a citation, one group for each entry, in the order of the
  entries, that holds each value of the second table whose second
  column describes the match of the entry;
- for each other input, each value of the second table whose second
  column describes the match of the input.

| name | input | value |
|---|---|---|
| the type of tag line | a tag line with a Sinter tag word | declaration, citation, status tag, or directive: the one that the tag line is |
| the inline description | a declaration, a citation, a status tag, or an `@extern` line | its inline description |
| the subject | an `@ack` line | the text that `subject` matches, or the empty text when the match holds no `subject` |
| the hash | an `@ack` line | the text that `hash` matches |
| the link text | an inline citation | its link text |

| name | match | value |
|---|---|---|
| the kind word | a match that holds `kind-word` | the text that `kind-word` matches |
| the slug | a match that holds `slug` | the text that `slug` matches |
| the slug | the match of a declaration with the tag word `@spec` whose target holds no `#` | the text that `segment` matches |
| the custom namespace | a match that holds `slug`, when the text that `slug` matches holds a `/` | the custom namespace of that text |
| the part name | a match that holds `part-name` | the text that `part-name` matches |
| every part | a match that holds `every-part` | no text |
| the namespace name | a match that holds `external-id` | the text that `namespace-name` matches in `external-id` |
| the id | a match that holds `external-id` | the text that `id-text` matches |
| the revision | a match that holds `revision` or `label` | the text that `revision` matches, or the text that `label` matches when the match holds no `revision` |

### 4.49 No other values

@req give-no-other-values=v1
@cites #{result-list=v1, inputs=v1, give-values=v1, give-tag-words=v1}

A conforming parser must give no value for an input other than the
values that the requirements `give-values` and `give-tag-words` state for
that input.

### 4.50 Results

@req give-results=v1
@cites #{
    result-list=v1, inputs=v1, tag-lines=v1, links=v1,
    external-namespaces=v1, tag-words=v1, destinations=v1,
    id-pattern-grammar=v1,
}

A conforming parser must give exactly one result for each input, and
only a result that this table lists for that input. For a line, a link,
and an image, this obligation holds under a binding of
`external-namespaces` that the parser accepts. The parser must give no
result for anything that is not an input.

| input | result |
|---|---|
| a line that is not a tag line | not a tag line |
| a tag line whose tag word is not a Sinter tag word | other tag word |
| a declaration, a citation, a status tag, or a directive | valid or invalid |
| a link or an image of a markdown document that is not an inline citation | not an inline citation |
| an inline citation | valid or invalid |
| an id pattern | valid or invalid |
| a binding of `external-namespaces` | valid or invalid |
| a pair of an id pattern and an id | fits or does not fit |

### 4.51 Acceptance

@req accept-inputs=v1
@cites #{
    result-list=v1, inputs=v1, tag-words=v1, destinations=v1,
    id-pattern-grammar=v1, external-namespaces=v1,
    reject-unmatched-id-patterns=v1, reject-reversed-ranges=v1,
    reject-large-counts=v1, reject-reversed-bounds=v1,
    reject-empty-id-fit=v1, reject-oversized-id-patterns=v1,
    reject-long-id-patterns=v1, reject-malformed-namespace-names=v1,
    reject-repeated-namespace-names=v1,
    reject-invalid-binding-patterns=v1, reject-unmatched-inputs=v1,
    reject-repeated-entries=v1, reject-blank-link-text=v1,
}

A conforming parser must accept each input that is a declaration, a
citation, a status tag, a directive, an inline citation, an id pattern,
or a binding of `external-namespaces`, unless one of these requirements
states that the parser must reject it: `reject-unmatched-id-patterns`,
`reject-reversed-ranges`, `reject-large-counts`, `reject-reversed-bounds`,
`reject-empty-id-fit`, `reject-oversized-id-patterns`, `reject-long-id-patterns`,
`reject-malformed-namespace-names`, `reject-repeated-namespace-names`, `reject-invalid-binding-patterns`,
`reject-unmatched-inputs`, `reject-repeated-entries`, and `reject-blank-link-text`. For a declaration,
a citation, a
status tag, a directive, and an inline citation, this obligation holds
under a binding of `external-namespaces` that the parser accepts.

## 5. Conformance

A parser conforms to this design when it meets every requirement of
section 4.

Each vector below gives an input and the result that a conforming
parser gives for it. These conventions apply:

- In sections 5.1, 5.2, and 5.3, the parser reads each input under a
  binding of `external-namespaces` with two pairs: `gh` with the id
  pattern `[1-9][0-9]*`, and `rfc` with the id pattern `[1-9][0-9]*`.
- In section 5.1, each row gives a line that a program gives to the
  parser alone: no line follows it.
- For a valid input, a row names every value that the parser gives,
  with two exceptions: the tag word of a tag line, and an inline
  description that is empty.
- For a citation with two or more entries, a row names the values of
  the tag line first, and then the values of each entry after
  "entry 1:", "entry 2:", and so on. For a citation with one entry, a
  row names the values of the entry and of the tag line together.
- For an input that is not valid, the parser gives no value, except the
  tag word of a tag line. A row of a tag line with another tag word
  names that tag word.
- The text after "invalid:" or "not an inline citation:" explains the
  result. A parser does not give it.

### 5.1 Tag lines

For the line `@cites gh/42`, the parser gives only the result of the
line. It gives no result for the id pattern `[1-9][0-9]*` of `gh`, and
no result for the pair of that id pattern and the id `42`, because
neither is an input.

| line | result |
|---|---|
| `@req size-limit=v2 A descriptor has at most 1 MiB.` | valid declaration: slug `size-limit`, revision `v2`, inline description `A descriptor has at most 1 MiB.` |
| `   @design identifiers=v1` | valid declaration: slug `identifiers`, revision `v1` |
| `@req`, a tab, and `size-limit=v2` | valid declaration: slug `size-limit`, revision `v2` |
| `see @req size-limit=v2` | not a tag line |
| `@param x The input.` | other tag word: `@param` |
| `@Req size-limit=v2` | other tag word: `@Req` |
| `@reqs size-limit=v2` | other tag word: `@reqs` |
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
| `@cites docs=v1; and more` | valid citation: slug `docs`, revision `v1;`, inline description `and more` |
| `@cites docs=v1, and more` | invalid: a label holds no `,` |
| `@cites docs=v{1}` | invalid: a label holds no `{` |
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
| `@cites gh/4,2` | invalid: the target is external, and an id holds no `,` |
| `@cites {#notation=v1, #characters=v1, docs#size=v2}` | valid citation: entry 1: part name `notation`, revision `v1`; entry 2: part name `characters`, revision `v1`; entry 3: slug `docs`, part name `size`, revision `v2` |
| `@cites {docs=v1}` | valid citation: slug `docs`, revision `v1` |
| `@cites { docs=v1 ,spec:docs#size=* } See both.` | valid citation: inline description `See both.`; entry 1: slug `docs`, revision `v1`; entry 2: kind word `spec`, slug `docs`, part name `size`, revision `*` |
| `@cites {gh/42, rfc/8259#section-6}` | valid citation: entry 1: namespace name `gh`, id `42`; entry 2: namespace name `rfc`, id `8259`, part name `section-6` |
| `@refines {#size=v2, gh/42}` | valid citation: entry 1: part name `size`, revision `v2`; entry 2: namespace name `gh`, id `42` |
| `@supersedes {docs=v3#*, other#size=v2}` | valid citation: entry 1: slug `docs`, revision `v3`, every part; entry 2: slug `other`, part name `size`, revision `v2` |
| `@cites packs#{size=v1, descriptor=v2}` | valid citation: entry 1: slug `packs`, part name `size`, revision `v1`; entry 2: slug `packs`, part name `descriptor`, revision `v2` |
| `@cites req:packs#{size=v1, descriptor=*}` | valid citation: entry 1: kind word `req`, slug `packs`, part name `size`, revision `v1`; entry 2: kind word `req`, slug `packs`, part name `descriptor`, revision `*` |
| `@cites #{notation=v1, characters=v1}` | valid citation: entry 1: part name `notation`, revision `v1`; entry 2: part name `characters`, revision `v1` |
| `@cites {identifiers#{segments=v1, notation=v1}, gh/42}` | valid citation: entry 1: slug `identifiers`, part name `segments`, revision `v1`; entry 2: slug `identifiers`, part name `notation`, revision `v1`; entry 3: namespace name `gh`, id `42` |
| `@verifies billing/auth#{lockout=v2}` | valid citation: slug `billing/auth`, custom namespace `billing`, part name `lockout`, revision `v2` |
| `@cites {}` | invalid: a target list holds one single target or scoped list at least |
| `@cites {docs=v1,}` | valid citation: slug `docs`, revision `v1` |
| `@cites packs#{size=v1, descriptor=v2,}` | valid citation: entry 1: slug `packs`, part name `size`, revision `v1`; entry 2: slug `packs`, part name `descriptor`, revision `v2` |
| `@cites {docs=v1,,}` | invalid: a single target or a scoped list stands between each two `,` |
| `@cites {,}` | invalid: a target list holds one single target or scoped list at least |
| `@cites {docs=v1 docs#size=v2}` | invalid: a `,` separates two single targets |
| `@cites {#a=v1, req:#a=v2}` | invalid: two entries have the name `#a` |
| `@cites packs#{size=v1, size=v2}` | invalid: two entries have the name `packs#size` |
| `@cites {packs#size=v1, packs#{size=v2}}` | invalid: two entries have the name `packs#size` |
| `@cites {docs=v1` | invalid: no line follows to close the target list |
| `@cites {docs=v1}x` | invalid: no space or tab after the `}` |
| `@cites {{docs=v1}}` | invalid: a target list holds no target list |
| `@cites packs#{size=v1, {docs=v1}}` | invalid: a scoped list holds no target list |
| `@cites packs#{req:size=v1}` | invalid: a scoped list holds no kind word between its braces |
| `@cites packs#{size}` | invalid: each part name of a scoped list has `=` and a revision |
| `@cites packs#{}` | invalid: a scoped list holds one part name at least |
| `@refines {docs=*}` | invalid: only an entry of `@cites` carries `*` |
| `@refines packs#{size=*}` | invalid: only an entry of `@cites` carries `*` |
| `@verifies {gh/42=v1}` | invalid: the entry is external, and an id holds no `=` |
| `@cites gh#{size=v1}` | invalid: the entry `gh#size=v1` is external, and no `/` and id follow `gh` |
| `@cites {docs=v3#*}` | invalid: only `@supersedes` takes an every-part target |
| `@supersedes docs#{*=v3}` | invalid: `*` is not a part name |
| `@design {docs=v1}` | invalid: only a citation has a target list |
| `@req packs#{size=v1}` | invalid: only a citation has a scoped list |
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

### 5.2 Citations over several lines

Each row gives the lines that a program gives to the parser, in their
order, and no other line. A citation and its continuation lines are one
input, and a continuation line gets no result of its own. When a row
holds another input after the citation, its result names that input.

| lines | result |
|---|---|
| `@cites {`, `#notation=v1,`, `#characters=v1`, and `}` | valid citation: entry 1: part name `notation`, revision `v1`; entry 2: part name `characters`, revision `v1` |
| `@cites #{`, four spaces and `notation=v1, characters=v1,`, four spaces and `segments=v1,`, and `}` | valid citation: entry 1: part name `notation`, revision `v1`; entry 2: part name `characters`, revision `v1`; entry 3: part name `segments`, revision `v1` |
| `@cites {docs=v1,`, `docs#size=v2,`, and `} The docs.` | valid citation: inline description `The docs.`; entry 1: slug `docs`, revision `v1`; entry 2: slug `docs`, part name `size`, revision `v2` |
| `@cites {identifiers#{`, `segments=v1,`, and `notation=v1}, gh/42}` | valid citation: entry 1: slug `identifiers`, part name `segments`, revision `v1`; entry 2: slug `identifiers`, part name `notation`, revision `v1`; entry 3: namespace name `gh`, id `42` |
| `@cites {`, an empty line, and `docs=v1}` | invalid: an empty line follows before the closing `}`; then the empty line is an input of its own: not a tag line; then the line `docs=v1}` is an input of its own: not a tag line |
| `@cites {`, a line of two spaces, and `docs=v1}` | invalid: an empty line follows before the closing `}`; then the empty line is an input of its own: not a tag line; then the line `docs=v1}` is an input of its own: not a tag line |
| `@cites {docs` and `=v1}` | invalid: an entry does not break across lines |
| `@cites {docs=v1,` | invalid: no line follows to close the target list |
| `@cites {docs=v1,` and `@req size-limit=v2` | invalid: a tag line follows before the closing `}`; then the line `@req size-limit=v2` is an input of its own: valid declaration: slug `size-limit`, revision `v2` |
| `@cites` and `{docs=v1}` | invalid: no target; then the line `{docs=v1}` is an input of its own: not a tag line |
| `@cites docs=v1 {` and `x}` | valid citation: slug `docs`, revision `v1`, inline description `{`; then the line `x}` is an input of its own: not a tag line |

### 5.3 Inline citations

Each row gives a markdown document that holds one link or one image,
or a link inside the link text of another link. When a row holds a link
inside the link text of another link, the result is the result of the
outer link.

| document | result |
|---|---|
| `[the size limit](sinter:req:packs#size-limit=v2)` | valid: link text `the size limit`, kind word `req`, slug `packs`, part name `size-limit`, revision `v2` |
| `[the size limit](sinter:req:packs#size-limit)` | invalid: no revision |
| `[any revision](sinter:packs#size-limit=*)` | valid: link text `any revision`, slug `packs`, part name `size-limit`, revision `*` |
| `[](sinter:packs#size-limit=v2)` | invalid: the plain string content of the link text is empty |
| `[ ](sinter:packs#size-limit=v2)` | invalid: the plain string content of the link text is one space |
| `[&nbsp;](sinter:packs#size-limit=v2)` | invalid: the plain string content of the link text is U+00A0, a blank character |
| `[<!-- -->](sinter:packs#size-limit=v2)` | invalid: raw HTML gives no plain string content |
| `> [`, a line feed, and `> ](sinter:packs#size-limit=v2)` | invalid: the plain string content of the link text is a line feed |
| `> [the`, a line feed, and `> limit](sinter:packs#size-limit=v2)` | valid: link text `the`, a line feed, and `limit`, slug `packs`, part name `size-limit`, revision `v2` |
| `[the`, a line feed, three spaces, and `limit](sinter:packs#size-limit=v2)` | valid: link text `the`, a line feed, and `limit`, slug `packs`, part name `size-limit`, revision `v2` |
| `[<https://example.com>](sinter:packs#size-limit=v2)` | valid: link text `<https://example.com>`, slug `packs`, part name `size-limit`, revision `v2` |
| `[`, U+200B, and `](sinter:packs#size-limit=v2)` | invalid: the plain string content of the link text is U+200B, a blank character |
| `[`, U+200C, and `](sinter:packs#size-limit=v2)` | invalid: the plain string content of the link text is U+200C, a blank character |
| `[`, U+200D, and `](sinter:packs#size-limit=v2)` | invalid: the plain string content of the link text is U+200D, a blank character |
| `[`, U+2060, and `](sinter:packs#size-limit=v2)` | invalid: the plain string content of the link text is U+2060, a blank character |
| `[`, U+FEFF, and `](sinter:packs#size-limit=v2)` | invalid: the plain string content of the link text is U+FEFF, a blank character |
| `[`, U+200B, and `x](sinter:packs#size-limit=v2)` | valid: link text U+200B and `x`, slug `packs`, part name `size-limit`, revision `v2` |
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
| `[x](sinter:{docs=v1})` | invalid: an inline citation cites one target |
| `[x](sinter:packs#{size=v1})` | invalid: an inline citation cites one target |
| `[x](Sinter:req:packs#size-limit=v2)` | not an inline citation: the destination does not start with `sinter:` |
| `![x](sinter:packs#size-limit=v2)` | not an inline citation: an image is not a link |

### 5.4 Id patterns

Each item gives an id pattern, as an input, and its result. For a
valid id pattern, it also gives ids that fit it and ids that do not fit
it. For the pair of the id pattern and an id that fits it, the parser
gives the result "fits". For the pair of the id pattern and an id that
does not fit it, the parser gives the result "does not fit".

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
- `[0-9]+,[0-9]+`: invalid: `,` is not a literal.
- `[0-9,]+`: invalid: `,` is not a member of a character class.
- `[a-z{]+`: invalid: `{` is not a member of a character class.
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

### 5.5 Bindings of `external-namespaces`

| binding | result |
|---|---|
| the empty set | valid |
| `gh` with `[1-9][0-9]*` | valid |
| `my-tracker` with `[A-Z]+-[1-9][0-9]*` | valid |
| `GH` with `[1-9][0-9]*` | invalid: `GH` does not match `namespace-name` |
| `my--tracker` with `[1-9][0-9]*` | invalid: `my--tracker` does not match `namespace-name` |
| `9ns` with `[1-9][0-9]*` | invalid: `9ns` does not match `namespace-name` |
| `gh` with `[1-9][0-9]*`, and `gh` with `[a-z]+` | invalid: two pairs with the namespace name `gh` |
| `gh` with `[0-9]*` | invalid: the empty id fits the id pattern; the id pattern `[0-9]*` gets no result of its own, because it is not an input |
