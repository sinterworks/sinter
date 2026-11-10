<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Identifiers
@design identifiers=v1
@cites text=v1
@cites rfc/5234
@cites rfc/7405
@cites commonmark/0.31.2
Specifies the grammar of tags, identifiers, and links as used in Sinter and requirements for conforming programs.

A tag line starts, after any spaces and tabs, with a tag word such as
`@req`. A declaration, such as `@req size-limit=v2`, is a tag line that
yields a name and a revision. Only a declaration with the tag word
`@term` can leave out the revision. A citation, such as
`@cites packs#size-limit=v2`, is a tag line that yields what it cites: a
name and a revision, or an external id. A citation can also cite several
things in a target list or a scoped list, such as
`@cites {#notation=v1, gh/42}` and
`@cites packs#{size=v1, descriptor=v2}`. A vector selection, such as
`[12]` in `@verifies packs#descriptor[12]=v1`, can follow the name in a
single target of `@cites` or `@verifies`. An inline citation is a link,
written within a block of text, that cites in the same way.

The productions in section 4 are written in ABNF, the notation of
RFC 5234. A production, such as `slug = segment *( "/" segment )`, gives
the texts that its rule name, here `slug`, matches. In a production, `/`
separates two alternatives. The quoted string `"/"` is the character
`/`. `( )` makes the elements between them one element, and `[ ]` makes
an element optional. `*` repeats the element after it any number of
times, zero included, `1*` repeats it one or more times, and `8*64`
repeats it from 8 to 64 times. `%x41` is the character U+0041, and
`%x30-39` is any one character from U+0030 to U+0039. In RFC 5234, a
quoted string such as `"a"` matches its letters in either case. RFC 7405
adds the form `%s"…"`, which matches its letters only in the same case,
as in `%s"@req"`. The productions also use four core rules of RFC 5234:
`ALPHA` is an ASCII letter, `DIGIT` is an ASCII digit, `WSP` is a space
or a tab, and `LF` is a line feed.

From Text and notation (`text`), the design takes characters, texts,
runs, bodies, lines, and line numbers; code spans; decimal numerals and
hex digits; productions and rule names; and what a conforming program,
an input, and a result are. From CommonMark 0.31.2, the design takes
what a link is, its destination and its link text, the inline elements
of a link text, and the Unicode whitespace characters.

## 1. Glossary

| term | meaning |
|---|---|
| [conforming program](sinter:text#conforming-program=v1) | a program, or a part of a program, that meets every requirement of a design |
| [production](sinter:text#production=v1) | a rule of ABNF, such as `slug = segment *( "/" segment )`, which gives the texts that its rule name, here `slug`, matches |
| [character](sinter:text#character=v1) | one Unicode scalar value: a code point that is not from U+D800 to U+DFFF |
| [text](sinter:text#text=v1) | a finite sequence of characters |
| [run](sinter:text#run=v1) | a part of a text between two of its boundaries, whose characters keep their places in the text |
| [line](sinter:text#line=v1) | a run of the body of a text that the line endings of the text divide from the other parts; a line holds no line feed, a byte order mark is on no line, and an empty run at the end of the body is no line |
| printable ASCII character | a character from `!` to `~`; a space is not one |
| [tag line](sinter:#tag-line=v1) | a line whose first character, after the spaces and tabs at its start, is `@` |
| [tag word](sinter:#tag-word=v1) | the `@` that starts a tag line after its spaces and tabs, with the longest run of ASCII letters, ASCII digits, and `-` right after it, such as `@req` |
| [Sinter tag word](sinter:#sinter-tag-word=v1) | one of the sixteen tag words of Sinter, such as `@req` and `@cites` |
| [declaration](sinter:#declaration=v1) | a tag line whose tag word is `@decision`, `@design`, `@finding-class`, `@req`, `@spec`, or `@term`, such as `@req size-limit=v2` |
| [citation](sinter:#citation=v1) | a tag line whose tag word is `@cites`, `@refines`, `@satisfies`, `@supersedes`, or `@verifies`, such as `@cites packs#size-limit=v2` |
| [status tag](sinter:#status-tag=v1) | a tag line with `@deferred`, `@deprecated`, or `@rejected`, which has no target |
| [directive](sinter:#directive=v1) | a tag line with `@ack` or `@extern`, each of which has a form of its own |
| [`@extern` line](sinter:#directive=v1) | a directive with the tag word `@extern`, such as `@extern spec:descriptor`; the production `extern-line` gives its [form](sinter:#extern-line=v1) |
| [`@ack` line](sinter:#directive=v1) | a directive with the tag word `@ack`, such as `@ack retired docs#size=v2 3f2a9c1d`; the productions of `ack-line` give its [form](sinter:#ack-line=v1) |
| [continuation line](sinter:#continuation-line=v1) | a line that continues the target of a citation on a line before it, while a count from the start of the target has passed more `{` than `}` |
| blank line | a line that is empty or holds only spaces and tabs |
| [text of a tag line](sinter:#tag-line-text=v1) | the text of its line, and, for a citation, the texts of its continuation lines after it, each after a line feed and without the spaces and tabs at its start |
| [link](sinter:#link=v1) | an inline link, a reference link, or an autolink of a markdown document, as CommonMark 0.31.2 defines them; an image is not a link; the markdown document of a text is the text of its body |
| [destination](sinter:#destination=v1) | the address of a link, such as `sinter:packs#size-limit=v2` in `[the limit](sinter:packs#size-limit=v2)` |
| [link text](sinter:#link-text=v1) | the text between the brackets of an inline link or a reference link, in the raw content that holds the link, such as `the limit` in `[the limit](sinter:packs#size-limit=v2)`; an autolink has no brackets, and its link text is its text between `<` and `>` |
| raw content | the lines of a paragraph or a heading, as CommonMark 0.31.2 gives them, without the underline of a setext heading, without the markers of block quotes, list items, and ATX headings, and without the spaces and tabs at the start of each line; then joined by line feeds, and without the spaces and tabs at the end |
| [inline citation](sinter:#inline-citation=v1) | a link whose destination starts with `sinter:` |
| [target](sinter:#target=v1) | the text after the tag word of a declaration, a citation, or an `@extern` line and the spaces and tabs after the tag word, up to the first space or tab before which the target holds no more `{` than `}`, or up to the end of the text of the tag line; also the destination of an inline citation after `sinter:` |
| [inline description](sinter:#inline-description=v1) | the text of a tag line after its target, or after the tag word of a status tag, without the spaces and tabs at its start; an `@ack` line has none |
| [segment](sinter:#segment=v1) | a text of ASCII letters and ASCII digits, with one `-`, `_`, or `.` at most between two of them, such as `size-limit` |
| [slug](sinter:#slug=v1) | one segment, or several segments joined by `/`, such as `packs` or `billing/auth` |
| custom namespace | the text of a slug before its last `/`, such as `billing` in `billing/auth` and `a/b` in `a/b/c` |
| [part name](sinter:#part-name=v1) | the segment after `#` in a name, such as `descriptor` in `packs#descriptor`; also the segment after the `:` in the target of an `@extern` line, such as `descriptor` in `@extern spec:descriptor`, which has no `#` |
| [full name](sinter:#full-name=v1) | a slug, `#`, and a part name, such as `packs#descriptor` |
| [name](sinter:#name=v1) | a slug, a full name, or `#` and a part name |
| [kind word](sinter:#kind-word=v1) | one of six words, such as `req`, that can stand with a `:` at the start of a target, as in `req:packs#size-limit=v2` |
| [label](sinter:#label=v1) | a text of printable ASCII characters other than `/`, `#`, `@`, `*`, `=`, `,`, `{`, `}`, `[`, and `]`, such as `v2` |
| [revision](sinter:#revision=v1) | a label, or `*`, which stands for any label; in a target it follows a name, or a name and a vector selection, and `=`, as `v2` in `docs#size=v2` and `v3` in `docs=v3#*` |
| every-part target | a slug, `=`, a label, and `#*`, such as `docs=v3#*` |
| [vector selection](sinter:#vector-selection=v1) | `[`, a vector number, and `]`; or `[`, a group name, `]`, and `[*]`; or `[*]`; it can follow the name in a single target of `@cites` or `@verifies`, such as `[12]` in `packs#descriptor[12]=v1`, and it gives a vector number, a group name and every vector, or every vector |
| vector number | the decimal numeral of a vector selection, such as `12` in `[12]` |
| group name | the segment of a vector selection before `[*]`, such as `offsets` in `[offsets][*]` |
| scoped list | an optional kind word and `:`, an optional slug, `#{`, part names, each with an optional vector selection and with its revision, separated by `,`, and `}`, such as `packs#{size=v1, descriptor=v2}`, which stands for `packs#size=v1` and `packs#descriptor=v2` |
| target list | `{`, one or more single targets or scoped lists separated by `,`, and `}`: a target of a citation, such as `{#notation=v1, gh/42}` |
| single target | a target that is neither a target list nor a scoped list, such as `packs#size=v1` |
| [citation entry](sinter:#citation-entry=v1) | a single target of a citation, or a single target for which a part of a scoped list stands |
| parameter | a name, such as `external-namespaces`, for which a program gives a binding, under which a conforming program reads lines, links, and images |
| [binding](sinter:#binding=v1) | what a program gives for the parameter `external-namespaces`: a finite set of pairs, each pair of a binding with a namespace name and an id pattern |
| [external namespace](sinter:#external-namespace=v1) | a pair of a binding, with its namespace name and its id pattern; the external namespaces of a line, a link, or an image are those of the binding under which a conforming program reads it |
| [namespace name](sinter:#namespace-name=v1) | the text of a pair of a binding that names its external namespace, such as `gh`; it can match the production `namespace-name` or not |
| [external id](sinter:#external-id=v1) | a namespace name, `/`, and an id, such as `gh/42` |
| [id](sinter:#id=v1) | a text that a conforming program tests against an id pattern, such as `42` in `gh/42` |
| [id pattern](sinter:#id-pattern=v1) | a text that a conforming program takes as a pattern, on its own or in a binding of `external-namespaces`, and against which it tests ids; it is an id pattern whether or not it matches the production `pattern` |
| class member | one element of a character class of an id pattern: a character, or a range such as `0-9` |
| [fit](sinter:#fit=v1) | an id fits an id pattern when the id has the form that the id pattern gives, such as `42` for `[1-9][0-9]*` |
| [size of an id pattern](sinter:#id-pattern-size=v1) | the number of the literals and character classes of an id pattern when each quantifier is written out as copies of its element; `?`, `*`, and `+` count as one copy |
| head | the text of a target or a citation entry without its kind word and the `:` after it, up to its first `#`, `=`, or `[` |
| [external target](sinter:#external-target=v1) | the target of a declaration or of an inline citation, or a citation entry, whose head starts with the namespace name of an external namespace of its tag line or its inline citation, followed by `/` or by the end of the head |
| [plain string content](sinter:#plain-string-content=v1) | the text that a link text shows without its markup, such as `the limit` for `*the* limit` |
| [blank character](sinter:#blank-character=v1) | a character that shows no text: a Unicode whitespace character of CommonMark 0.31.2, such as a space, a tab, a line feed, or U+00A0, the no-break space; or one of U+200B, U+200C, U+200D, U+2060, and U+FEFF, such as U+200B, the zero width space |
| [input](sinter:#input=v1) | a line of a text that a conforming program reads, other than a continuation line, because a citation and its continuation lines are one input; a link or an image of the markdown document of such a text; an id pattern that the program takes on its own or in a pair of an id pattern and an id, but not an id pattern of a binding; a binding of `external-namespaces` that the program takes or under which it reads; a pair of an id pattern and an id that the program takes, when the program accepts the id pattern of that pair |
| [match of an input](sinter:#input-match=v1) | a match of the text of a tag line or of the destination of an inline citation by the production for its kind of tag line or by `inline-destination`, in which the target of a declaration is not an external target, and each other external target matches `external-ref` |
| [result](sinter:text#result=v1) | what a conforming program gives for an input, such as "valid", "not a tag line", or "fits" |
| accept, reject | to give the result "valid" for an input, and to give the result "invalid" for an input |
| [value](sinter:#value=v1) | a text or a fact that a conforming program gives for an input together with its result, under a value name, such as the tag word of a tag line under the value name "the tag word" |

## 2. The written forms

### 2.1 Tag lines and tag words

A conforming program reads the lines of texts. A line holds no line
feed: the line feeds of a text, each with the carriage return right
before it when there is one, divide the text into lines, and a U+FEFF
at the start of a text is on no line. A line is a tag line when its
first character, after the spaces and tabs at its start, is `@`. Every
such line is a tag line, whatever its tag word is.

The tag word of a tag line is its `@` and the longest sequence of ASCII
letters, ASCII digits, and `-` right after that `@`. The sequence can be
empty.

| line | tag word |
|---|---|
| `@req size-limit=v2` | `@req` |
| `   @finding-class late-fee=v1` | `@finding-class` |
| `@foo-bar: text` | `@foo-bar` |
| `@param x The input.` | `@param` |
| `@ alone` | `@` |
| `see @req size-limit=v2` | none: the line is not a tag line |

Sinter has sixteen tag words. A tag word is a Sinter tag word only when
it is the same text as one of them, so `@Req` and `@reqs` are not
Sinter tag words. For a tag line whose tag word is not a Sinter tag
word, a conforming program gives the result "other tag word" and the
tag word, and nothing more.

A Sinter tag word makes its tag line a declaration, a citation, a
status tag, or a directive. The tag word also sets the form of the line
and of its target:

| tag word | tag line | target | revision |
|---|---|---|---|
| `@decision`, `@design`, `@finding-class` | declaration | a slug | a label |
| `@req` | declaration | a slug or a full name | a label |
| `@spec` | declaration | a slug of one segment, or a full name | a label |
| `@term` | declaration | a slug or a full name | a label, or none |
| `@cites` | citation | an optional kind word and `:`, then a name with an optional vector selection, or an external id with an optional `#` and part name | a label or `*`; none after an external id |
| `@verifies` | citation | an optional kind word and `:`, then a name with an optional vector selection, or an external id with an optional `#` and part name | a label; none after an external id |
| `@refines`, `@satisfies` | citation | an optional kind word and `:`, then a name, or an external id with an optional `#` and part name | a label; none after an external id |
| `@supersedes` | citation | an optional kind word and `:`, then a name, or an external id with an optional `#` and part name; or an every-part target | a label; none after an external id |
| `@deferred`, `@deprecated`, `@rejected` | status tag | none | none |
| `@extern` | directive | a kind word, `:`, and a part name | none |
| `@ack` | directive | none; a form of its own (section 2.8) | none |

In a declaration, a citation, and an `@extern` line, one or more spaces
or tabs follow the tag word, and then the target. The target ends at the
next space or tab, or at the end of the line. The target of a citation
can also be a target list or a scoped list, which can hold spaces, tabs,
and line feeds of the text of the citation between its braces, and which
can continue on the lines that follow (section 2.7). The inline
description is the text after the target, without the spaces and tabs at
its start. A status tag has no target, and its inline description is the
text after its tag word, without the spaces and tabs at its start.
Example: in `@req size-limit=v2 A descriptor has at most 1 MiB.`, the
target is `size-limit=v2`, and the inline description is
`A descriptor has at most 1 MiB.`.

In a valid tag line, the character right after a Sinter tag word is a
space or a tab, or the line ends there. So `@req:size-limit=v2` and
`@deprecated.` are invalid.

### 2.2 Names

A segment is a text of ASCII letters and ASCII digits, with one `-`,
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

A conforming program gives each name with its case unchanged, so
`Auth-Lockout` and `auth-lockout` stay two different texts.

### 2.3 Kind words

The six kind words are `decision`, `design`, `finding-class`, `req`,
`spec`, and `term`. A kind word stands at the start of a target, with a
`:` after it: `req:packs#size-limit=v2`, `spec:rfc/8259`.

A single target of a citation, a scoped list, and the target of an
inline citation can start with a kind word. The target of `@extern`
always starts with one. The target of a declaration holds no kind word,
and an every-part target holds none. A name holds no `:`. So the target
`plan:upkeep=*` is invalid: `plan` is not a kind word, and `plan:upkeep`
is not a slug.

### 2.4 Revisions

A revision is a label or `*`. A label is a text of printable ASCII
characters other than `/`, `#`, `@`, `*`, `=`, `,`, `{`, `}`, `[`, and
`]`, such as `v2`, `2026-11`, `v1.2.0`, or `rc1`. `*` stands for any
label.

A revision follows a name, or a name and a vector selection (section
2.6), after `=`. A single target (section 2.7) carries one revision at
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
a revision, except an external target and the target of `@term`. The
target of `@term` carries a revision or none, so `@term segment=v1` and
`@term invoice` are both valid. The revision of a declaration is a
label. The target of `@cites` and the target of an inline citation
carry a label or `*`. The target of a citation whose tag word is
`@refines`, `@satisfies`, `@supersedes`, or `@verifies` carries a
label. The target of `@extern` and an `@ack` line carry no revision.

A revision has no default. So a declaration other than `@term`, a
citation, or an inline citation whose target is not external and
carries no revision is invalid. For example, `@cites billing/auth` and
`@design billing/auth` are invalid: neither target carries a revision.

The target ends at the first space or tab, so in
`@cites docs=v1; and more` the label is `v1;`. A label holds no `=`,
`,`, `{`, `}`, `[`, or `]`, so `@cites docs=v=1` and
`@cites docs=v1, and more` are invalid.

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
such as `gh/42`. The id is a text of printable ASCII characters other
than `#`, `/`, `=`, `@`, `,`, `{`, `}`, `[`, and `]`, and it fits the id
pattern of the external namespace. An external id allows `#` and a part
name after it, as in `rfc/8259#section-6`. An external id carries no
revision.

One rule decides whether the target of a declaration, a citation, or an
inline citation holds an external id. The head of the target is its
text after its kind word and the `:` after the kind word, and before
its first `#`, `=`, or `[`. When the head starts with a namespace name,
followed by `/` or by the end of the head, the target is an external
target. A conforming program reads an external target only as an
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
- `@cites gh[3]=v1` is invalid: its head is `gh`, so the target is
  external, and no `/` and id follow `gh`.
- `@design gh=v1`, `@term gh`, and `@term gh/42` are invalid, because
  the target is external, and the target of a declaration is never an
  external id.
- `@supersedes gh/42#*` is invalid, because the target is external and
  `*` is not a part name.

### 2.6 Vector selections

A vector selection can follow the name in a single target of `@cites` or
`@verifies`, before the `=` and the revision. A vector selection gives
one of these: a vector number; a group name and every vector; or every
vector:

| target | name | vector selection |
|---|---|---|
| `packs#descriptor[12]=v1` | the full name `packs#descriptor` | the vector number `12` |
| `packs#descriptor[offsets][*]=v2` | the full name `packs#descriptor` | the group name `offsets`, and every vector |
| `packs#descriptor[*]=v3` | the full name `packs#descriptor` | every vector |
| `packs[37]=v1` | the slug `packs` | the vector number `37` |
| `#descriptor[12]=v1` | `#` and the part name `descriptor` | the vector number `12` |

A vector number is a decimal numeral, such as `12` or `0`, so `[012]` is
not a vector selection. A group name is a segment, such as `offsets`. A
group name alone is not a vector selection, so
`@cites packs#descriptor[offsets]=v2` is invalid. The revision follows
the vector selection, and it follows the rules of its tag word: a label
or `*` for `@cites`, and a label for `@verifies`.

Only `@cites` and `@verifies` allow a vector selection, so
`@refines packs#descriptor[12]=v1` is invalid. A declaration and an
external id allow none, so `@spec descriptor[12]=v1` and
`@cites gh/42[3]` are invalid. A name, a label, and an id hold no `[`
and no `]`, so `@cites packs#descriptor=v1[12]` is invalid.

### 2.7 Target lists and scoped lists

A citation can cite several things on one line. Its target can be a
target list, a scoped list, or a target list that holds scoped lists.

A target list is `{`, one or more single targets or scoped lists
separated by `,`, and `}`, such as `{#notation=v1, gh/42}`. A single
target is a target of the forms of sections 2.1 to 2.6: a target that
is neither a target list nor a scoped list.

A scoped list is an optional kind word and `:`, an optional slug, `#{`,
one or more parts separated by `,`, and `}`, such as
`packs#{size=v1, descriptor=v2}`. Each part is a part name, an optional
vector selection, `=`, and a revision. Each part of a scoped list
stands for a single target: the kind word and the `:` of the scoped
list, its slug, `#`, and the part. So
`req:packs#{size=v1, descriptor=v2}` stands for `req:packs#size=v1` and
`req:packs#descriptor=v2`, and
`@verifies packs#{descriptor[12]=v1, size[*]=v2}` stands for
`packs#descriptor[12]=v1` and `packs#size[*]=v2`. A scoped list with no
slug, such as `#{notation=v1, characters=v1}`, stands for
`#notation=v1` and `#characters=v1`. A scoped list holds no kind word
between its braces, and it holds no target list.

Spaces and tabs can stand after each `{`, before and after each `,`, and
before each `}`. A space or a tab before which the target holds more `{`
than `}` does not end the target. One `,` can also stand right before a
`}`, so `{docs=v1, docs#size=v2,}` and `packs#{size=v1,}` are valid.
After the target, the line ends, or one or more spaces or tabs and an
inline description follow. Example: in
`@cites {#notation=v1, packs#{size=v1, descriptor=v2}} The limits.`, the
inline description is `The limits.`.

A target list or a scoped list can continue over the lines that follow
its citation. When a space or a tab follows the tag word of a citation,
a count goes through the line from the start of the target, and it keeps
the number of `{` and the number of `}` that it has passed. When the
line ends and the count has passed more `{` than `}`, the next line
continues the target, and the count goes on through that line. The lines
continue in this way up to the line on which the count comes to a space
or a tab, or to the end of the line, and has passed no more `{` than
`}`. Each of these lines is a continuation line of the citation, and the
spaces and tabs at its start do not count. In the text of the citation,
a line feed comes before each continuation line. A line feed of the text
of a citation counts as a space or a tab between the braces: in a valid
citation, it stands only where `list-space` stands in the production
`citation-line`, which is after the `{` of a target list or a scoped
list, before and after each `,` between its braces, and before its `}`.
So a citation entry does not break across lines. After the target, the
rest of the last line of the citation can hold an inline description.

Example, with the lines written as in the rows of section 6.2: the lines
`@cites #{`; a space written 4 times, `notation=v1, characters=v1,`; a
space written 4 times, `segments=v1,`; and `}` are one citation with the
citation entries `#notation=v1`, `#characters=v1`, and `#segments=v1`. A
tag line and a blank line, a line that holds nothing or only spaces and
tabs, are never continuation lines. When the count comes to the end of a
line and has passed more `{` than `}`, and no line follows, or a tag
line or a blank line follows, the citation is invalid, and the line that
follows is an input of its own. A blank line is not a line of blank
characters (section 2.9): a line that holds U+00A0 is not a blank line.

The citation entries of a citation are its single targets and the
single targets for which the parts of its scoped lists stand, in their
order. A citation whose target is a single target has one citation
entry: its target. Each citation entry follows the rules of a single
target of the tag word of its citation:

- A citation entry of `@cites` carries a label or `*`. A citation entry
  of `@refines`, `@satisfies`, `@supersedes`, or `@verifies` carries a
  label.
- A citation entry that is an external id carries no revision. The rule
  of external targets (section 2.5) applies to each citation entry. So
  under a binding with the external namespace `gh`,
  `@cites gh#{size=v1}` is invalid: it stands for `gh#size=v1`, whose
  head is `gh`.
- Only a single target of `@supersedes` can be an every-part target. A
  scoped list stands for no every-part target.
- Only a citation entry of `@cites` or `@verifies` can hold a vector
  selection.

The entry name of a citation entry is its slug, its full name, its `#`
and part name, or its external id with its `#` and part name. The entry
name of an every-part target is its slug. No two citation entries of a
citation have the same entry name and the same vector selection,
whatever their kind words and revisions. The vector selection of a
citation entry that holds none is the empty text. So
`@cites {docs=v1, docs#size=v2}`,
`@cites {identifiers#{segments=v1, notation=v1}, gh/42}`, and
`@cites {packs#descriptor[12]=v1, packs#descriptor[13]=v1}` are valid,
and these citations are invalid when no line follows them:

- `@cites {}`, because a target list holds one single target or scoped
  list at least;
- `@cites {docs=v1,,}`, because a single target or a scoped list stands
  between each two `,`;
- `@cites {docs=v1 docs#size=v2}`, because a `,` separates two single
  targets;
- `@cites {#a=v1, req:#a=v2}`, because its two citation entries have
  the entry name `#a` and no vector selection;
- `@cites {packs#size=v1, packs#{size=v2}}`, because its two citation
  entries have the entry name `packs#size` and no vector selection;
- `@supersedes {docs=v3#*, docs=v1}`, because its two citation entries
  have the entry name `docs` and no vector selection;
- `@cites {packs#descriptor[12]=v1, packs#descriptor[12]=v2}`, because
  its two citation entries have the entry name `packs#descriptor` and
  the vector selection `[12]`;
- `@refines packs#{size=*}`, because only a citation entry of `@cites`
  carries `*`;
- `@cites {{docs=v1}}`, because a target list holds no target list;
- `@cites {docs=v1,`, because no line follows to close the target list;
- `@design {docs=v1}`, because only a citation has a target list.

An inline citation cites one target, so `[x](sinter:{docs=v1})` and
`[x](sinter:packs#{size=v1})` are invalid.

For a valid citation, a conforming program gives the values of each
citation entry, apart from the values of the other citation entries, in
the order of the citation entries. It gives the tag word and the inline
description of the line once.

### 2.8 The directives `@extern` and `@ack`

The target of `@extern` is a kind word, `:`, and a part name, such as
`spec:descriptor`. It holds no `#`, so no slug comes before the part
name. It holds no revision.

An `@ack` line holds two or more runs of characters other than spaces
and tabs after `@ack`, with spaces or tabs between them:

- The first is a slug.
- The last is the **hash prefix**: from 8 to 64 hex digits, `0` to `9`
  and `a` to `f`.
- The text between these two, without the spaces and tabs at its two
  ends, is the **subject**. The subject can be empty, and it can hold
  any character, spaces and `@` included.

Spaces and tabs can follow the hash prefix, and nothing else can.
Example: in `@ack retired docs#size=v2 3f2a9c1d`, the slug is
`retired`, the subject is `docs#size=v2`, and the hash prefix is
`3f2a9c1d`.

### 2.9 Inline citations

An inline citation is a link whose destination starts with the seven
characters `sinter:`. A link is an inline link, a reference link, or an
autolink of the markdown document of a text, as CommonMark 0.31.2
defines them. The markdown document of a text is the text of its body,
so a U+FEFF at the start of the text is not part of it. An image is not
a link, so `![x](sinter:packs#size-limit=v2)` is not an inline citation.

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
an external id carries no revision. An inline citation allows no vector
selection, so `[x](sinter:packs#descriptor[12]=v1)` is invalid. So
`[auth](sinter:billing/auth=v3)` cites the slug `billing/auth` with the
revision `v3`, and `[auth](sinter:billing/auth)` is invalid. The rule
of external targets (section 2.5) applies as it applies in a tag line.
So under a binding with the external namespace `gh`,
`[x](sinter:gh/42=v2)` is invalid.

The link text of an inline link or a reference link is the text between
its brackets, as it stands in the raw content of the paragraph or the
heading that holds the link. The raw content holds the lines of the
paragraph or the heading, joined by line feeds. Each line of the raw
content is without the markers and the indentation of block quotes and
list items, and without the spaces and tabs at its start. So in a block
quote, the lines `> [the` and `> limit](sinter:packs#size-limit=v2)`
give the link text `the`, a line feed, and `limit`. The line `[the`,
followed by a line that holds three spaces and then
`limit](sinter:packs#size-limit=v2)`, gives the same link text. A
carriage return that no line feed follows also ends a line of
CommonMark 0.31.2, so the text `[the`, a carriage return, and
`limit](sinter:packs#size-limit=v2)` gives the same link text too. The
link text keeps its markup, such as `*the* limit` in
`[*the* limit](sinter:packs#size-limit=v2)`. The link text of an
autolink, such as `<sinter:req:packs#size-limit=v2>`, is its text
between `<` and `>`.

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
- A code span of CommonMark 0.31.2 gives its content.
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
0.31.2 builds both links, and a conforming program follows the parsing
strategy. So the text
`[<https://example.com>](sinter:packs#size-limit=v2)` is a link, and
the autolink inside it is a link too. This inline citation is valid:
the autolink gives `https://example.com` to the plain string content of
its link text.

### 2.10 Id patterns

An id pattern is a small regular expression. An id fits an id pattern
when the whole id, and not only a part of it, has the form that the id
pattern gives. An id pattern is built from these elements:

| element | form | texts that fit it |
|---|---|---|
| literal | one printable ASCII character other than `\ . [ ] ( ) { } * + ? \| ^ $ # / = @ ,` | that character |
| character class | `[`, class members, `]`, with a `-` that can also stand right after the `[` or right before the `]`; it holds one class member or such a `-` at least | one character that fits a class member; also `-` when the class holds a `-` right after its `[` or right before its `]` |
| class member | a printable ASCII character other than `\ [ ] ^ - # / = @ , { }` | that character |
| class member | a range `x-y`: two digits, two upper-case letters, or two lower-case letters, with `x` not after `y` | each character from `x` to `y` |
| subpattern | `(`, an id pattern, `)` | the texts that fit that id pattern |
| sequence | elements one after another | texts that fit each element, one after another |
| alternation | `a\|b` | the texts that fit `a`, and the texts that fit `b` |
| quantifier | `?`, `*`, `+`, `{n}`, `{n,}`, or `{n,m}` after a literal, a character class, or a subpattern | texts that fit the element, 0 or 1 times; 0 or more times; 1 or more times; `n` times; `n` or more times; from `n` to `m` times |

Alternation has the lowest precedence, so the ids `ab` and `c` fit
`ab|c`. A quantifier applies to the one literal, character class, or
subpattern before it. An element allows one quantifier at most. In a
quantifier, `n` and `m` are decimal numerals of whole numbers from 0 to
255, so they have no leading zero, and `n` is not greater than `m`. Case
always matters. A character class can hold characters that a literal
leaves out, such as `.` and `+`: `[.]`, `[+]`.

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

The elements of an id pattern have the forms that they have in the
extended regular expressions of POSIX.1-2024 and the regular expressions
of ECMAScript 2025.

### 2.11 Inputs, results, and values

The inputs of a conforming program are the lines of the texts that it
reads, the links and the images of the markdown document of each text
that it reads, the id patterns and the pairs of an id pattern and an id
that it takes, and the bindings of `external-namespaces` that it takes
or under which it reads. The line that follows a line of a text is the
line of that text whose line number is 1 more. A citation and its
continuation lines are one input, and a continuation line gets no result
of its own. An id pattern is an input when the program takes it on its
own or as the id pattern of a pair of an id pattern and an id, and not
when the program takes it in a binding. A pair of an id pattern and an
id is an input only when the program accepts its id pattern. A
conforming program gives one result for each input, and no result for
anything that is not an input. So the id patterns of a binding get no
results of their own: the binding gets one result. The program also
gives no result when it tests the id of an external target against an id
pattern of the binding.

A line gets one of four results: "not a tag line", "other tag word",
"valid", or "invalid". A link or an image gets one of three results:
"not an inline citation", "valid", or "invalid". An id pattern and a
binding of `external-namespaces` each get "valid" or "invalid". A pair
of an id pattern and an id gets "fits" or "does not fit". To accept an
input is to give it the result "valid", and to reject an input is to
give it the result "invalid". Under a binding that the program rejects,
the program gives no result and no value for a line, a link, or an
image.

For a tag line, the program gives the tag word. For a valid declaration,
citation, status tag, directive, or inline citation, it also gives the
values that the input holds, such as the kind word, the slug, the custom
namespace, the part name, the vector number, the group name, the
namespace name and the id, the revision, the inline description, the
subject and the hash prefix, and the link text. For a citation, it gives
the values of each citation entry, apart from the values of the other
citation entries, in the order of the citation entries. It gives each
value together with its value name, such as "the slug". For each other
input, it gives no value other than the tag word of a tag line. Each
value of a tag line that is a text is the text of a run of the text of
the tag line. Each value of the target of an inline citation is the text
of a run of the destination, so `[x](sinter:&#65;uth=v1)` gives the slug
`Auth`. The link text is the text that section 2.9 describes.

## 3. Parameters

### 3.1 `external-namespaces`

The parameter `external-namespaces` gives the external namespaces. A
binding of it is a finite set of pairs. A conforming program reads each
line, link, and image under exactly one binding, and that binding is an
input too. The external namespaces of that line, link, or image are the
pairs of that binding: each pair of the binding is one external
namespace, with a namespace name and an id pattern. The binding can be
the empty set, and then no target is external.

In a valid binding, each namespace name is a text of lower-case ASCII
letters and ASCII digits that starts with a letter, with one `-` at most
between two of them, such as `gh` or `my-tracker`. No two pairs of a
valid binding have the same namespace name. Each id pattern of a valid
binding is valid.

## 4. Definitions

### 4.1 Tag lines

@term tag-line=v1
@cites text#{
    line=v1, character=v1, space=v1, tab=v1, text=v1, code-span=v1,
    production=v1, rule-name=v1,
}

A tag line is a line whose first character after the spaces and tabs at
its start is `@`. The production `any-char` matches each character. The
productions `indent` and `gap` give the spaces and tabs of a tag line.
The production `rest` matches the empty text, or one or more spaces or
tabs and then any characters:

```
any-char  = %x0-D7FF / %xE000-10FFFF
indent    = *WSP
gap       = 1*WSP
rest      = [ gap *any-char ]
```

### 4.2 Tag words

@term tag-word=v1
@cites {
    #{tag-line=v1},
    text#{
        line=v1, text=v1, run=v1, boundary=v1, code-span=v1, production=v1,
        rule-name=v1,
    },
}

The tag word of a tag line is the text of the longest run of the line
that starts at the boundary right before the first `@` of the line and
whose text matches `tag-word`:

```
tag-word  = "@" *( ALPHA / DIGIT / "-" )
```

### 4.3 Sinter tag words

@term sinter-tag-word=v1
@cites {#{tag-word=v1}, text#{text=v1, code-span=v1}}

The Sinter tag words are these sixteen tag words, in four sets:

- the declaration words: `@decision`, `@design`, `@finding-class`,
  `@req`, `@spec`, and `@term`;
- the citation words: `@cites`, `@refines`, `@satisfies`,
  `@supersedes`, and `@verifies`;
- the status words: `@deferred`, `@deprecated`, and `@rejected`;
- the directive words: `@ack` and `@extern`.

A tag word is a Sinter tag word when, and only when, it is the same
text as one of these sixteen words.

### 4.4 Declarations

@term declaration=v1
@cites #{tag-line=v1, tag-word=v1, sinter-tag-word=v1}

A declaration is a tag line whose tag word is a declaration word.

### 4.5 Citations

@term citation=v1
@cites #{tag-line=v1, tag-word=v1, sinter-tag-word=v1}

A citation is a tag line whose tag word is a citation word.

### 4.6 Status tags

@term status-tag=v1
@cites #{tag-line=v1, tag-word=v1, sinter-tag-word=v1}

A status tag is a tag line whose tag word is a status word.

### 4.7 Directives

@term directive=v1
@cites {
    #{tag-line=v1, tag-word=v1, sinter-tag-word=v1},
    text#{code-span=v1},
}

A directive is a tag line whose tag word is a directive word. An `@ack`
line is a directive whose tag word is `@ack`. An `@extern` line is a
directive whose tag word is `@extern`.

### 4.8 Continuation lines

@term continuation-line=v1
@cites {
    #{tag-line=v1, tag-word=v1, citation=v1},
    text#{
        line=v1, line-number=v1, text=v1, run=v1, character=v1, space=v1,
        tab=v1, line-feed=v1, code-span=v1,
    },
}

For a citation in which a space or a tab follows the tag word, these
steps give its continuation lines. The steps build a text, which starts
as the text of the line of the citation:

1. A count starts at the first character of the text after the spaces
   and tabs that follow the tag word. The count goes through the text,
   one character after another, and keeps the number of `{` and the
   number of `}` that it has passed.
2. When the count comes to a space or a tab, or to the end of the text,
   and it has passed no more `{` than `}`, the steps end.
3. When the count comes to the end of the text and it has passed more
   `{` than `}`, and the next line is neither a tag line nor a blank
   line, that line is a continuation line of the citation. The steps
   add a line feed and the text of that line, without the spaces and
   tabs at its start, to the end of the text, and the count goes on from
   the line feed.
4. When the count comes to the end of the text and it has passed more
   `{` than `}`, and there is no next line, or the next line is a tag
   line or a blank line, the steps end.

The next line is the line of the same text whose line number is 1 more
than the line number of the last line that the steps have added: the
line of the citation, or the last continuation line. A blank line is a
line that holds no character other than spaces and tabs.

### 4.9 The texts of tag lines

@term tag-line-text=v1
@cites {
    #{tag-line=v1, tag-word=v1, citation=v1, continuation-line=v1},
    text#{line=v1, text=v1, space=v1, tab=v1, code-span=v1},
}

The text of a citation in which a space or a tab follows the tag word is
the text that the steps of `continuation-line` build when they end. The
text of each other tag line is the text of its line.

### 4.10 Segments

@term segment=v1
@cites text#{text=v1, code-span=v1, production=v1, rule-name=v1}

A segment is a text that matches the production `segment`:

```
alnum      = ALPHA / DIGIT
segment    = 1*alnum *( ( "-" / "_" / "." ) 1*alnum )
```

### 4.11 Slugs

@term slug=v1
@cites {#{segment=v1}, text#{text=v1, code-span=v1, production=v1, rule-name=v1}}

A slug is a text that matches the production `slug`:

```
slug       = segment *( "/" segment )
```

### 4.12 Part names

@term part-name=v1
@cites {#{segment=v1}, text#{text=v1, code-span=v1, production=v1, rule-name=v1}}

A part name is a text that matches the production `part-name`:

```
part-name  = segment
```

### 4.13 Full names

@term full-name=v1
@cites {
    #{slug=v1, part-name=v1},
    text#{text=v1, code-span=v1, production=v1, rule-name=v1},
}

A full name is a text that matches the production `full-name`:

```
full-name  = slug "#" part-name
```

### 4.14 Names

@term name=v1
@cites {
    #{slug=v1, part-name=v1, full-name=v1},
    text#{text=v1, code-span=v1, production=v1, rule-name=v1},
}

A name is a text that matches the production `name`:

```
name       = slug / full-name / "#" part-name
```

### 4.15 Kind words

@term kind-word=v1
@cites text#{text=v1, code-span=v1, production=v1, rule-name=v1}

The kind words are the texts that this production matches:

```
kind-word  = %s"decision" / %s"design" / %s"finding-class" / %s"req"
           / %s"spec" / %s"term"
```

### 4.16 Labels

@term label=v1
@cites text#{text=v1, code-span=v1, production=v1, rule-name=v1}

A label is a text that matches the production `label`:

```
label     = 1*( %x21-22 / %x24-29 / %x2B / %x2D-2E / %x30-3C
              / %x3E-3F / %x41-5A / %x5C / %x5E-7A / %x7C / %x7E )
```

### 4.17 Revisions

@term revision=v1
@cites {#{label=v1}, text#{text=v1, code-span=v1, production=v1, rule-name=v1}}

A revision is a text that matches the production `revision`:

```
revision  = label / "*"
```

The revision `*` stands for any label.

### 4.18 Vector selections

@term vector-selection=v1
@cites {
    #{segment=v1},
    text#{
        text=v1, decimal-numeral=v1, code-span=v1, production=v1,
        rule-name=v1,
    },
}

A vector selection is a text that matches the production
`vector-selection`:

```
vector-selection  = "[" vector-number "]"
                  / [ "[" group-name "]" ] every-vector
vector-number     = decimal-numeral
group-name        = segment
every-vector      = "[*]"
```

### 4.19 Links

@term link=v1
@cites {commonmark/0.31.2, text#{text=v1, run=v1, body=v1}}

The markdown document of a text is the text of its body. A link is an
inline link, a full, collapsed, or shortcut reference link, or an
autolink of the markdown document of a text, each as CommonMark 0.31.2
defines it. An image is not a link. An inline link or a reference link
can hold an autolink among the inline elements that its square brackets
enclose. Then the inline link or the reference link is a link, and the
autolink is a link too, as the parsing strategy in the appendix of
CommonMark 0.31.2 builds them. For such an autolink, this rule takes
precedence over the rule in section 6.3 of CommonMark 0.31.2 that a link
holds no other link.

### 4.20 Destinations

@term destination=v1
@cites {
    commonmark/0.31.2,
    #{link=v1},
    text#{text=v1, character=v1, code-span=v1},
}

The destination of an inline link or a reference link is its link
destination as CommonMark 0.31.2 gives it: without the angle brackets
that enclose it, and with each backslash escape, entity reference, and
numeric character reference replaced by the characters that CommonMark
0.31.2 gives for it. No percent-encoding and no percent-decoding
applies to a destination, so a `%` is a character of the destination.
The destination of an autolink is its text between `<` and `>`.

### 4.21 Inline citations

@term inline-citation=v1
@cites {#{link=v1, destination=v1}, text#{character=v1, code-span=v1}}

An inline citation is a link whose destination starts with the seven
characters `sinter:`.

### 4.22 Link text

@term link-text=v1
@cites {
    commonmark/0.31.2,
    #{link=v1},
    text#{
        text=v1, character=v1, space=v1, tab=v1, line-feed=v1,
        carriage-return=v1, code-span=v1,
    },
}

The raw content of a paragraph or a heading is the text that these
steps give:

1. Take the lines of the paragraph or the heading, in their order, as
   CommonMark 0.31.2 gives them. A line of CommonMark 0.31.2 holds no
   line feed and no carriage return: a line feed, a carriage return
   that no line feed follows, and a carriage return with the line feed
   right after it each end a line. Leave out the underline of a setext
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

### 4.23 Blank characters

@term blank-character=v1
@cites {commonmark/0.31.2, text#{character=v1, u-numeral=v1}}

A blank character is one of these characters:

- each Unicode whitespace character of CommonMark 0.31.2: U+0009,
  U+000A, U+000C, U+000D, U+0020, U+00A0, U+1680, each character from
  U+2000 to U+200A, U+202F, U+205F, and U+3000;
- U+200B, U+200C, U+200D, U+2060, and U+FEFF.

### 4.24 Plain string content

@term plain-string-content=v1
@cites {
    commonmark/0.31.2,
    #{link=v1, link-text=v1},
    text#{text=v1, character=v1, line-feed=v1, code-span=v1},
}

The plain string content of a sequence of inline elements, as
CommonMark 0.31.2 parses them, is a text. It joins, in the order of the
elements, the texts that these rules give for the elements:

- Textual content gives its characters, with each backslash escape,
  entity reference, and numeric character reference replaced by the
  characters that CommonMark 0.31.2 gives for it.
- A code span of CommonMark 0.31.2 gives its content.
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

### 4.25 Targets

@term target=v1
@cites {
    #{
        tag-line=v1, declaration=v1, citation=v1, directive=v1,
        tag-word=v1, tag-line-text=v1, inline-citation=v1, destination=v1,
    },
    text#{text=v1, space=v1, tab=v1, code-span=v1},
}

The target of a declaration, a citation, or an `@extern` line is the
text that starts after the spaces and tabs that follow its tag word in
the text of the tag line. The target ends before the first space or tab
that has no more `{` than `}` of the target before it, or at the end of
the text of the tag line when no such space or tab follows. The target
of an inline citation is the text of its destination after `sinter:`.

### 4.26 Inline descriptions

@term inline-description=v1
@cites {
    #{
        target=v1, tag-line=v1, declaration=v1, citation=v1, status-tag=v1,
        directive=v1, tag-word=v1, tag-line-text=v1,
    },
    text#{text=v1, space=v1, tab=v1, code-span=v1},
}

The inline description of a declaration, a citation, or an `@extern`
line is the text of the tag line after its target, without the spaces
and tabs at its start. The inline description of a status tag is the
text of the tag line after its tag word, without the spaces and tabs at
its start. An inline description can be empty.

### 4.27 Id patterns

@term id-pattern=v1
@cites text#{
    text=v1, conforming-program=v1, decimal-numeral=v1, whole-number=v1,
    code-span=v1, production=v1, rule-name=v1,
}

An id pattern is a text that a conforming program takes as a pattern,
against which it tests other texts. A text that a conforming program
takes as an id pattern is an id pattern whether or not it matches
`pattern`. These productions give the texts that `pattern` matches:

```
pattern       = branch *( "|" branch )
branch        = 1*piece
piece         = atom [ quantifier ]
atom          = literal / char-class / "(" pattern ")"
literal       = %x21-22 / %x25-27 / %x2D / %x30-3C / %x3E / %x41-5A
              / %x5F-7A / %x7E
char-class    = "[" ( edge-dash *class-member / 1*class-member )
                [ edge-dash ] "]"
edge-dash     = "-"
class-member  = range / single
range         = %x30-39 "-" %x30-39 / %x41-5A "-" %x41-5A
              / %x61-7A "-" %x61-7A
single        = %x21-22 / %x24-2B / %x2E / %x30-3C / %x3E-3F / %x41-5A
              / %x5F-7A / %x7C / %x7E
quantifier    = "?" / "*" / "+" / "{" count "}" / "{" count ",}"
              / "{" count "," count "}"
count         = decimal-numeral
```

The number of a `count` is the whole number that its decimal numeral
writes. The quantifiers `{n}`, `{n,}`, and `{n,m}` are the forms
`"{" count "}"`, `"{" count ",}"`, and `"{" count "," count "}"`, where
`n` is the number of the first `count`, and `m` is the number of the
second `count`.

### 4.28 Ids

@term id=v1
@cites {#{id-pattern=v1}, text#{text=v1, conforming-program=v1}}

An id is a text that a conforming program tests against an id pattern.

### 4.29 Fit

@term fit=v1
@cites {
    #{id=v1, id-pattern=v1},
    text#{
        text=v1, run=v1, boundary=v1, character=v1, code-point-order=v1,
        code-span=v1, production=v1,
    },
}

An id fits an id pattern that matches `pattern` when, and only when,
the run of the id that holds all of its characters fits that `pattern`.
These rules state when a run of the id, which can be the whole id or an
empty run, fits an element of the id pattern:

- A run fits a `literal` when, and only when, it holds exactly one
  character, which is the one character of the `literal`.
- A run fits a `range` when, and only when, it holds exactly one
  character, which comes neither before the first character of the
  `range` nor after its last character in code point order. A run fits
  a `single` when, and only when, it holds exactly one character, which
  is the one character of the `single`. A run fits an `edge-dash` when,
  and only when, it holds exactly one character, which is `-`.
- A run fits a `class-member` when, and only when, it fits the `range`
  or the `single` of the `class-member`.
- A run fits a `char-class` when, and only when, it fits one of the
  `class-member` elements or one of the `edge-dash` elements of the
  `char-class`.
- A run fits an `atom` that is a `literal` or a `char-class` when, and
  only when, it fits that `literal` or that `char-class`. A run fits an
  `atom` of the form `"(" pattern ")"` when, and only when, it fits the
  inner `pattern`.
- A run fits a `piece` with no `quantifier` when, and only when, it
  fits the `atom` of the `piece`. A run fits a `piece` with a
  `quantifier` when, and only when, boundaries of the run divide it into
  a sequence of runs, one right after another, that each fit the
  `atom`, and the number of runs of the sequence is 0 or 1 for `?`, 0
  or more for `*`, 1 or more for `+`, exactly `n` for `{n}`, `n` or more
  for `{n,}`, and from `n` to `m` for `{n,m}`. A sequence of no runs
  divides only an empty run. The runs of the sequence can differ.
- A run fits a `branch` when, and only when, boundaries of the run
  divide it into a sequence of runs, one right after another and one
  for each `piece` of the `branch` in their order, and each run fits its
  `piece`.
- A run fits a `pattern` when, and only when, it fits one of the
  branches of the `pattern`.

### 4.30 The size of an id pattern

@term id-pattern-size=v1
@cites {
    #{id-pattern=v1},
    text#{text=v1, whole-number=v1, code-span=v1, production=v1},
}

The size of a text that matches `pattern` is a whole number that these
rules give:

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

### 4.31 Bindings

@term binding=v1
@cites {#{id-pattern=v1}, text#{text=v1, code-span=v1}}

A binding of the parameter `external-namespaces` is a finite set of
pairs. Each pair of a binding holds a namespace name, which is a text,
and an id pattern.

### 4.32 External namespaces

@term external-namespace=v1
@cites {
    #{binding=v1, id-pattern=v1, link=v1},
    text#{line=v1, conforming-program=v1},
}

Each pair of a binding is an external namespace of that binding, with
the namespace name and the id pattern of that pair of the binding. The
external namespaces of a line, a link, or an image are the external
namespaces of the binding under which a conforming program reads it.

### 4.33 Namespace names

@term namespace-name=v1
@cites {
    #{binding=v1},
    text#{text=v1, code-span=v1, production=v1, rule-name=v1},
}

A namespace name of a binding can match the production `namespace-name`
or not. This production gives the texts that `namespace-name` matches:

```
namespace-name  = %x61-7A *( %x61-7A / DIGIT )
                  *( "-" 1*( %x61-7A / DIGIT ) )
```

### 4.34 External ids

@term external-id=v1
@cites {
    #{
        part-name=v1, namespace-name=v1, binding=v1,
        external-namespace=v1, id=v1, id-pattern=v1, fit=v1, tag-line=v1,
        inline-citation=v1,
    },
    text#{text=v1, code-span=v1, production=v1, rule-name=v1},
}

These productions give the form of an external id:

```
external-ref  = external-id [ "#" part-name ]
external-id   = namespace-name "/" id-text
id-text       = 1*( %x21-22 / %x24-2B / %x2D-2E / %x30-3C / %x3E-3F
                    / %x41-5A / %x5C / %x5E-7A / %x7C / %x7E )
```

In `external-id`, a text matches `namespace-name` only when it is the
namespace name of an external namespace of the tag line or the inline
citation that holds the text. A text matches `external-id` only when the
text that its `id-text` matches, as an id, fits the id pattern of the
external namespace of that tag line or that inline citation whose
namespace name its `namespace-name` matches.

### 4.35 External targets

@term external-target=v1
@cites {
    #{
        target=v1, citation-entry=v1, kind-word=v1, declaration=v1,
        inline-citation=v1, tag-line=v1, binding=v1,
        external-namespace=v1,
    },
    text#{text=v1, character=v1, code-span=v1, production=v1},
}

A target or a citation entry starts with a kind word when it holds a `:`
and the text before its first `:` matches `kind-word`. The head of a
target or a citation entry is its text after that kind word and that
`:`, when it starts with a kind word, and before its first character
that is `#`, `=`, or `[`, when it holds one. The target of a
declaration, the target of an inline citation, and a citation entry are
each an external target when, and only when, the text of its head before
the first `/` of that head, or the whole head when that head holds no
`/`, is the namespace name of an external namespace of the tag line or
the inline citation that holds that target or that citation entry.

### 4.36 The form of declarations

@term declaration-line=v1
@cites {
    #{
        declaration=v1, tag-line=v1, segment=v1, slug=v1, full-name=v1,
        label=v1,
    },
    text#{code-span=v1, production=v1, rule-name=v1},
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
                  / indent %s"@term" gap ( slug / full-name )
                    [ "=" label ] rest
```

### 4.37 The form of citations

@term citation-line=v1
@cites {
    #{
        citation=v1, tag-line-text=v1, tag-line=v1, kind-word=v1, name=v1,
        slug=v1, part-name=v1, label=v1, revision=v1, external-id=v1,
        vector-selection=v1,
    },
    text#{text=v1, code-span=v1, production=v1, rule-name=v1},
}

These productions give the form of the text of a citation:

```
citation-line      = indent %s"@cites" gap ( cites-target / cites-list )
                     rest
                   / indent %s"@verifies" gap
                     ( verifies-target / verifies-list ) rest
                   / indent ( %s"@refines" / %s"@satisfies" )
                     gap ( fixed-target / fixed-list ) rest
                   / indent %s"@supersedes" gap
                     ( supersedes-target / supersedes-list ) rest
cites-list         = "{" list-space cites-target
                     *( comma cites-target ) [ list-space "," ]
                     list-space "}"
verifies-list      = "{" list-space verifies-target
                     *( comma verifies-target ) [ list-space "," ]
                     list-space "}"
fixed-list         = "{" list-space fixed-target
                     *( comma fixed-target ) [ list-space "," ]
                     list-space "}"
supersedes-list    = "{" list-space supersedes-target
                     *( comma supersedes-target ) [ list-space "," ]
                     list-space "}"
cites-target       = cites-single / cites-scoped
verifies-target    = verifies-single / verifies-scoped
fixed-target       = fixed-single / fixed-scoped
supersedes-target  = supersedes-single / fixed-scoped
cites-single       = [ kind-word ":" ]
                     ( name [ vector-selection ] "=" revision
                     / external-ref )
verifies-single    = [ kind-word ":" ]
                     ( name [ vector-selection ] "=" label
                     / external-ref )
fixed-single       = [ kind-word ":" ] ( name "=" label / external-ref )
supersedes-single  = [ kind-word ":" ] ( name "=" label / external-ref )
                   / every-part
every-part         = slug "=" label "#*"
cites-scoped       = [ kind-word ":" ] [ slug ] "#{" list-space
                     cites-part *( comma cites-part )
                     [ list-space "," ] list-space "}"
verifies-scoped    = [ kind-word ":" ] [ slug ] "#{" list-space
                     verifies-part *( comma verifies-part )
                     [ list-space "," ] list-space "}"
fixed-scoped       = [ kind-word ":" ] [ slug ] "#{" list-space
                     fixed-part *( comma fixed-part )
                     [ list-space "," ] list-space "}"
cites-part         = part-name [ vector-selection ] "=" revision
verifies-part      = part-name [ vector-selection ] "=" label
fixed-part         = part-name "=" label
comma              = list-space "," list-space
list-space         = *( WSP / LF )
```

### 4.38 Citation entries

@term citation-entry=v1
@cites {
    #{
        citation=v1, citation-line=v1, tag-line-text=v1, tag-word=v1,
        sinter-tag-word=v1, name=v1, slug=v1, external-id=v1,
        vector-selection=v1,
    },
    text#{text=v1, code-span=v1, production=v1},
}

In a match of the text of a citation by `citation-line`, a single target
is a text that `cites-single`, `verifies-single`, `fixed-single`, or
`supersedes-single` matches, and a scoped list is a text that
`cites-scoped`, `verifies-scoped`, or `fixed-scoped` matches. In a
scoped list, each text that `cites-part`, `verifies-part`, or
`fixed-part` matches stands for a single target: the text of the scoped
list before its `{`, and then that text. The citation entries of the
match are, in their order in the text of the citation, its single
targets and the single targets for which the parts of its scoped lists
stand.

The match of a citation entry is its match by `cites-single` when the
tag word of the citation is `@cites`, by `verifies-single` when it is
`@verifies`, by `supersedes-single` when it is `@supersedes`, and by
`fixed-single` for each other citation word. The entry name of a
citation entry is the text that `name` or `external-ref` matches in the
match of the citation entry, or the text that `slug` matches in it when
`every-part` matches the citation entry. The vector selection of a
citation entry is the text that `vector-selection` matches in the match
of the citation entry, or the empty text when the match holds no
`vector-selection`.

### 4.39 The form of status tags

@term status-line=v1
@cites {#{status-tag=v1, tag-line=v1}, text#{code-span=v1, production=v1, rule-name=v1}}

This production gives the form of a status tag:

```
status-line  = indent ( %s"@deferred" / %s"@deprecated" / %s"@rejected" )
               rest
```

### 4.40 The form of `@extern` lines

@term extern-line=v1
@cites {
    #{directive=v1, tag-line=v1, kind-word=v1, part-name=v1},
    text#{code-span=v1, production=v1, rule-name=v1},
}

This production gives the form of an `@extern` line:

```
extern-line  = indent %s"@extern" gap kind-word ":" part-name rest
```

### 4.41 The form of `@ack` lines

@term ack-line=v1
@cites {
    #{directive=v1, tag-line=v1, slug=v1},
    text#{hex-digit=v1, code-span=v1, production=v1, rule-name=v1},
}

These productions give the form of an `@ack` line:

```
ack-line     = indent %s"@ack" gap slug [ gap subject ] gap hash-prefix
               *WSP
subject      = non-wsp [ *any-char non-wsp ]
non-wsp      = %x0-8 / %xA-1F / %x21-D7FF / %xE000-10FFFF
hash-prefix  = 8*64hex-digit
```

### 4.42 The form of inline citations

@term inline-destination=v1
@cites {
    #{
        inline-citation=v1, destination=v1, kind-word=v1, name=v1,
        revision=v1, external-id=v1,
    },
    text#{code-span=v1, production=v1, rule-name=v1},
}

This production gives the form of the destination of an inline
citation:

```
inline-destination  = %s"sinter:" [ kind-word ":" ]
                      ( name "=" revision / external-ref )
```

### 4.43 Inputs

@term input=v1
@cites {
    #{
        continuation-line=v1, citation=v1, link=v1, id-pattern=v1, id=v1,
        binding=v1,
    },
    text#{
        input=v1, conforming-program=v1, line=v1, text=v1, result=v1,
        code-span=v1,
    },
}

The inputs of a conforming program are these:

- each line of a text that it reads, except a continuation line: a
  citation and its continuation lines are one input;
- each link and each image of the markdown document of a text that it
  reads;
- each id pattern that it takes on its own, and the id pattern of each
  pair of an id pattern and an id that it takes, but not an id pattern
  of a binding of `external-namespaces`;
- each binding of `external-namespaces` that it takes, and each binding
  of `external-namespaces` under which it reads a line, a link, or an
  image;
- each pair of an id pattern and an id that it takes, when it gives the
  result "valid" for the id pattern of that pair of an id pattern and an
  id.

### 4.44 The matches of inputs

@term input-match=v1
@cites {
    #{
        input=v1, tag-line=v1, tag-line-text=v1, inline-citation=v1,
        destination=v1, declaration=v1, citation=v1, status-tag=v1,
        directive=v1, extern-line=v1, ack-line=v1, declaration-line=v1,
        citation-line=v1, status-line=v1, inline-destination=v1,
        external-target=v1, external-id=v1, citation-entry=v1, target=v1,
        kind-word=v1,
    },
    text#{text=v1, code-span=v1, production=v1},
}

A match of an input is a match of the text of a tag line, or of the
destination of an inline citation, by one of these productions:

- `declaration-line` for a declaration;
- `citation-line` for a citation;
- `status-line` for a status tag;
- `extern-line` for an `@extern` line;
- `ack-line` for an `@ack` line;
- `inline-destination` for the destination of an inline citation.

A match is a match of the input only when these conditions hold:

- When the input is a declaration, its target is not an external
  target.
- Each of these texts that is an external target matches
  `external-ref`, without its kind word and the `:` after it when it
  starts with a kind word: the target of an inline citation, and each
  citation entry of the match of a citation.

### 4.45 Values

@term value=v1
@cites text#{text=v1, conforming-program=v1, result=v1}

A value is a text or a fact that a conforming program gives together
with a result, under a value name, such as "the slug".

## 5. Requirements

### 5.1 One binding for each line, link, and image

@req use-one-binding=v1
@cites {
    #{binding=v1, link=v1},
    text#{conforming-program=v1, requirement=v1, line=v1, code-span=v1},
}

A conforming program must read each line, link, and image under exactly
one binding of `external-namespaces`.

### 5.2 Unmatched id patterns

@req reject-unmatched-id-patterns=v1
@cites {
    #{input=v1, id-pattern=v1},
    text#{
        conforming-program=v1, requirement=v1, result=v1, production=v1,
        code-span=v1,
    },
}

A conforming program must give the result "invalid" for each id pattern
that is an input and that does not match the production `pattern`.

### 5.3 Reversed ranges in id patterns

@req reject-reversed-ranges=v1
@cites {
    #{input=v1, id-pattern=v1},
    text#{
        conforming-program=v1, requirement=v1, result=v1, character=v1,
        code-point-order=v1, code-span=v1,
    },
}

A conforming program must give the result "invalid" for each id pattern
that is an input and that holds a `range` whose first character comes
after its last character in code point order.

### 5.4 Large counts in id patterns

@req reject-large-counts=v1
@cites {
    #{input=v1, id-pattern=v1},
    text#{conforming-program=v1, requirement=v1, result=v1, code-span=v1},
}

A conforming program must give the result "invalid" for each id pattern
that is an input and that holds a `count` whose number is greater than
255.

### 5.5 Reversed bounds in id patterns

@req reject-reversed-bounds=v1
@cites {
    #{input=v1, id-pattern=v1},
    text#{conforming-program=v1, requirement=v1, result=v1, code-span=v1},
}

A conforming program must give the result "invalid" for each id pattern
that is an input and that holds a quantifier `{n,m}` in which `n` is
greater than `m`.

### 5.6 Tests of ids

@req test-ids=v1
@cites {
    #{input=v1, id-pattern=v1, id=v1, fit=v1},
    text#{conforming-program=v1, requirement=v1, result=v1},
}

For each input that is a pair of an id pattern and an id, a conforming
program must give the result "fits" when the id fits the id pattern, and
the result "does not fit" when it does not.

### 5.7 Empty ids

@req reject-empty-id-fit=v1
@cites {
    #{input=v1, id-pattern=v1, id=v1, fit=v1},
    text#{conforming-program=v1, requirement=v1, result=v1, text=v1},
}

A conforming program must give the result "invalid" for each id pattern
that is an input and that the empty text, as an id, fits.

### 5.8 The limit on the size of an id pattern

@req reject-oversized-id-patterns=v1
@cites {
    #{input=v1, id-pattern=v1, id-pattern-size=v1},
    text#{conforming-program=v1, requirement=v1, result=v1},
}

A conforming program must give the result "invalid" for each id pattern
that is an input and whose size is greater than 1,000.

### 5.9 The length of an id pattern

@req reject-long-id-patterns=v1
@cites {
    #{input=v1, id-pattern=v1},
    text#{conforming-program=v1, requirement=v1, result=v1, character=v1},
}

A conforming program must give the result "invalid" for each id pattern
that is an input and that holds more than 1,000 characters.

### 5.10 The form of namespace names

@req reject-malformed-namespace-names=v1
@cites {
    #{binding=v1, namespace-name=v1},
    text#{
        conforming-program=v1, requirement=v1, result=v1, production=v1,
        code-span=v1,
    },
}

A conforming program must give the result "invalid" for a binding of
`external-namespaces` that holds a namespace name that does not match
`namespace-name`.

### 5.11 Unique namespace names

@req reject-repeated-namespace-names=v1
@cites {
    #{binding=v1},
    text#{
        conforming-program=v1, requirement=v1, result=v1, text=v1,
        code-span=v1,
    },
}

A conforming program must give the result "invalid" for a binding of
`external-namespaces` in which two pairs of the binding have the same
namespace name.

### 5.12 Invalid id patterns in bindings

@req reject-invalid-binding-patterns=v1
@cites {
    #{
        binding=v1, id-pattern=v1, input=v1,
        reject-unmatched-id-patterns=v1, reject-reversed-ranges=v1,
        reject-large-counts=v1, reject-reversed-bounds=v1,
        reject-empty-id-fit=v1, reject-oversized-id-patterns=v1,
        reject-long-id-patterns=v1,
    },
    text#{conforming-program=v1, requirement=v1, result=v1, code-span=v1},
}

A conforming program must give the result "invalid" for a binding of
`external-namespaces` that holds an id pattern that, as an input on its
own, gets the result "invalid" under one of these requirements:
`reject-unmatched-id-patterns`, `reject-reversed-ranges`,
`reject-large-counts`, `reject-reversed-bounds`, `reject-empty-id-fit`,
`reject-oversized-id-patterns`, and `reject-long-id-patterns`.

### 5.13 Rejected bindings

@req give-no-results-under-rejected-bindings=v1
@cites {
    #{binding=v1, link=v1},
    text#{
        conforming-program=v1, requirement=v1, result=v1, line=v1,
        code-span=v1,
    },
}

Under a binding of `external-namespaces` for which it gives the result
"invalid", a conforming program must give no result for a line, a link,
or an image.

### 5.14 Inputs with no match

@req reject-unmatched-inputs=v1
@cites {
    #{
        binding=v1, input=v1, declaration=v1, citation=v1,
        status-tag=v1, directive=v1, inline-citation=v1, input-match=v1,
    },
    text#{conforming-program=v1, requirement=v1, result=v1, code-span=v1},
}

Under a binding of `external-namespaces` for which it gives the result
"valid", a conforming program must give the result "invalid" for each
declaration, citation, status tag, directive, and inline citation that
is an input and that has no match.

### 5.15 Unique citation entries

@req reject-repeated-entries=v1
@cites {
    #{
        binding=v1, input=v1, citation=v1, citation-entry=v1,
        vector-selection=v1, input-match=v1,
    },
    text#{
        conforming-program=v1, requirement=v1, result=v1, text=v1,
        code-span=v1,
    },
}

Under a binding of `external-namespaces` for which it gives the result
"valid", a conforming program must give the result "invalid" for each
citation that is an input and that has a match in which two citation
entries have the same entry name and the same vector selection.

### 5.16 The link text of inline citations

@req reject-blank-link-text=v1
@cites {
    #{
        binding=v1, input=v1, inline-citation=v1, link-text=v1,
        plain-string-content=v1, blank-character=v1,
    },
    text#{
        conforming-program=v1, requirement=v1, result=v1, character=v1,
        code-span=v1,
    },
}

Under a binding of `external-namespaces` for which it gives the result
"valid", a conforming program must give the result "invalid" for each
inline citation that is an input and the plain string content of whose
link text holds no character other than blank characters.

### 5.17 The tag word

@req give-tag-words=v1
@cites {
    #{binding=v1, tag-line=v1, tag-word=v1, value=v1},
    text#{conforming-program=v1, requirement=v1, result=v1, code-span=v1},
}

Under a binding of `external-namespaces` for which it gives the result
"valid", a conforming program must give the tag word of each tag line as
a value, with the value name "the tag word".

### 5.18 Values

@req give-values=v1
@cites {
    #{
        binding=v1, input=v1, value=v1, tag-line=v1,
        tag-word=v1, sinter-tag-word=v1, declaration=v1, citation=v1,
        status-tag=v1, directive=v1, ack-line=v1,
        inline-citation=v1, target=v1, inline-description=v1,
        link-text=v1, input-match=v1, citation-entry=v1, kind-word=v1,
        slug=v1, segment=v1, part-name=v1, citation-line=v1,
        vector-selection=v1, external-id=v1, namespace-name=v1,
        revision=v1, label=v1,
    },
    text#{
        conforming-program=v1, requirement=v1, result=v1, text=v1,
        code-span=v1, production=v1,
    },
}

Under a binding of `external-namespaces` for which it gives the result
"valid", a conforming program must give these values for each
declaration, citation, status tag, directive, and inline citation for
which it gives the result "valid", each together with the value name in
the first cell of its row:

- each value of the first table whose second cell describes the input;
- for a citation, for each citation entry in the order of the citation
  entries, and apart from the values of the other citation entries, each
  value of the second table whose second cell describes the match of the
  citation entry;
- for each other input, each value of the second table whose second
  cell describes the match of the input.

| value name | input | value |
|---|---|---|
| the type of tag line | a tag line with a Sinter tag word | declaration, citation, status tag, or directive: the one that the tag line is |
| the inline description | a declaration, a citation, a status tag, or an `@extern` line | its inline description |
| the subject | an `@ack` line | the text that `subject` matches, or the empty text when the match holds no `subject` |
| the hash prefix | an `@ack` line | the text that `hash-prefix` matches |
| the link text | an inline citation | its link text |

| value name | match | value |
|---|---|---|
| the kind word | a match that holds `kind-word` | the text that `kind-word` matches |
| the slug | a match that holds `slug` | the text that `slug` matches |
| the slug | the match of a declaration with the tag word `@spec` whose target holds no `#` | the text that `segment` matches |
| the custom namespace | a match that holds `slug`, when the text that `slug` matches holds a `/` | the text that `slug` matches, before its last `/` |
| the part name | a match that holds `part-name` | the text that `part-name` matches |
| every part | a match that holds `every-part` | no text |
| the vector number | a match that holds `vector-number` | the text that `vector-number` matches |
| the group name | a match that holds `group-name` | the text that `group-name` matches |
| every vector | a match that holds `every-vector` | no text |
| the namespace name | a match that holds `external-id` | the text that `namespace-name` matches in `external-id` |
| the id | a match that holds `external-id` | the text that `id-text` matches |
| the revision | a match that holds `revision` or `label` | the text that `revision` matches, or the text that `label` matches when the match holds no `revision` |

### 5.19 No other values

@req give-no-other-values=v1
@cites {
    #{input=v1, value=v1, give-values=v1, give-tag-words=v1},
    text#{conforming-program=v1, requirement=v1, code-span=v1},
}

A conforming program must give no value for an input other than the
values that the requirements `give-values` and `give-tag-words` state
for that input.

### 5.20 The result of each input

@req give-results=v1
@cites {
    #{
        input=v1, binding=v1, tag-line=v1, tag-word=v1,
        sinter-tag-word=v1, declaration=v1, citation=v1, status-tag=v1,
        directive=v1, link=v1, inline-citation=v1, id-pattern=v1, id=v1,
    },
    text#{
        conforming-program=v1, requirement=v1, result=v1, line=v1,
        code-span=v1,
    },
}

A conforming program must give exactly one result for each input, and
only a result that this table lists for that input. For a line, a link,
and an image, this obligation holds under a binding of
`external-namespaces` for which the program gives the result "valid".

| input | result |
|---|---|
| a line that is not a tag line | "not a tag line" |
| a tag line whose tag word is not a Sinter tag word | "other tag word" |
| a declaration, a citation, a status tag, or a directive | "valid" or "invalid" |
| a link or an image of a markdown document that is not an inline citation | "not an inline citation" |
| an inline citation | "valid" or "invalid" |
| an id pattern | "valid" or "invalid" |
| a binding of `external-namespaces` | "valid" or "invalid" |
| a pair of an id pattern and an id | "fits" or "does not fit" |

### 5.21 Things that are not inputs

@req give-no-results-for-non-inputs=v1
@cites {
    #{input=v1},
    text#{conforming-program=v1, requirement=v1, result=v1},
}

A conforming program must give no result for anything that is not an
input.

### 5.22 Acceptance

@req accept-inputs=v1
@cites {
    #{
        input=v1, declaration=v1, citation=v1, status-tag=v1, directive=v1,
        inline-citation=v1, id-pattern=v1, binding=v1,
        reject-unmatched-id-patterns=v1, reject-reversed-ranges=v1,
        reject-large-counts=v1, reject-reversed-bounds=v1,
        reject-empty-id-fit=v1, reject-oversized-id-patterns=v1,
        reject-long-id-patterns=v1, reject-malformed-namespace-names=v1,
        reject-repeated-namespace-names=v1,
        reject-invalid-binding-patterns=v1, reject-unmatched-inputs=v1,
        reject-repeated-entries=v1, reject-blank-link-text=v1,
    },
    text#{conforming-program=v1, requirement=v1, result=v1, code-span=v1},
}

A conforming program must give the result "valid" for each input that
is a declaration, a citation, a status tag, a directive, an inline
citation, an id pattern, or a binding of `external-namespaces`, unless
one of these requirements states that the program must give the result
"invalid" for it: `reject-unmatched-id-patterns`,
`reject-reversed-ranges`, `reject-large-counts`,
`reject-reversed-bounds`, `reject-empty-id-fit`,
`reject-oversized-id-patterns`, `reject-long-id-patterns`,
`reject-malformed-namespace-names`, `reject-repeated-namespace-names`,
`reject-invalid-binding-patterns`, `reject-unmatched-inputs`,
`reject-repeated-entries`, and `reject-blank-link-text`. For a
declaration, a citation, a status tag, a directive, and an inline
citation, this obligation holds under a binding of
`external-namespaces` for which the program gives the result "valid".

## 6. Conformance

A program, or a part of a program, conforms to this design when it
meets every requirement of the section Requirements.

Each vector below gives an input and the result that a conforming
program gives for it. These conventions apply:

- In sections 6.1, 6.2, and 6.3, the program reads each input under one
  binding of `external-namespaces`, the binding of the conventions. The
  pairs of the binding of the conventions are `gh` with the id pattern
  `[1-9][0-9]*`, and `rfc` with the id pattern `[1-9][0-9]*`.
- The binding of the conventions is an input too. It gets the result
  "valid", which no row repeats.
- In section 6.1, each row gives a text that the program reads, and the
  text has one line.
- A cell writes a text as its parts, in order, with commas between
  them. A part is characters between backticks; a space, a tab, a line
  feed, or a carriage return; a U+ numeral, for the character that it
  names; or a part, then "written", a decimal numeral, and "times", for
  that part as many times in a row as the numeral writes.
- For a valid input, a row names every value that the program gives,
  with two exceptions: the tag word of a tag line, and an inline
  description that is empty.
- In the result of a tag line, the word after "valid" names the value
  "the type of tag line", as in "valid declaration". The words "empty
  subject" name the empty text as the value "the subject".
- For a citation with two or more citation entries, a row names the
  values of the tag line first, and then the values of each citation
  entry after "entry 1:", "entry 2:", and so on. For a citation with
  one citation entry, a row names the values of the citation entry and
  of the tag line together.
- For an input that is not valid, the program gives no value, except the
  tag word of a tag line. A row of a tag line with another tag word
  names that tag word.
- The text after "invalid:", "not an inline citation:", or "no link
  and no image:" explains the result. A conforming program does not
  give it.

### 6.1 Tag lines

For the line `@cites gh/42`, the program gives no result for the id
pattern `[1-9][0-9]*` of `gh`, and none for the pair of that id pattern
and the id `42`, because neither is an input.

| line | result |
|---|---|
| `@req size-limit=v2 A descriptor has at most 1 MiB.` | valid declaration: slug `size-limit`, revision `v2`, inline description `A descriptor has at most 1 MiB.` |
| `   @design identifiers=v1` | valid declaration: slug `identifiers`, revision `v1` |
| `@req`, a tab, `size-limit=v2` | valid declaration: slug `size-limit`, revision `v2` |
| `see @req size-limit=v2` | not a tag line |
| `@param x The input.` | other tag word: `@param` |
| `@Req size-limit=v2` | other tag word: `@Req` |
| `@reqs size-limit=v2` | other tag word: `@reqs` |
| `@ alone` | other tag word: `@` |
| `@req:size-limit=v2` | invalid: no space or tab after `@req` |
| `@deprecated.` | invalid: no space or tab after `@deprecated` |
| `@deprecated`, a carriage return | invalid: a carriage return that no line feed follows is a character of the line, and it is not a space or a tab |
| `@deprecated`, a carriage return, a line feed | valid status tag |
| U+FEFF, `@req size-limit=v2` | valid declaration: slug `size-limit`, revision `v2` |
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
| `@term segment=v1` | valid declaration: slug `segment`, revision `v1` |
| `@term invoice` | valid declaration: slug `invoice` |
| `@term invoice The amount that a customer owes.` | valid declaration: slug `invoice`, inline description `The amount that a customer owes.` |
| `@term billing#invoice=v2` | valid declaration: slug `billing`, part name `invoice`, revision `v2` |
| `@term billing/terms#invoice` | valid declaration: slug `billing/terms`, custom namespace `billing`, part name `invoice` |
| `@term segment=` | invalid: no label after `=` |
| `@term segment=*` | invalid: the revision of a declaration is a label |
| `@term term:segment=v1` | invalid: the target of a declaration holds no kind word |
| `@term #segment=v1` | invalid: the target of `@term` is a slug or a full name |
| `@term gh` | invalid: the target is external, and the target of a declaration is never an external id |
| `@term gh/42` | invalid: the target is external, and the target of a declaration is never an external id |
| `@term gh/42#x` | invalid: the target is external, and the target of a declaration is never an external id |
| `@term {segment=v1}` | invalid: only a citation has a target list |
| `@Term segment=v1` | other tag word: `@Term` |
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
| `@cites docs=v3#size=v2` | invalid: a single target carries one revision at most |
| `@cites docs@3f2a9c=*` | invalid: a slug holds no `@` |
| `@cites docs=v3#size` | invalid: the revision of the part name `size` follows `size`, and a label holds no `#` |
| `@cites docs#a/b=v1` | invalid: `a/b` is not a part name |
| `@cites docs#a#b=v1` | invalid: a second `#` |
| `@cites plan:upkeep=*` | invalid: `plan` is not a kind word, and a slug holds no `:` |
| `@cites spec:docs=v2` | valid citation: kind word `spec`, slug `docs`, revision `v2` |
| `@cites term:docs#segment=v1` | valid citation: kind word `term`, slug `docs`, part name `segment`, revision `v1` |
| `@refines docs#size=v2` | valid citation: slug `docs`, part name `size`, revision `v2` |
| `@refines docs=*` | invalid: only `@cites` allows the revision `*` |
| `@satisfies docs#size=*` | invalid: only `@cites` allows the revision `*` |
| `@verifies spec:docs#size=v1` | valid citation: kind word `spec`, slug `docs`, part name `size`, revision `v1` |
| `@supersedes docs=v3#*` | valid citation: slug `docs`, revision `v3`, every part |
| `@supersedes docs#*=v3` | invalid: in an every-part target, the revision follows the slug |
| `@supersedes docs=*#*` | invalid: the revision of an every-part target is a label |
| `@cites docs=v3#*` | invalid: only `@supersedes` allows an every-part target |
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
| `@cites packs#descriptor[12]=v1` | valid citation: slug `packs`, part name `descriptor`, vector number `12`, revision `v1` |
| `@cites packs#descriptor[offsets][*]=v2` | valid citation: slug `packs`, part name `descriptor`, group name `offsets`, every vector, revision `v2` |
| `@cites packs#descriptor[*]=v3` | valid citation: slug `packs`, part name `descriptor`, every vector, revision `v3` |
| `@cites packs[37]=v1` | valid citation: slug `packs`, vector number `37`, revision `v1` |
| `@cites #descriptor[0]=v1` | valid citation: part name `descriptor`, vector number `0`, revision `v1` |
| `@cites spec:packs#descriptor[12]=*` | valid citation: kind word `spec`, slug `packs`, part name `descriptor`, vector number `12`, revision `*` |
| `@verifies packs#descriptor[12]=v1` | valid citation: slug `packs`, part name `descriptor`, vector number `12`, revision `v1` |
| `@verifies packs#descriptor[offsets][*]=v2` | valid citation: slug `packs`, part name `descriptor`, group name `offsets`, every vector, revision `v2` |
| `@verifies packs#descriptor[12]=*` | invalid: only `@cites` allows the revision `*` |
| `@refines packs#descriptor[12]=v1` | invalid: only `@cites` and `@verifies` allow a vector selection |
| `@satisfies packs#descriptor[*]=v1` | invalid: only `@cites` and `@verifies` allow a vector selection |
| `@supersedes packs[12]=v1` | invalid: only `@cites` and `@verifies` allow a vector selection |
| `@spec descriptor[12]=v1` | invalid: a declaration allows no vector selection |
| `@cites packs#descriptor[offsets]=v2` | invalid: a group name alone is not a vector selection |
| `@cites packs#descriptor[*][*]=v1` | invalid: `[*]` follows a name or a group name |
| `@cites packs#descriptor[012]=v1` | invalid: `012` is not a decimal numeral |
| `@cites packs#descriptor[]=v1` | invalid: `[]` is not a vector selection |
| `@cites packs#descriptor[12]` | invalid: no revision |
| `@cites packs#descriptor=v1[12]` | invalid: a label holds no `[` |
| `@cites gh/42[3]` | invalid: the target is external, and an id holds no `[` |
| `@cites gh[3]=v1` | invalid: the head is `gh`, so the target is external, and no `/` and id follow `gh` |
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
| `@cites {packs#descriptor[12]=v1, packs#descriptor[13]=v1}` | valid citation: entry 1: slug `packs`, part name `descriptor`, vector number `12`, revision `v1`; entry 2: slug `packs`, part name `descriptor`, vector number `13`, revision `v1` |
| `@cites {packs#descriptor=v1, packs#descriptor[*]=v1}` | valid citation: entry 1: slug `packs`, part name `descriptor`, revision `v1`; entry 2: slug `packs`, part name `descriptor`, every vector, revision `v1` |
| `@verifies packs#{descriptor[12]=v1, size[offsets][*]=v2}` | valid citation: entry 1: slug `packs`, part name `descriptor`, vector number `12`, revision `v1`; entry 2: slug `packs`, part name `size`, group name `offsets`, every vector, revision `v2` |
| `@cites {packs#descriptor[12]=v1, packs#descriptor[12]=v2}` | invalid: two citation entries have the entry name `packs#descriptor` and the vector selection `[12]` |
| `@cites packs#{descriptor[*]=v1, descriptor[*]=v2}` | invalid: two citation entries have the entry name `packs#descriptor` and the vector selection `[*]` |
| `@refines packs#{descriptor[12]=v1}` | invalid: only `@cites` and `@verifies` allow a vector selection |
| `@cites {}` | invalid: a target list holds one single target or scoped list at least |
| `@cites {docs=v1,}` | valid citation: slug `docs`, revision `v1` |
| `@cites packs#{size=v1, descriptor=v2,}` | valid citation: entry 1: slug `packs`, part name `size`, revision `v1`; entry 2: slug `packs`, part name `descriptor`, revision `v2` |
| `@cites {docs=v1,,}` | invalid: a single target or a scoped list stands between each two `,` |
| `@cites {,}` | invalid: a target list holds one single target or scoped list at least |
| `@cites {docs=v1 docs#size=v2}` | invalid: a `,` separates two single targets |
| `@cites {#a=v1, req:#a=v2}` | invalid: two citation entries have the entry name `#a` and no vector selection |
| `@cites packs#{size=v1, size=v2}` | invalid: two citation entries have the entry name `packs#size` and no vector selection |
| `@cites {packs#size=v1, packs#{size=v2}}` | invalid: two citation entries have the entry name `packs#size` and no vector selection |
| `@supersedes {docs=v3#*, docs=v1}` | invalid: two citation entries have the entry name `docs` and no vector selection |
| `@cites {gh/42, spec:gh/42}` | invalid: two citation entries have the entry name `gh/42` and no vector selection |
| `@cites {docs=v1` | invalid: no line follows to close the target list |
| `@cites {docs=v1}x` | invalid: no space or tab after the `}` |
| `@cites {{docs=v1}}` | invalid: a target list holds no target list |
| `@cites packs#{size=v1, {docs=v1}}` | invalid: a scoped list holds no target list |
| `@cites packs#{req:size=v1}` | invalid: a scoped list holds no kind word between its braces |
| `@cites packs#{size}` | invalid: each part of a scoped list has `=` and a revision |
| `@cites packs#{}` | invalid: a scoped list holds one part at least |
| `@refines {docs=*}` | invalid: only a citation entry of `@cites` carries `*` |
| `@refines packs#{size=*}` | invalid: only a citation entry of `@cites` carries `*` |
| `@verifies {gh/42=v1}` | invalid: the citation entry is external, and an id holds no `=` |
| `@cites gh#{size=v1}` | invalid: the citation entry `gh#size=v1` is external, and no `/` and id follow `gh` |
| `@cites {docs=v3#*}` | invalid: only `@supersedes` allows an every-part target |
| `@supersedes docs#{*=v3}` | invalid: `*` is not a part name |
| `@design {docs=v1}` | invalid: only a citation has a target list |
| `@req packs#{size=v1}` | invalid: only a citation has a scoped list |
| `@extern spec:descriptor` | valid directive: kind word `spec`, part name `descriptor` |
| `@extern spec:gh` | valid directive: kind word `spec`, part name `gh` |
| `@extern spec:descriptor=v1` | invalid: the target of `@extern` carries no revision |
| `@extern descriptor` | invalid: no kind word |
| `@extern spec:packs#descriptor` | invalid: the target of `@extern` holds no `#` |
| `@ack retired docs#size=v2 3f2a9c1d` | valid directive: slug `retired`, subject `docs#size=v2`, hash prefix `3f2a9c1d` |
| `@ack unexercised 3f2a9c1d0b7e` | valid directive: slug `unexercised`, empty subject, hash prefix `3f2a9c1d0b7e` |
| `@ack retired a @b 3f2a9c1d` | valid directive: slug `retired`, subject `a @b`, hash prefix `3f2a9c1d` |
| `@ack retired 3f2a9c1d`, a space written 2 times | valid directive: slug `retired`, empty subject, hash prefix `3f2a9c1d` |
| `@ack retired docs#size=v2`, a space written 2 times, `3f2a9c1d` | valid directive: slug `retired`, subject `docs#size=v2`, hash prefix `3f2a9c1d` |
| `@ack retired`, a space, `0123456789abcdef` written 4 times | valid directive: slug `retired`, empty subject, hash prefix `0123456789abcdef` written 4 times |
| `@ack retired`, a space, `0123456789abcdef` written 4 times, `0` | invalid: the hash prefix has more than 64 digits |
| `@ack retired 3F2A9C1D` | invalid: the hash prefix holds upper-case letters |
| `@ack retired 3f2a9c` | invalid: the hash prefix has fewer than 8 digits |
| `@ack 3f2a9c1d` | invalid: `3f2a9c1d` is the slug, and no hash prefix follows it |

### 6.2 Citations over several lines

Each row gives the lines of a text that the program reads, in their
order, with semicolons between them. The text has no other line. A
citation and its continuation lines are one input, and a continuation
line gets no result of its own. When a row holds another input after the
citation, its result names that input. In a result, "; then" starts the
result of the next input. What follows it names that input and gives its
result, and it is not an explanation.

| lines | result |
|---|---|
| `@cites {`; `#notation=v1,`; `#characters=v1`; `}` | valid citation: entry 1: part name `notation`, revision `v1`; entry 2: part name `characters`, revision `v1` |
| `@cites #{`; a space written 4 times, `notation=v1, characters=v1,`; a space written 4 times, `segments=v1,`; `}` | valid citation: entry 1: part name `notation`, revision `v1`; entry 2: part name `characters`, revision `v1`; entry 3: part name `segments`, revision `v1` |
| `@cites {docs=v1,`; `docs#size=v2,`; `} The docs.` | valid citation: inline description `The docs.`; entry 1: slug `docs`, revision `v1`; entry 2: slug `docs`, part name `size`, revision `v2` |
| `@cites {identifiers#{`; `segments=v1,`; `notation=v1}, gh/42}` | valid citation: entry 1: slug `identifiers`, part name `segments`, revision `v1`; entry 2: slug `identifiers`, part name `notation`, revision `v1`; entry 3: namespace name `gh`, id `42` |
| `@cites {`; the empty text; `docs=v1}` | invalid: a blank line follows before the closing `}`; then the blank line is an input of its own: not a tag line; then the line `docs=v1}` is an input of its own: not a tag line |
| `@cites {`; a space written 2 times; `docs=v1}` | invalid: a blank line follows before the closing `}`; then the blank line is an input of its own: not a tag line; then the line `docs=v1}` is an input of its own: not a tag line |
| `@cites {docs`; `=v1}` | invalid: a citation entry does not break across lines |
| `@cites {docs=v1,` | invalid: no line follows to close the target list |
| `@cites {docs=v1,`; `@req size-limit=v2` | invalid: a tag line follows before the closing `}`; then the line `@req size-limit=v2` is an input of its own: valid declaration: slug `size-limit`, revision `v2` |
| `@cites`; `{docs=v1}` | invalid: no target; then the line `{docs=v1}` is an input of its own: not a tag line |
| `@cites docs=v1 {`; `x}` | valid citation: slug `docs`, revision `v1`, inline description `{`; then the line `x}` is an input of its own: not a tag line |

### 6.3 Inline citations

Each row gives a text that the program reads. The markdown document of
the text holds one link or one image, a link inside the link text of
another link, or no link and no image. The lines of each text are inputs
too. None of these lines is a tag line, so each of them gets the result
"not a tag line", which no row repeats. When a row holds a link inside
the link text of another link, the result is the result of the outer
link. The inner link gets a result of its own, which the row does not
repeat: `<https://example.com>` gets the result "not an inline
citation".

| text | result |
|---|---|
| `[the size limit](sinter:req:packs#size-limit=v2)` | valid: link text `the size limit`, kind word `req`, slug `packs`, part name `size-limit`, revision `v2` |
| `[the size limit](sinter:req:packs#size-limit)` | invalid: no revision |
| `[any revision](sinter:packs#size-limit=*)` | valid: link text `any revision`, slug `packs`, part name `size-limit`, revision `*` |
| `[](sinter:packs#size-limit=v2)` | invalid: the plain string content of the link text is empty |
| `[ ](sinter:packs#size-limit=v2)` | invalid: the plain string content of the link text is one space |
| `[&nbsp;](sinter:packs#size-limit=v2)` | invalid: the plain string content of the link text is U+00A0, a blank character |
| `[<!-- -->](sinter:packs#size-limit=v2)` | invalid: raw HTML gives no plain string content |
| `> [`, a line feed, `> ](sinter:packs#size-limit=v2)` | invalid: the plain string content of the link text is a line feed |
| `> [the`, a line feed, `> limit](sinter:packs#size-limit=v2)` | valid: link text `the`, a line feed, and `limit`, slug `packs`, part name `size-limit`, revision `v2` |
| `[the`, a line feed, a space written 3 times, `limit](sinter:packs#size-limit=v2)` | valid: link text `the`, a line feed, and `limit`, slug `packs`, part name `size-limit`, revision `v2` |
| `[the`, a carriage return, `limit](sinter:packs#size-limit=v2)` | valid: link text `the`, a line feed, and `limit`, slug `packs`, part name `size-limit`, revision `v2` |
| `[<https://example.com>](sinter:packs#size-limit=v2)` | valid: link text `<https://example.com>`, slug `packs`, part name `size-limit`, revision `v2` |
| `[`, U+200B, `](sinter:packs#size-limit=v2)` | invalid: the plain string content of the link text is U+200B, a blank character |
| `[`, U+200C, `](sinter:packs#size-limit=v2)` | invalid: the plain string content of the link text is U+200C, a blank character |
| `[`, U+200D, `](sinter:packs#size-limit=v2)` | invalid: the plain string content of the link text is U+200D, a blank character |
| `[`, U+2060, `](sinter:packs#size-limit=v2)` | invalid: the plain string content of the link text is U+2060, a blank character |
| `[`, U+FEFF, `](sinter:packs#size-limit=v2)` | invalid: the plain string content of the link text is U+FEFF, a blank character |
| `[`, U+200B, `x](sinter:packs#size-limit=v2)` | valid: link text U+200B and `x`, slug `packs`, part name `size-limit`, revision `v2` |
| `[**](sinter:packs#size-limit=v2)` | valid: link text `**`, slug `packs`, part name `size-limit`, revision `v2` |
| `[the limit](sinter:#size-limit=v2)` | valid: link text `the limit`, part name `size-limit`, revision `v2` |
| `[RFC 8259](sinter:spec:rfc/8259)` | valid: link text `RFC 8259`, kind word `spec`, namespace name `rfc`, id `8259` |
| `[x](sinter:gh/42=v2)` | invalid: the target is external, and an id holds no `=` |
| `[auth](sinter:billing/auth=v3)` | valid: link text `auth`, slug `billing/auth`, custom namespace `billing`, revision `v3` |
| `[auth](sinter:billing/auth)` | invalid: no revision |
| `[auth][r]`, a line feed, a line feed, `[r]: sinter:billing/auth=v3` | valid: link text `auth`, slug `billing/auth`, custom namespace `billing`, revision `v3` |
| `<sinter:req:packs#size-limit=v2>` | valid: link text `sinter:req:packs#size-limit=v2`, kind word `req`, slug `packs`, part name `size-limit`, revision `v2` |
| `[*the* limit](sinter:packs#size-limit=v2)` | valid: link text `*the* limit`, slug `packs`, part name `size-limit`, revision `v2` |
| `[x](sinter:packs\#size-limit=v2)` | valid: link text `x`, slug `packs`, part name `size-limit`, revision `v2` |
| `[x](sinter:packs&#35;size-limit=v2)` | valid: link text `x`, slug `packs`, part name `size-limit`, revision `v2` |
| `[x](sinter:&#65;uth=v1)` | valid: link text `x`, slug `Auth`, revision `v1` |
| `[x](sinter:packs%23size-limit=v2)` | invalid: `%23` is three characters, and a segment holds no `%` |
| `[x](sinter:docs=v3#*)` | invalid: only `@supersedes` allows an every-part target |
| `[x](sinter:)` | invalid: no target |
| `[x](sinter:plan:upkeep=v1)` | invalid: `plan` is not a kind word, and a slug holds no `:` |
| `[x](sinter:docs@3f2a9c=v1)` | invalid: a slug holds no `@` |
| `[x](sinter:gh)` | invalid: the target is external, and no `/` and id follow `gh` |
| `[x](sinter:{docs=v1})` | invalid: an inline citation cites one target |
| `[x](sinter:packs#{size=v1})` | invalid: an inline citation cites one target |
| `[x](sinter:packs#descriptor[12]=v1)` | invalid: an inline citation allows no vector selection |
| `[x](Sinter:req:packs#size-limit=v2)` | not an inline citation: the destination does not start with `sinter:` |
| `![x](sinter:packs#size-limit=v2)` | not an inline citation: an image is not a link |
| U+FEFF, a space written 4 times, `[x](sinter:docs=v1)` | no link and no image: the markdown document is the body of the text, which is an indented code block |

### 6.4 Id patterns

Each item gives an id pattern, as an input, and its result. For a
valid id pattern, it also gives ids that fit it and ids that do not fit
it. For the pair of the id pattern and an id that fits it, the program
gives the result "fits". For the pair of the id pattern and an id that
does not fit it, the program gives the result "does not fit".

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
- `()`: invalid: a subpattern holds a pattern.
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

### 6.5 Bindings of `external-namespaces`

| binding | result |
|---|---|
| the empty set | valid |
| `gh` with `[1-9][0-9]*` | valid |
| `my-tracker` with `[A-Z]+-[1-9][0-9]*` | valid |
| `GH` with `[1-9][0-9]*` | invalid: `GH` does not match `namespace-name` |
| `my--tracker` with `[1-9][0-9]*` | invalid: `my--tracker` does not match `namespace-name` |
| `9ns` with `[1-9][0-9]*` | invalid: `9ns` does not match `namespace-name` |
| `gh` with `[1-9][0-9]*`, and `gh` with `[a-z]+` | invalid: two pairs of the binding have the namespace name `gh` |
| `gh` with `[0-9]*` | invalid: the empty id fits the id pattern; the id pattern `[0-9]*` gets no result of its own, because it is not an input |
