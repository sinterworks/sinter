<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Identifiers
@design identifiers=v1
@cites text=v1
@cites rfc/5234
@cites rfc/7405
@cites rfc/8259
@cites commonmark/0.31.2
Specifies the grammar of tags, identifiers, and links as used in Sinter, the canonical forms of identifiers and citation entries, and requirements for conforming programs.

A tag line starts, after any spaces and tabs, with a tag word such as
`@req`. A declaration, such as `@req size-limit=v2`, is a tag line that
yields a name and a revision. Only a declaration with the tag word
`@term` can leave out the revision. A citation, such as
`@cites catalog#size-limit=v2`, is a tag line that yields what it cites:
a name and a revision, a name and a vector selection, or an external id.
A citation can also cite several things in a target list or a scoped
list, such as `@cites {#notation=v1, gh/42}` and
`@cites catalog#{size=v1, descriptor=v2}`. A vector selection, such as
`[offsets]` in `@verifies catalog#descriptor[offsets]`, can follow the
name in place of a revision in a single target of `@cites` or
`@verifies`. An inline citation is a link in the markdown document of a
text. An inline citation cites in the same way.

The productions use ABNF (RFC 5234), with the case-sensitive strings of
RFC 7405.

From Text and notation (`text`), the design takes the basics of
characters, texts, runs, lines, numerals, and productions; sequences and
algorithms; canonical vector lines for the vector file of the design;
and what a conforming program and a result are. The design narrows what
an input is. From CommonMark 0.31.2, the design takes the links and
images of CommonMark 0.31.2, the link destinations of those links and
images, and the block and inline elements that hold those links and
images. From RFC 8259, the design takes JSON texts, with their objects,
members, arrays, strings, numbers, and the literal name `true`. Each
line of the file that holds the conformance vectors of the design is a
JSON text.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [conforming program](sinter:text#conforming-program=v1) | a program, or a part of a program, that meets every requirement of a design |
| [production](sinter:text#production=v1) | a rule of ABNF, such as `slug = segment *( "/" segment )`, which gives the texts that its rule name, here `slug`, matches |
| [character](sinter:text#character=v1) | a character, whose code point is a Unicode scalar value: a code point that is not from U+D800 to U+DFFF |
| [text](sinter:text#text=v1) | a finite sequence of characters |
| [run](sinter:text#run=v1) | a sequence of the characters of a text between two of its boundaries, whose characters keep their places in the text |
| [line](sinter:text#line=v1) | one of the runs into which the line endings of a text divide the body of that text; a line holds no line feed; a byte order mark is on no line; an empty run at the end of the body is no line |
| [body](sinter:text#body=v1) | the run of a text that starts at boundary 1 when the text has a byte order mark, and at boundary 0 when it has none, and that ends at the last boundary of the text |
| [line ending](sinter:text#line-ending=v1) | a run of a text that holds a line feed of the body and, when a carriage return of the body is right before that line feed, that carriage return, and that holds no other character |
| [byte order mark](sinter:text#byte-order-mark=v1) | the character U+FEFF at place 1 of a text |
| [hex digit](sinter:text#hex-digit=v1) | one of the characters `0` to `9` and `a` to `f`, which write the whole numbers 0 to 15 |
| [decimal numeral](sinter:text#decimal-numeral=v1) | a text of the characters `0` to `9` that writes a whole number of 0 or more in base 10, and whose first character is not `0` unless the text is `0`, such as `42` |
| printable ASCII character | a character from `!` to `~`; a space is not one |
| [tag line](sinter:#tag-line=v1) | a line whose first character, after the spaces and tabs at its start, is `@` |
| [tag word](sinter:#tag-word=v1) | the `@` that starts a tag line after its spaces and tabs, with the longest run of ASCII letters, ASCII digits, and `-` right after that `@`, such as `@req` |
| [Sinter tag word](sinter:#sinter-tag-word=v1) | one of the fifteen tag words of Sinter, such as `@req` and `@cites` |
| [declaration](sinter:#declaration=v1) | a tag line whose tag word is `@atom`, `@decision`, `@design`, `@req`, `@schema`, `@spec`, or `@term`, such as `@req size-limit=v2`; the schema `declaration-line` gives its [form](sinter:#declaration-line=v1) |
| [citation](sinter:#citation=v1) | a tag line whose tag word is `@cites`, `@refines`, `@satisfies`, `@supersedes`, or `@verifies`, such as `@cites catalog#size-limit=v2` |
| [status tag](sinter:#status-tag=v1) | a tag line with `@deprecated`, which has no target; the schema `status-line` gives its [form](sinter:#status-line=v1) |
| [directive](sinter:#directive=v1) | a tag line with `@ack` or `@extern`, each of which has a form of its own |
| [`@extern` line](sinter:#directive=v1) | a directive with the tag word `@extern`, such as `@extern spec:descriptor`; the schema `extern-line` gives its [form](sinter:#extern-line=v1) |
| [`@ack` line](sinter:#directive=v1) | a directive with the tag word `@ack`, such as `@ack retired docs#size=v2 3f2a9c1d`; the schema `ack-line` gives its [form](sinter:#ack-line=v1) |
| [continuation line](sinter:#continuation-line=v1) | a line that continues the target of a citation on a line before that continuation line, while the brace count has more `{` than `}`; the brace count is the number of `{` and the number of `}` from the start of the target; only a citation in which the character right after the tag word is a space or a tab has continuation lines; a continuation line is never a tag line or a blank line |
| [blank line](sinter:#continuation-line=v1) | a line that is empty or holds only spaces and tabs |
| [text of a tag line](sinter:#tag-line-text=v1) | the text of the line of the tag line, and, for a citation, the texts of the continuation lines of that citation after the text of the line of that citation, each after a line feed and without the spaces and tabs at the start of that continuation line |
| [link](sinter:#link=v1) | an inline link, a reference link, or an autolink of a markdown document, as CommonMark 0.31.2 defines them; an image is not a link; the markdown document of a text is the text of its body |
| [image](sinter:#link=v1) | an inline image or a reference image of CommonMark 0.31.2; an image is not a link |
| [destination](sinter:#destination=v1) | the link destination of an inline link or a reference link, or the URI of an autolink, as CommonMark 0.31.2 gives it, such as `sinter:catalog#size-limit=v2` in `[the limit](sinter:catalog#size-limit=v2)`, with no percent-encoding and no percent-decoding |
| [link text](sinter:#link-text=v1) | the text between the `[` that starts an inline link or a reference link and the `]` that closes that `[`, in the raw content that holds the link, such as `the limit` in `[the limit](sinter:catalog#size-limit=v2)`; an autolink has no brackets, and its link text is its text between `<` and `>`, with no backslash escape, entity reference, or numeric character reference replaced |
| [line of CommonMark 0.31.2](sinter:#link-text=v1) | a line as CommonMark 0.31.2 gives it |
| [raw content](sinter:#link-text=v1) | the text of the lines of a paragraph or a heading, joined by line feeds, without the marks of the blocks, such as `>`, `#`, and the underline of a setext heading, and without indentation |
| [inline citation](sinter:#inline-citation=v1) | a link whose destination starts with `sinter:`; the schema `inline-destination` gives the [form](sinter:#inline-destination=v1) of its destination |
| [target](sinter:#target=v1) | for a declaration, a citation, or an `@extern` line, the text after the tag word and the spaces and tabs that follow that tag word, up to the first space or tab before which the text from the start of the target holds no more `{` than `}`, or up to the end of the text of the tag line; also the destination of an inline citation after `sinter:` |
| [inline description](sinter:#inline-description=v1) | the text of a tag line after the target of that tag line, or after the tag word of a status tag, without the spaces and tabs at the start of that text; an `@ack` line has no inline description |
| [segment](sinter:#segment=v1) | a text of ASCII letters and ASCII digits, with one `-`, `_`, or `.` at most between two of them, such as `size-limit` |
| [slug](sinter:#slug=v1) | one segment, or several segments joined by `/`, such as `catalog` or `billing/auth` |
| [custom namespace](sinter:#give-values=v1) | the text of a slug before its last `/`, such as `billing` in `billing/auth` and `a/b` in `a/b/c` |
| [part name](sinter:#part-name=v1) | a segment, such as `descriptor` in `catalog#descriptor` |
| [full name](sinter:#full-name=v1) | a slug, `#`, and a part name, such as `catalog#descriptor` |
| [name](sinter:#name=v1) | a slug, a full name, or `#` and a part name |
| [kind word](sinter:#kind-word=v1) | one of seven words, such as `req`, that can stand with a `:` at the start of a target, as in `req:catalog#size-limit=v2` |
| [label](sinter:#label=v1) | a text of printable ASCII characters other than `/`, `#`, `@`, `*`, `=`, `,`, `{`, `}`, `[`, and `]`, such as `v2` |
| [revision](sinter:#revision=v1) | a label, or `*`, which stands for any label; in a target, a revision follows a name and `=`, as `v2` in `docs#size=v2` and `v3` in `docs=v3#*` |
| [every-part target](sinter:#citation-line=v1) | a slug, `=`, a label, and `#*`, such as `docs=v3#*` |
| [vector selection](sinter:#vector-selection=v1) | `[`, a group name, and `]`, or `[*]`; a vector selection can follow the name in place of a revision in a single target of `@cites` or `@verifies`, such as `[offsets]` in `catalog#descriptor[offsets]`; a vector selection gives a group name or every vector |
| [group name](sinter:#vector-selection=v1) | the name in a vector selection: lower-case ASCII letters and ASCII digits that start with a letter, with one `-` at most between two of them, such as `offsets` in `[offsets]` |
| [scoped list](sinter:#citation-entry=v1) | an optional kind word and `:`, an optional slug, `#{`, part names, each with a revision or a vector selection, separated by `,`, and `}`, such as `catalog#{size=v1, descriptor=v2}`, which stands for `catalog#size=v1` and `catalog#descriptor=v2` |
| target list | `{`, one or more single targets or scoped lists separated by `,`, and `}`: a target of a citation, such as `{#notation=v1, gh/42}` |
| [single target](sinter:#citation-entry=v1) | a target, or an element of a target list, that is neither a target list nor a scoped list, such as `catalog#size=v1` |
| [citation entry](sinter:#citation-entry=v1) | a single target of a citation, or a single target for which a part of a scoped list stands |
| [entry name](sinter:#citation-entry=v1) | the name in a citation entry: its slug, its full name, its `#` and part name, or its external id with its `#` and part name; for an every-part target, its slug |
| [canonical identifier](sinter:#canonical-id=v1) | a kind word, `:`, and a slug, a full name, or an external id with an optional `#` and part name, such as `req:catalog#size-limit`; or, with no kind word, the slug, the full name, or the external id alone, such as `gh/42` |
| [canonical form of a citation entry](sinter:#canonical-entry=v1) | the text that gives one name to a citation entry or to the target of an inline citation, with a slug or no slug and a kind word or no kind word, such as `term:docs#notation` for `#notation=v1` with the slug `docs` and the kind word `term`; a canonical form of a citation entry holds no revision |
| parameter | a word, such as `external-namespaces`, for which a conforming program takes a binding |
| [`external-namespaces`](sinter:#external-namespaces=v1) | the parameter whose bindings give the external namespaces; the schema `external-namespaces` gives the form of a binding |
| [binding](sinter:#external-namespaces=v1) | a finite set of pairs of a namespace name and an id pattern, which a conforming program takes for the parameter `external-namespaces` |
| [external namespace](sinter:#external-namespace=v1) | a pair of a binding, with its namespace name and its id pattern; the external namespaces of a line, a link, or an image are those of the binding under which a conforming program reads it |
| [namespace name](sinter:#external-namespaces=v1) | the text of a pair of a binding that names its external namespace, such as `gh`; a namespace name can match the production [`namespace-name`](sinter:#namespace-name=v1) or not |
| [external id](sinter:#external-id=v1) | a namespace name, `/`, and an id, such as `gh/42` |
| [id](sinter:#id=v1) | a text for which a conforming program decides whether that text has the form that an id pattern gives, such as `42` in `gh/42` |
| [id pattern](sinter:#id-pattern=v1) | a text that a conforming program takes as a pattern, on its own or with other texts, such as an id, or a namespace name in a pair of a binding; that text is an id pattern whether or not that text matches the production `pattern` |
| [class member](sinter:#id-pattern=v1) | one element of a character class of an id pattern: a character, or a range such as `0-9` |
| [valid id pattern](sinter:#valid-id-pattern=v1) | an id pattern that matches `pattern`, uses no reversed range and no reversed quantifier bounds, and that the empty id does not fit |
| [fit](sinter:#fit=v1) | an id fits an id pattern when the id has the form that the id pattern gives, such as `42` for `[1-9][0-9]*` |
| [head](sinter:#external-target=v1) | the text of a target or a citation entry without its kind word and the `:` after that kind word, up to its first `#`, `=`, or `[` |
| [external target](sinter:#external-target=v1) | the target of a declaration or of an inline citation, or a citation entry, whose head starts with the namespace name of an external namespace of its tag line or its inline citation, followed by `/` or by the end of the head |
| [plain string content](sinter:#plain-string-content=v1) | the text that a link text shows without its markup, such as `the limit` for `*the* limit` |
| [blank character](sinter:#blank-character=v1) | a Unicode whitespace character of CommonMark 0.31.2, such as a space, a tab, a line feed, or U+00A0, the no-break space; or one of U+200B, U+200C, U+200D, U+2060, and U+FEFF, such as U+200B, the zero width space |
| [input](sinter:#input=v1) | a line of a text that a conforming program reads, other than a continuation line, because a citation and its continuation lines are one input; a link or an image of the markdown document of such a text; an id pattern that the program takes on its own or in a pair of an id pattern and an id; a binding of `external-namespaces` that the program takes or under which it reads; a pair of an id pattern and an id that the program takes, when the program accepts the id pattern of that pair; the id patterns of a binding belong to the binding and are not inputs of their own |
| [match](sinter:#match=v1) | one way in which a production matches the whole of a text, by one set of the choices of that production, such as one alternative at each `/` and one number of repetitions at each repetition; in a match, each use of a rule through a rule name matches a run of the text, and the match uses that rule |
| [match of an input](sinter:#input-match=v1) | a match of the text of a tag line by the production for its kind of tag line, or of the destination of an inline citation by `inline-destination`, in which the target of a declaration is not an external target; each other external target, without its kind word and the `:` after that kind word, matches `external-ref`; and in each run that `external-id` matches, the text that `namespace-name` matches is the namespace name of an external namespace, and the text that `id-text` matches fits the id pattern of that external namespace |
| [line result](sinter:#line-result=v1) | the result for a line that is an input under a binding of `external-namespaces` that meets the schema `external-namespaces`: "not a tag line", "other tag word", "valid", or "invalid" |
| [link result](sinter:#link-result=v1) | the result for a link or an image that is an input under a binding of `external-namespaces` that meets the schema `external-namespaces`: "not an inline citation", "valid", or "invalid" |
| [result](sinter:text#result=v1) | a text that a requirement shows between two double quotes, such as "valid", "not a tag line", or "fits", as one of the cases of what a conforming program gives for an input |
| accept, reject | to give the result "valid" for an input, and to give the result "invalid" for an input |
| [value](sinter:#value=v1) | a text or a fact that a conforming program gives for an input together with the result of that input, under a value name, which tells what the value is, such as the tag word of a tag line under the value name the tag word; the program gives a value under a value name when the program gives the value together with something that stands for that value name and for no other value name; the program gives a fact when the program gives something that stands for that fact and for no other fact |

## 2. The written forms

### 2.1 Tag lines and tag words

A conforming program reads the lines of texts. A line holds no line
feed. The line feeds of a text, each with the carriage return right
before that line feed when there is one, divide the text into lines. A
U+FEFF at the start of a text is on no line. A line is a tag line when
its first character, after the spaces and tabs at its start, is `@`.
Every such line is a tag line, whatever its tag word is.

The tag word of a tag line is its `@` and the longest sequence of ASCII
letters, ASCII digits, and `-` right after that `@`. The sequence can be
empty.

| line | tag word |
|---|---|
| `@req size-limit=v2` | `@req` |
| `   @atom late-fee=v1` | `@atom` |
| `@foo-bar: text` | `@foo-bar` |
| `@param x The input.` | `@param` |
| `@ alone` | `@` |
| `see @req size-limit=v2` | none: the line is not a tag line |

Sinter has fifteen tag words. A tag word is a Sinter tag word only when
that tag word is the same text as one of those fifteen tag words, so
`@Req` and `@reqs` are not Sinter tag words. For a tag line whose tag
word is not a Sinter tag word, a conforming program gives the result
"other tag word" and the tag word, and nothing more.

A Sinter tag word makes its tag line a declaration, a citation, a status
tag, or a directive. The tag word also sets the form of the line and of
its target, which the productions `declaration-line`, `citation-line`,
`status-line`, `extern-line`, and `ack-line` give. For example, the
target of `@req` is a slug or a full name with a label as its revision,
and a status tag, `@deprecated`, has no target.

In a declaration, a citation, and an `@extern` line, one or more spaces
or tabs follow the tag word, and the target follows those spaces or
tabs. The target ends at the next space or tab outside the braces of a
target list or a scoped list, or at the end of the line. The target of a
citation can also be a target list or a scoped list. A target list or a
scoped list can hold spaces, tabs, and line feeds of the text of the
citation between the braces of that list. A target list or a scoped list
can continue on the lines after the line of the citation (section 2.7).
The inline description is the text after the target, without the spaces
and tabs at the start of that text. A status tag has no target. The
inline description of a status tag is the text after the tag word of
that status tag, without the spaces and tabs at the start of that text.
Example: in `@req size-limit=v2 A descriptor has at most 1 MiB.`, the
target is `size-limit=v2`, and the inline description is
`A descriptor has at most 1 MiB.`.

In a valid tag line, the character right after a Sinter tag word is a
space or a tab, or the line ends there. So `@req:size-limit=v2` and
`@deprecated.` are invalid.

### 2.2 Names

A segment is a text of ASCII letters and ASCII digits, with one `-`,
`_`, or `.` at most between two of them. Examples of segments are
`catalog`, `size-limit`, `my_docs.v2`, and `Auth`. The texts `-docs`,
`docs-`, `docs--x`, and `docs x` are not segments.

A slug is one segment, such as `catalog`, or several segments joined by
`/`, such as `billing/auth`. The text of a slug before its last `/` is
the custom namespace of the slug: `billing` in `billing/auth`, and
`a/b` in `a/b/c`.

A part name is one segment. A full name is a slug, `#`, and a part
name, such as `catalog#descriptor` or `billing/auth#lockout`. A target
can also hold `#` and a part name with no slug before the `#`, as in
`#descriptor=v1`. A name is a slug, a full name, or `#` and a part
name.

A conforming program gives each name with its case unchanged, so
`Auth-Lockout` and `auth-lockout` stay two different texts.

### 2.3 Kind words

The seven kind words are `atom`, `decision`, `design`, `req`, `schema`,
`spec`, and `term`. A kind word stands at the start of a target, with a
`:` after that kind word: `req:catalog#size-limit=v2`, `spec:rfc/8259`.

A single target of a citation, a scoped list, and the target of an
inline citation can start with a kind word. The target of `@extern`
always starts with a kind word. The target of a declaration holds no
kind word. An every-part target holds no kind word. A name holds no `:`.
So the target `plan:upkeep=*` is invalid: `plan` is not a kind word, and
`plan:upkeep` is not a slug.

### 2.4 Revisions

A revision is a label or `*`. A label is a text of printable ASCII
characters other than `/`, `#`, `@`, `*`, `=`, `,`, `{`, `}`, `[`, and
`]`, such as `v2`, `2026-11`, `v1.2.0`, or `rc1`. `*` stands for any
label.

A revision follows a name after `=`. A single target (section 2.7)
carries one revision at most.

| target | name | revision |
|---|---|---|
| `docs=v3` | the slug `docs` | `v3` |
| `billing/auth=v3` | the slug `billing/auth` | `v3` |
| `docs#size=v2` | the full name `docs#size` | `v2` |
| `#size=v2` | `#` and the part name `size` | `v2` |
| `docs=*` | the slug `docs` | `*` |
| `docs#size=*` | the full name `docs#size` | `*` |

Each single target of a declaration or a citation, and the target of an
inline citation, carries a revision, except an external target, a target
with a vector selection (section 2.6), and the target of `@term`. The
target of `@term` carries a revision or none, so `@term segment=v1` and
`@term invoice` are both valid. The revision of a declaration is a
label. The revision of a single target of `@cites`, and of the target of
an inline citation, is a label or `*`. The revision of a single target
of a citation whose tag word is `@refines`, `@satisfies`, `@supersedes`,
or `@verifies` is a label. The target of `@extern` carries no revision.
An `@ack` line carries no revision.

A revision has no default. So a declaration other than `@term`, or a
citation, is invalid when it has a single target that is not external,
has no vector selection, and carries no revision. An inline citation
whose target is not external and carries no revision is invalid too. For
example, `@cites billing/auth` and `@design billing/auth` are invalid:
neither target carries a revision.

The target ends at the first space or tab outside the braces of a target
list or a scoped list, so in `@cites docs=v1; and more` the label is
`v1;`. A label holds no `=`, `,`, `{`, `}`, `[`, or `]`, so
`@cites docs=v=1` and `@cites docs=v1, and more` are invalid.

An every-part target is a slug, `=`, a label, and `#*`, such as
`docs=v3#*`. Only a single target of `@supersedes` can be an every-part
target. The revision of an every-part target follows the slug. That
revision is a label. So `@supersedes docs#*=v3` and
`@supersedes docs=*#*` are invalid. An every-part target holds no kind
word, so `@supersedes design:docs=v3#*` is invalid.

### 2.5 External ids

The parameter `external-namespaces` (section 3) gives the external
namespaces. Each external namespace has a namespace name, such as `gh`,
and an id pattern. An external id is a namespace name, `/`, and an id,
such as `gh/42`. The id of an external id is a text of printable ASCII
characters other than `#`, `/`, `=`, `@`, `,`, `{`, `}`, `[`, and `]`.
The id of an external id fits the id pattern of the external namespace.
An external id allows `#` and a part name after it, as in
`rfc/8259#section-6`. An external id carries no revision.

One rule decides whether a single target (section 2.7) or a citation
entry holds an external id. The head of a single target or a citation
entry is its text after its kind word and the `:` after the kind word,
and before its first `#`, `=`, or `[`. When the head starts with a
namespace name, followed by `/` or by the end of the head, the single
target or the citation entry is an external target. A conforming program
interprets an external target only as an external id, with an optional
`#` and part name after that external id. A conforming program
interprets no other single target and no other citation entry as an
external id. The target of `@extern` is never an external target, so
`@extern spec:gh` is valid under a binding with the external namespace
`gh`.

So the binding of `external-namespaces` decides the meaning of a target.
When `gh` is a namespace name of the binding, `@cites gh/42` cites the
external id `gh/42`. When `gh` is not a namespace name of the binding,
the target `gh/42` is the slug `gh/42`. When `gh` is not a namespace
name of the binding, `@cites gh/42` is invalid, because the target
`gh/42` carries no revision. When `gh` is not a namespace name of the
binding, `@cites gh/42=v1` is valid. Under a binding with the external
namespace `gh`:

- `@cites gh/42=v1` is invalid, because the target is external, and an
  id holds no `=`.
- `@cites gh=v1` is invalid: its head is `gh`, so the target is
  external, and no `/` and id follow `gh`.

### 2.6 Vector selections

A vector selection can follow the name in place of a revision in a
single target of `@cites` or `@verifies`. A vector selection gives one
of these: a group name; or every vector:

| target | name | vector selection |
|---|---|---|
| `catalog#descriptor[offsets]` | the full name `catalog#descriptor` | the group name `offsets` |
| `catalog#descriptor[*]` | the full name `catalog#descriptor` | every vector |
| `catalog[offsets]` | the slug `catalog` | the group name `offsets` |
| `#descriptor[offsets]` | `#` and the part name `descriptor` | the group name `offsets` |

A group name is a text of lower-case ASCII letters and ASCII digits that
starts with a letter, with one `-` at most between two of them, such as
`offsets` or `utf-8`. So `[12]` and `[Offsets]` are not vector
selections. A target with a vector selection carries no revision, so
`@cites catalog#descriptor[offsets]=v2` and
`@cites catalog#descriptor[*]=v3` are invalid. `[offsets][*]` is not a
vector selection, so `@cites catalog#descriptor[offsets][*]` is invalid.

Only `@cites` and `@verifies` allow a vector selection, so
`@refines catalog#descriptor[offsets]` is invalid. A declaration and an
external id allow no vector selection, so `@spec descriptor[offsets]`
and `@cites gh/42[offsets]` are invalid. A name, a label, and an id hold
no `[` and no `]`, so `@cites catalog#descriptor=v1[offsets]` is
invalid.

### 2.7 Target lists and scoped lists

A citation can cite several things on one line. Its target can be a
target list, a scoped list, or a target list that holds scoped lists.

A target list is `{`, one or more single targets or scoped lists
separated by `,`, and `}`, such as `{#notation=v1, gh/42}`. A single
target is a target, or an element of a target list, that is neither a
target list nor a scoped list. A single target has one of the forms of
sections 2.1 to 2.6.

A scoped list is an optional kind word and `:`, an optional slug, `#{`,
one or more parts separated by `,`, and `}`, such as
`catalog#{size=v1, descriptor=v2}`. Each part is a part name followed by
`=` and a revision, or, for `@cites` and `@verifies`, by a vector
selection. Each part of a scoped list stands for a single target: the
kind word and the `:` of the scoped list, its slug, `#`, and the part.
So `req:catalog#{size=v1, descriptor=v2}` stands for
`req:catalog#size=v1` and `req:catalog#descriptor=v2`, and
`@verifies catalog#{descriptor[offsets], size[*]}` stands for
`catalog#descriptor[offsets]` and `catalog#size[*]`. A scoped list with
no slug, such as `#{notation=v1, characters=v1}`, stands for
`#notation=v1` and `#characters=v1`. A scoped list holds no kind word
between its braces. A scoped list holds no target list.

Spaces and tabs can stand after each `{`, before and after each `,`, and
before each `}`. A space or a tab before which the text from the start
of the target holds more `{` than `}` does not end the target. One `,`
can also stand before a `}`, so `{docs=v1, docs#size=v2,}` and
`catalog#{size=v1,}` are valid. After the target, the line ends, or one
or more spaces or tabs and an inline description follow. Example: in
`@cites {#notation=v1, catalog#{size=v1, descriptor=v2}} The limits.`,
the inline description is `The limits.`.

A target list or a scoped list can continue over the lines after the
line of its citation. In a citation in which the character right after
the tag word is a space or a tab, a conforming program reads the
characters of the line one after another, from the start of the target.
The brace count is the number of `{` and the number of `}` that the
program read. When the line ends and the brace count has more `{` than
`}`, the next line continues the target, and the program reads on
through that line. The lines continue in this way up to the line on
which the program comes to a space or a tab, or to the end of the line,
and the brace count has no more `{` than `}`. Each of these lines is a
continuation line of the citation. The spaces and tabs at the start of
each continuation line are not in the text of the citation. In the text
of the citation, a line feed comes before each continuation line. A line
feed of the text of a citation can stand between the braces where a
space or a tab can stand. In a valid citation, a line feed of the text
of a citation stands only where `list-space` stands in the production
`citation-line`. In the production `citation-line`, `list-space` stands
after the `{` of a target list or a scoped list, before and after each
`,` between the braces of that list, and before the `}` of that list. So
a citation entry does not break across lines. After the target, the rest
of the last line of the citation can hold an inline description.

Example: the lines `@cites #{`; a space written 4 times, then
`segment=v1, slug=v1,`; a space written 4 times, then `name=v1,`; and
`}` are one citation with the citation entries `#segment=v1`,
`#slug=v1`, and `#name=v1`. A blank line is a line that holds nothing or
only spaces and tabs. A tag line and a blank line are never continuation
lines. When the program comes to the end of a line, the brace count has
more `{` than `}`, and either there is no next line or the next line is
a tag line or a blank line, the citation is invalid. When the program
comes to the end of a line, the brace count has more `{` than `}`, and
the next line is a tag line or a blank line, the next line is an input
of its own.

The citation entries of a citation are its single targets and the
single targets for which the parts of its scoped lists stand, in their
order. A citation whose target is a single target has one citation
entry: its target. Each citation entry follows the rules of a single
target of the tag word of its citation:

- When a citation entry of `@cites` carries a revision, that citation
  entry carries a label or `*`. When a citation entry of `@refines`,
  `@satisfies`, `@supersedes`, or `@verifies` carries a revision, that
  citation entry carries a label.
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
name of an every-part target is its slug. A citation is invalid when two
citation entries have the same entry name, and either neither of them
has a vector selection or both have the same vector selection. Their
kind words and their revisions have no effect on this rule. So
`@cites {docs=v1, docs#size=v2}`,
`@cites {identifiers#{segments=v1, notation=v1}, gh/42}`, and
`@cites {catalog#descriptor[offsets], catalog#descriptor[utf-8]}` are
valid. These citations are invalid:

- `@cites {#a=v1, req:#a=v2}`, because its two citation entries have
  the entry name `#a` and no vector selection;
- `@cites {catalog#descriptor[offsets], spec:catalog#descriptor[offsets]}`,
  because its two citation entries have the entry name
  `catalog#descriptor` and the vector selection `[offsets]`.

An inline citation cites one target, so `[x](sinter:{docs=v1})` and
`[x](sinter:catalog#{size=v1})` are invalid.

For a valid citation, a conforming program gives a separate list of
values for each citation entry, in the order of the citation entries.
For a valid citation, no list of values holds a value of another
citation entry. For a valid citation, a conforming program gives the tag
word and the inline description of the line once.

### 2.8 The directives `@extern` and `@ack`

The target of `@extern` is a kind word, `:`, and a part name, such as
`spec:descriptor`. The target of `@extern` holds no `#`, so no slug
comes before the part name. The target of `@extern` holds no revision.

After `@ack`, an `@ack` line holds two or more longest runs of
characters other than spaces and tabs, with spaces or tabs between those
runs:

- The first run is a slug.
- The last run is the **hash prefix**: from 8 to 64 hex digits, `0` to
  `9` and `a` to `f`.
- The text between the first run and the last run, without the spaces
  and tabs at its two ends, is the **subject**. The subject can be
  empty. The subject can hold any character, spaces and `@` included.

Spaces and tabs can follow the hash prefix. Nothing else can follow the
hash prefix. Example: in `@ack retired docs#size=v2 3f2a9c1d`, the slug
is `retired`, the subject is `docs#size=v2`, and the hash prefix is
`3f2a9c1d`.

### 2.9 Inline citations

An inline citation is a link whose destination starts with the seven
characters `sinter:`. A link is an inline link, a reference link, or an
autolink of the markdown document of a text, as CommonMark 0.31.2
defines them. The markdown document of a text is the text of its body. A
U+FEFF at the start of the text is not in the body, so that U+FEFF is
not in the markdown document. An image is not a link, so
`![x](sinter:catalog#size-limit=v2)` is not an inline citation.

The destination of an inline link or a reference link is its link
destination as CommonMark 0.31.2 gives it. The destination of an
autolink is its URI as CommonMark 0.31.2 gives it. No percent-encoding
and no percent-decoding applies to a destination. So `%23` is three
characters and not `#`. As a result,
`[x](sinter:catalog%23size-limit=v2)` is invalid.

The target of an inline citation is its destination after `sinter:`. The
target is an optional kind word and `:`, and then either a name, `=`,
and a revision, or an external id with an optional `#` and part name. As
in the target of `@cites`, the revision is a label or `*`. As in the
target of `@cites`, an external id carries no revision. An inline
citation allows no vector selection, so
`[x](sinter:catalog#descriptor[offsets])` is invalid. So
`[auth](sinter:billing/auth=v3)` cites the slug `billing/auth` with the
revision `v3`, and `[auth](sinter:billing/auth)` is invalid. The rule of
external targets (section 2.5) applies as it applies in a tag line. So
under a binding with the external namespace `gh`, `[x](sinter:gh/42=v2)`
is invalid.

The link text of an inline link or a reference link is the text between
the `[` that starts the link and the `]` that closes that `[`, as
CommonMark 0.31.2 parses the link. It is that text as it stands in the
raw content of the paragraph or the heading that holds the link. The raw
content holds the lines of CommonMark 0.31.2 of the paragraph or the
heading, joined by line feeds. The underline of a setext heading is not
a line of the raw content. Each line of the raw content is without the
markers and the indentation of block quotes and list items, without the
opening and the closing sequences of `#` of an ATX heading, and without
the spaces and tabs at the start of the line. The spaces and tabs at the
end of the joined lines are not in the raw content. So in a block quote,
the lines `> [the` and `> limit](sinter:catalog#size-limit=v2)` give the
link text `the`, a line feed, and `limit`. The line `[the`, followed by
a line that holds three spaces and then
`limit](sinter:catalog#size-limit=v2)`, gives the same link text. The
link text keeps its markup, such as `*the* limit` in
`[*the* limit](sinter:catalog#size-limit=v2)`. The link text of an
autolink, such as `<sinter:req:catalog#size-limit=v2>`, is its text
between `<` and `>`. No backslash escape, entity reference, or numeric
character reference in that text is replaced.

An inline citation is invalid when the plain string content of its
link text holds no character other than blank characters. A blank
character is a Unicode whitespace character of CommonMark 0.31.2, or
one of the characters U+200B, U+200C, U+200D, U+2060, and U+FEFF, which
show no text. The plain string content of the link text of an autolink
is that link text. For an inline link or a reference link, CommonMark
0.31.2 parses inline elements between the `[` that starts the link and
the `]` that closes that `[`. The plain string content of the link text
of such a link is the text that these inline elements give without
their markup, in their order and joined together:

- Textual content gives its characters, with each backslash escape,
  entity reference, and numeric character reference replaced by the
  characters that CommonMark 0.31.2 gives for that escape or reference.
  So `&nbsp;` gives U+00A0.
- A code span of CommonMark 0.31.2 gives its content.
- Emphasis and strong emphasis give the plain string content of what
  they hold, so `*the* limit` gives `the limit`.
- An inline link and a reference link give the plain string content of
  their link text.
- An image gives the plain string content of its description.
- An autolink gives its text between `<` and `>`, with no backslash
  escape, entity reference, or numeric character reference replaced.
- A line break gives a line feed.
- Raw HTML, such as `<!-- -->`, gives no characters.

So `[](sinter:catalog#size-limit=v2)`, `[ ](sinter:catalog#size-limit=v2)`,
`[&nbsp;](sinter:catalog#size-limit=v2)`,
`[&#x200B;](sinter:catalog#size-limit=v2)`, and
`[<!-- -->](sinter:catalog#size-limit=v2)` are invalid. But
`[**](sinter:catalog#size-limit=v2)` is valid, because `**` that opens no
emphasis is text.

### 2.10 Id patterns

An id pattern is a small regular expression. An id fits an id pattern
when the whole id, and not only a run of it, has the form that the id
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
quantifier, the counts are decimal numerals, so they have no leading
zero. In `{n,m}`, `n` is not greater than `m`. Case always matters. A
character class can hold characters that a literal leaves out, such as
`.` and `+`: `[.]`, `[+]`.

This condition also applies to an id pattern: the empty id does not fit
the id pattern. So `[0-9]*` is invalid.

| id pattern | ids that fit it |
|---|---|
| `[1-9][0-9]*` | the numbers of GitHub issues and pull requests, such as `42` |
| `[A-Z]+-[1-9][0-9]*` | Jira keys whose project key holds only letters, such as `PROJ-1` |

### 2.11 Inputs, results, and values

The inputs of a conforming program are: the lines of the texts that the
program reads; the links and the images of the markdown document of each
text that the program reads; the id patterns and the pairs of an id
pattern and an id that the program takes; and the bindings of
`external-namespaces` that the program takes or under which the program
reads. The next line after a line of a text is the line of that text
whose line number is 1 more. A citation and its continuation lines are
one input. A continuation line gets no result of its own. An id pattern
is an input when the program takes that id pattern on its own, or in a
pair of an id pattern and an id. The id patterns of a binding belong to
the binding. Those id patterns are not inputs of their own. A pair of an
id pattern and an id is an input only when the program accepts the id
pattern of that pair. A conforming program gives one result for each
input. A conforming program gives no result for anything that is not an
input.

The requirements `validate-id-patterns`, `decide-fit`,
`validate-bindings`, `give-line-results`, and `give-link-results` state
the results that each kind of input gets. For example, a line that is
not a tag line gets the result "not a tag line", and a pair of an id
pattern and an id gets "fits" or "does not fit". Under a binding that
the program rejects, the program gives no result and no value for a
line, a link, or an image.

For a tag line, the program gives the tag word. For a valid declaration,
citation, status tag, directive, or inline citation, the program also
gives the values that the input holds, such as the kind word, the slug,
the custom namespace, the part name, the group name, the namespace name
and the id, the revision, the inline description, the subject and the
hash prefix, and the link text. For a citation, the program gives a
separate list of values for each citation entry, in the order of the
citation entries. For a citation, no list holds a value of another
citation entry. The program gives each value together with its value
name, such as "the slug". For each other input, the program gives no
value other than the tag word of a tag line. For a tag line, each value
that is a text is the text of a run of the text of the tag line. Each
value of the target of an inline citation is the text of a run of the
destination. The link text is the text that section 2.9 describes.

### 2.12 Canonical forms

Several texts can name the same thing. A canonical form writes it in one
way. The canonical identifier of a kind word and a name is the kind
word, `:`, and the name, such as `req:catalog#size-limit`. With no kind
word, the canonical identifier is the name alone, such as `docs`. The
name is a slug, a full name, or an external id with an optional `#` and
part name, such as `gh/42` or `rfc/8259#section-6`.

A conforming program can give the canonical form of a citation entry of
a valid citation together with a slug, or no slug, and a kind word, or
no kind word, that the program takes. The slug goes before an entry name
that starts with `#`, so `#notation=v1` with the slug `docs` gives the
name `docs#notation`. With no slug, such a name stays as it is. So the
canonical form of `#notation=v1` with no slug and the kind word `req` is
`req:#notation`. The text `req:#notation` is not a canonical identifier.
The kind word of the canonical form is the kind word that the program
takes, and not the kind word of the citation entry. The canonical form
holds no revision. The canonical form keeps the vector selection of the
citation entry. The canonical form of an every-part target ends with
`#*`. Under a binding with the external namespace `gh`:

| citation entry | slug | kind word | canonical form |
|---|---|---|---|
| `#notation=v1` | `docs` | `term` | `term:docs#notation` |
| `req:catalog#size=v2` | none | `req` | `req:catalog#size` |
| `spec:catalog#size=*` | `docs` | `req` | `req:catalog#size` |
| `req:#notation=v1` | none | none | `#notation` |
| `#notation=v1` | none | `req` | `req:#notation` |
| `docs#descriptor[offsets]` | none | `spec` | `spec:docs#descriptor[offsets]` |
| `docs=v3#*` | none | `design` | `design:docs#*` |
| `gh/42` | `docs` | none | `gh/42` |

The target of a valid inline citation has a canonical form in the same
way, from the name or the external id of its destination. So the target
of `[the notation](sinter:#notation=v1)`, with the slug `docs` and the
kind word `term`, gives `term:docs#notation`.

So the two citation entries of `@cites catalog#{size=v1, limit=v2}`,
with no slug and the kind word `req`, give `req:catalog#size` and
`req:catalog#limit`, as the citation entries of
`@cites {catalog#limit=v1, catalog#size=v3}` do.

## 3. Parameters

### 3.1 `external-namespaces`

@schema external-namespaces=v1
@cites {
    #{namespace-name=v1, id-pattern=v1, valid-id-pattern=v1},
    text#{text=v1, code-span=v1, production=v1},
}

A binding of the parameter `external-namespaces` is a finite set of
pairs. Each pair of a binding holds a namespace name, which is a text,
and an id pattern. The binding can be the empty set.

A binding of `external-namespaces` meets the schema
`external-namespaces` when, and only when, each of these conditions
holds:

- Each namespace name of the binding matches the production
  `namespace-name`.
- No two pairs of the binding have the same namespace name.
- Each id pattern of the binding is a valid id pattern.

## 4. Definitions

### 4.1 Tag lines

@term tag-line=v1
@cites text#{line=v1, character=v1, space=v1, tab=v1, code-span=v1}

A tag line is a line whose first character after the spaces and tabs at
its start is `@`.

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

The Sinter tag words are these fifteen tag words, in four sets:

- the declaration words: `@atom`, `@decision`, `@design`, `@req`,
  `@schema`, `@spec`, and `@term`;
- the citation words: `@cites`, `@refines`, `@satisfies`,
  `@supersedes`, and `@verifies`;
- the status word: `@deprecated`;
- the directive words: `@ack` and `@extern`.

A tag word is a Sinter tag word when, and only when, it is the same
text as one of these fifteen words.

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

For a citation in which the character right after the tag word is a
space or a tab, these steps give its continuation lines. The steps build
a text, which starts as the text of the line of the citation. The steps
read the characters of the text one after another, from the first
character after the spaces and tabs that follow the tag word. The brace
count is the number of `{` and the number of `}` that the steps already
read. At each character of the text, and at the end of the text, exactly
one of these cases applies, and the steps do what that case states:

1. At a space or a tab, or at the end of the text, when the brace count
   has no more `{` than `}`, the steps end.
2. At the end of the text, when the brace count has more `{` than `}`,
   and the next line is neither a tag line nor a blank line, that line
   is a continuation line of the citation. The steps add a line feed and
   the text of that line, without the spaces and tabs at its start, to
   the end of the text, and they read on from that line feed.
3. At the end of the text, when the brace count has more `{` than `}`,
   and there is no next line, or the next line is a tag line or a blank
   line, the steps end.
4. At each other character, the steps read that character and go on to
   the character after it.

When the steps already added a continuation line, the next line is the
line of the same text whose line number is 1 more than the line number
of the last continuation line that the steps added. Otherwise, the next
line is the line of the same text whose line number is 1 more than the
line number of the line of the citation. A blank line is a line that
holds no character other than spaces and tabs.

### 4.9 The texts of tag lines

@term tag-line-text=v1
@cites {
    #{tag-line=v1, tag-word=v1, citation=v1, continuation-line=v1},
    text#{
        line=v1, text=v1, character=v1, space=v1, tab=v1, code-span=v1,
    },
}

The text of a citation in which the character right after the tag word
is a space or a tab is the text that the steps of `continuation-line`
build when they end. The text of each other tag line is the text of its
line.

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
kind-word  = %s"atom" / %s"decision" / %s"design" / %s"req"
           / %s"schema" / %s"spec" / %s"term"
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
@cites text#{text=v1, code-span=v1, production=v1, rule-name=v1}

A vector selection is a text that matches the production
`vector-selection`:

```
vector-selection  = "[" group-name "]" / every-vector
group-name        = %x61-7A *( %x61-7A / DIGIT )
                    *( "-" 1*( %x61-7A / DIGIT ) )
every-vector      = "[*]"
```

### 4.19 Links

@term link=v1
@cites {commonmark/0.31.2, text#{text=v1, run=v1, body=v1}}

The markdown document of a text is the text of its body. A link is an
inline link, a full, collapsed, or shortcut reference link, or an
autolink of the markdown document of a text, each as CommonMark 0.31.2
defines it. An image is not a link.

### 4.20 Destinations

@term destination=v1
@cites {
    commonmark/0.31.2,
    #{link=v1},
    text#{text=v1, character=v1, code-span=v1},
}

The destination of an inline link or a reference link is its link
destination as CommonMark 0.31.2 gives it. The destination of an
autolink is its URI as CommonMark 0.31.2 gives it. No percent-encoding
and no percent-decoding applies to a destination, so a `%` is a
character of the destination.

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
        code-span=v1, algorithm=v1, sequence=v1,
    },
}

A line of CommonMark 0.31.2 is a line as CommonMark 0.31.2 gives it.

The raw content of a paragraph or a heading *b* is the text that these
steps give.

1. Let *lines* be the sequence of the lines of CommonMark 0.31.2 of *b*,
   in their order.
2. If *b* is a setext heading, remove the underline of *b* from *lines*.
3. Let *content* be the empty text.
4. For each *l* of *lines*, in order:
   1. Let *t* be *l* without the markers and the indentation of the
      block quotes and the list items that hold *b*, as CommonMark
      0.31.2 gives them.
   2. If *b* is an ATX heading, set *t* to *t* without its opening
      sequence of `#` and its closing sequence of `#`.
   3. While *t* is not empty and the first character of *t* is a space
      or a tab:
      1. Remove the first character of *t* from *t*.
   4. Append *t* to *content*.
   5. Append a line feed to *content*.
5. If *lines* is not empty, remove the last character of *content* from
   *content*.
6. While *content* is not empty and the last character of *content* is a
   space or a tab:
   1. Remove the last character of *content* from *content*.
7. Give *content*.

The link text of an inline link or a reference link is the text between
the `[` that starts the link and the `]` that closes that `[`, as
CommonMark 0.31.2 parses the link, in the raw content of the paragraph
or the heading that holds the link. The link text of an autolink is the
text of that autolink between `<` and `>`. No backslash escape, entity
reference, or numeric character reference in that link text is replaced.

### 4.23 Blank characters

@term blank-character=v1
@cites {commonmark/0.31.2, text#{character=v1, u-numeral=v1}}

A blank character is one of these characters:

- each Unicode whitespace character of CommonMark 0.31.2;
- U+200B, U+200C, U+200D, U+2060, and U+FEFF.

### 4.24 Plain string content

@term plain-string-content=v1
@cites {
    commonmark/0.31.2,
    #{link=v1, link-text=v1},
    text#{text=v1, character=v1, line-feed=v1, code-span=v1},
}

The plain string content of a sequence of inline elements, as CommonMark
0.31.2 parses them, is a text. The plain string content joins, in the
order of the elements, the texts that these rules give for the elements:

- Textual content gives its characters, with each backslash escape,
  entity reference, and numeric character reference replaced by the
  characters that CommonMark 0.31.2 gives for that backslash escape,
  that entity reference, or that numeric character reference.
- A code span of CommonMark 0.31.2 gives its content.
- Emphasis and strong emphasis give the plain string content of their
  inline elements.
- An inline link and a reference link give the plain string content of
  the inline elements that CommonMark 0.31.2 parses between the `[` that
  starts the link and the `]` that closes that `[`.
- An autolink gives its text between `<` and `>`, with no backslash
  escape, entity reference, or numeric character reference replaced.
- An image gives the plain string content of the inline elements of its
  image description.
- A soft line break and a hard line break each give a line feed.
- Raw HTML gives the empty text.

The plain string content of the link text of an inline link or a
reference link is the plain string content of the inline elements that
CommonMark 0.31.2 parses between the `[` that starts the link and the
`]` that closes that `[`. The plain string content of the link text of
an autolink is that link text.

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
text that starts after the spaces and tabs that follow the tag word of
the tag line in the text of the tag line. The target ends before the
first space or tab before which the text from the start of the target
holds no more `{` than `}`, or at the end of the text of the tag line
when no such space or tab follows. The target of an inline citation is
the text of its destination after `sinter:`.

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
line is the text of the tag line after the target of that tag line,
without the spaces and tabs at the start of the text of the tag line
after that target. The inline description of a status tag is the text of
the tag line after the tag word of that status tag, without the spaces
and tabs at the start of the text of the tag line after that tag word.
An inline description can be empty.

### 4.27 Id patterns

@term id-pattern=v1
@cites text#{
    text=v1, conforming-program=v1, decimal-numeral=v1, whole-number=v1,
    code-span=v1, production=v1, rule-name=v1,
}

An id pattern is a text that a conforming program takes as a pattern, on
its own or with other texts. A text that a conforming program takes as
an id pattern is an id pattern whether or not that text matches
`pattern`. These productions give the texts that `pattern` matches:

```
pattern       = branch *( "|" branch )
branch        = 1*piece
piece         = unit [ quantifier ]
unit          = literal / char-class / "(" pattern ")"
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

The number of a `count` is the whole number that the decimal numeral of
that `count` writes. The quantifiers `{n}`, `{n,}`, and `{n,m}` are the
forms `"{" count "}"`, `"{" count ",}"`, and `"{" count "," count "}"`,
where `n` is the number of the first `count`, and `m` is the number of
the second `count`.

### 4.28 Ids

@term id=v1
@cites {#{id-pattern=v1}, text#{text=v1, conforming-program=v1}}

An id is a text for which a conforming program decides whether that text
has the form that an id pattern gives.

### 4.29 Fit

@atom fit=v1
@cites {
    #{id=v1, id-pattern=v1, match=v1},
    text#{
        text=v1, run=v1, boundary=v1, character=v1, code-point-order=v1,
        code-span=v1, production=v1, result=v1,
    },
}

An id fits an id pattern that matches `pattern` when, and only when, the
run of the id that holds all of the characters of the id fits that
`pattern`. An element of the id pattern is a use of a rule in the match
of the id pattern by `pattern`. These rules state when a run of the id,
which can be the whole id or an empty run, fits an element of the id
pattern:

- A run fits a `literal` when, and only when, the run holds exactly one
  character, which is the one character of the `literal`.
- A run fits a `range` when, and only when, the run holds exactly one
  character, which comes neither before the first character of the
  `range` nor after the last character of the `range` in code point
  order. A run fits a `single` when, and only when, the run holds
  exactly one character, which is the one character of the `single`. A
  run fits an `edge-dash` when, and only when, the run holds exactly one
  character, which is `-`.
- A run fits a `class-member` when, and only when, the run fits the
  `range` or the `single` of the `class-member`.
- A run fits a `char-class` when, and only when, the run fits one of the
  `class-member` elements or one of the `edge-dash` elements of the
  `char-class`.
- A run fits a `unit` that is a `literal` or a `char-class` when, and
  only when, the run fits that `literal` or that `char-class`. A run
  fits a `unit` of the form `"(" pattern ")"` when, and only when, the
  run fits the inner `pattern`.
- A run fits a `piece` with no `quantifier` when, and only when, the run
  fits the `unit` of the `piece`. A run fits a `piece` with a
  `quantifier` when, and only when, boundaries of the run divide it into
  a sequence of runs, one right after another, that each fit the `unit`,
  and the number of runs of the sequence is 0 or 1 for `?`, 0 or more
  for `*`, 1 or more for `+`, exactly `n` for `{n}`, `n` or more for
  `{n,}`, and from `n` to `m` for `{n,m}`. A sequence of no runs divides
  only an empty run. The runs of the sequence can differ.
- A run fits a `branch` when, and only when, boundaries of the run
  divide the run into a sequence of runs, one right after another and
  one for each `piece` of the `branch` in the order of those `piece`
  elements, and each run fits its `piece`.
- A run fits a `pattern` when, and only when, the run fits one of the
  branches of the `pattern`.

For a pair of an id pattern that matches `pattern` and an id, the result
is "fits" when the id fits the id pattern, and the result is "does not
fit" when the id does not fit the id pattern.

### 4.30 Valid id patterns

@term valid-id-pattern=v1
@cites {
    #{id-pattern=v1, id=v1, fit=v1, match=v1},
    text#{
        text=v1, character=v1, code-point-order=v1, code-span=v1,
        production=v1,
    },
}

An id pattern is a valid id pattern when, and only when, each of these
conditions holds:

- The id pattern matches the production `pattern`.
- The id pattern does not use, by `pattern`, a `range` whose first
  character comes after the last character of that `range` in code point
  order.
- The id pattern does not use, by `pattern`, a quantifier `{n,m}` in
  which `n` is greater than `m`.
- The empty text, as an id, does not fit the id pattern.

### 4.31 External namespaces

@term external-namespace=v1
@cites {
    #{external-namespaces=v1, id-pattern=v1, link=v1},
    text#{line=v1, conforming-program=v1},
}

Each pair of a binding is an external namespace of that binding, with
the namespace name and the id pattern of that pair of the binding. The
external namespaces of a line, a link, or an image are the external
namespaces of the binding under which a conforming program reads that
line, that link, or that image.

### 4.32 The form of namespace names

@term namespace-name=v1
@cites text#{text=v1, code-span=v1, production=v1, rule-name=v1}

This production gives the texts that `namespace-name` matches:

```
namespace-name  = %x61-7A *( %x61-7A / DIGIT )
                  *( "-" 1*( %x61-7A / DIGIT ) )
```

### 4.33 External ids

@term external-id=v1
@cites {
    #{part-name=v1, namespace-name=v1},
    text#{code-span=v1, production=v1, rule-name=v1},
}

These productions give the form of an external id:

```
external-ref  = external-id [ "#" part-name ]
external-id   = namespace-name "/" id-text
id-text       = 1*( %x21-22 / %x24-2B / %x2D-2E / %x30-3C / %x3E-3F
                    / %x41-5A / %x5C / %x5E-7A / %x7C / %x7E )
```

### 4.34 External targets

@term external-target=v1
@cites {
    #{
        target=v1, citation-entry=v1, kind-word=v1, declaration=v1,
        inline-citation=v1, tag-line=v1, external-namespaces=v1,
        external-namespace=v1,
    },
    text#{text=v1, character=v1, code-span=v1, production=v1},
}

A target or a citation entry starts with a kind word when it holds a `:`
and the text before its first `:` matches `kind-word`. The head of a
target or a citation entry is the text of that target or citation entry
that starts after that kind word and that `:` when the target or
citation entry starts with a kind word, or at the start of the target or
citation entry when the target or citation entry does not start with a
kind word. The head ends before the first character of the target or
citation entry that is `#`, `=`, or `[`, or at the end of the target or
citation entry when the target or citation entry holds no character that
is `#`, `=`, or `[`. The target of a declaration, the target of an
inline citation, and a citation entry are each an external target when,
and only when, one of two conditions holds. First, the head of that
target or that citation entry holds a `/`, and the text of that head
before the first `/` of that head is the namespace name of an external
namespace of the tag line or the inline citation that holds that target
or that citation entry. Second, the head of that target or that citation
entry holds no `/`, and the whole head is the namespace name of an
external namespace of the tag line or the inline citation that holds
that target or that citation entry.

### 4.35 The layout of tag lines

@term tag-line-layout=v1
@cites {
    #{tag-line=v1},
    text#{
        character=v1, space=v1, tab=v1, code-span=v1, production=v1,
        rule-name=v1,
    },
}

These productions give the spaces and tabs of a tag line and the end of
a tag line:

```
any-char  = %x0-D7FF / %xE000-10FFFF
indent    = *WSP
gap       = 1*WSP
rest      = [ gap *any-char ]
```

### 4.36 The form of declarations

@schema declaration-line=v1
@cites {
    #{
        declaration=v1, tag-line=v1, tag-line-layout=v1, segment=v1,
        slug=v1, full-name=v1, label=v1,
    },
    text#{text=v1, code-span=v1, production=v1, rule-name=v1},
}

This production gives the form of a declaration:

```
declaration-line  = indent ( %s"@decision" / %s"@design" )
                    gap slug "=" label rest
                  / indent %s"@spec" gap ( segment / full-name )
                    "=" label rest
                  / indent ( %s"@atom" / %s"@req" / %s"@schema" )
                    gap ( slug / full-name ) "=" label rest
                  / indent %s"@term" gap ( slug / full-name )
                    [ "=" label ] rest
```

A text meets the schema `declaration-line` when, and only when, it
matches the production `declaration-line`.

### 4.37 The form of citations

@schema citation-line=v1
@cites {
    #{
        citation=v1, tag-line-text=v1, tag-line=v1, tag-line-layout=v1,
        kind-word=v1, name=v1, slug=v1, part-name=v1, label=v1,
        revision=v1, external-id=v1, vector-selection=v1, match=v1,
    },
    text#{text=v1, run=v1, code-span=v1, production=v1, rule-name=v1},
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
                     ( name "=" revision
                     / name vector-selection
                     / external-ref )
verifies-single    = [ kind-word ":" ]
                     ( name "=" label
                     / name vector-selection
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
cites-part         = part-name ( "=" revision / vector-selection )
verifies-part      = part-name ( "=" label / vector-selection )
fixed-part         = part-name "=" label
comma              = list-space "," list-space
list-space         = *( WSP / LF )
```

A text meets the schema `citation-line` when, and only when, the text
has a match by `citation-line` in which no two entries meet both of two
conditions. First, the two entries have the same entry name. Second,
either neither of the two entries has a vector selection, or both of the
two entries have the same vector selection. The entries of a match by
`citation-line` are each run that `cites-single`, `verifies-single`,
`fixed-single`, or `supersedes-single` matches, and, for each run that
`cites-scoped`, `verifies-scoped`, or `fixed-scoped` matches, each run
within that enclosing run that `cites-part`, `verifies-part`, or
`fixed-part` matches:

- For a run that `cites-single`, `verifies-single`, `fixed-single`, or
  `supersedes-single` matches, the entry name of that run is the text
  that `name` or `external-ref` matches in that run, or, when
  `every-part` matches that run, the text that `slug` matches in that
  run. When that run uses `vector-selection`, the vector selection of
  that run is the text that `vector-selection` matches in that run.
- For a run that `cites-part`, `verifies-part`, or `fixed-part` matches
  within a run that `cites-scoped`, `verifies-scoped`, or `fixed-scoped`
  matches, when that enclosing run uses `slug`, the entry name of that
  part run is the text that `slug` matches in that enclosing run, then
  `#`, then the text that `part-name` matches in that part run. For that
  part run, when that enclosing run uses no `slug`, the entry name of
  that part run is `#`, then the text that `part-name` matches in that
  part run. When that part run uses `vector-selection`, the vector
  selection of that part run is the text that `vector-selection` matches
  in that part run.

### 4.38 Citation entries

@term citation-entry=v1
@cites {
    #{
        citation=v1, citation-line=v1, tag-line-text=v1, tag-word=v1,
        sinter-tag-word=v1, vector-selection=v1, match=v1,
    },
    text#{text=v1, run=v1, code-span=v1, production=v1},
}

In a match of the text of a citation by `citation-line`, a single target
is a run that `cites-single`, `verifies-single`, `fixed-single`, or
`supersedes-single` matches. In a match of the text of a citation by
`citation-line`, a scoped list is a run that `cites-scoped`,
`verifies-scoped`, or `fixed-scoped` matches. In a scoped list, each run
that `cites-part`, `verifies-part`, or `fixed-part` matches stands for a
single target: the text of the scoped list before its `{`, and then the
text of that run. The citation entries of the match are, in their order
in the text of the citation, the single targets of the match and the
single targets for which the parts of the scoped lists of the match
stand.

When the tag word of the citation is `@cites`, the match of a citation
entry is the match of that citation entry by `cites-single`. When the
tag word of the citation is `@verifies`, the match of a citation entry
is the match of that citation entry by `verifies-single`. When the tag
word of the citation is `@supersedes`, the match of a citation entry is
the match of that citation entry by `supersedes-single`. For each other
citation word, the match of a citation entry is the match of that
citation entry by `fixed-single`. The entry name of a citation entry is
the entry name that `citation-line` gives for the entry of the match of
the citation from which that citation entry comes: the single target, or
the run within a scoped list for which that citation entry stands. When
the match of a citation entry uses `vector-selection`, the vector
selection of the citation entry is the text that `vector-selection`
matches in that match.

### 4.39 The form of status tags

@schema status-line=v1
@cites {
    #{status-tag=v1, tag-line=v1, tag-line-layout=v1},
    text#{text=v1, code-span=v1, production=v1, rule-name=v1},
}

This production gives the form of a status tag:

```
status-line  = indent %s"@deprecated" rest
```

A text meets the schema `status-line` when, and only when, it matches
the production `status-line`.

### 4.40 The form of `@extern` lines

@schema extern-line=v1
@cites {
    #{
        directive=v1, tag-line=v1, tag-line-layout=v1, kind-word=v1,
        part-name=v1,
    },
    text#{text=v1, code-span=v1, production=v1, rule-name=v1},
}

This production gives the form of an `@extern` line:

```
extern-line  = indent %s"@extern" gap kind-word ":" part-name rest
```

A text meets the schema `extern-line` when, and only when, it matches
the production `extern-line`.

### 4.41 The form of `@ack` lines

@schema ack-line=v1
@cites {
    #{directive=v1, tag-line=v1, tag-line-layout=v1, slug=v1},
    text#{text=v1, hex-digit=v1, code-span=v1, production=v1, rule-name=v1},
}

These productions give the form of an `@ack` line:

```
ack-line     = indent %s"@ack" gap slug [ gap subject ] gap hash-prefix
               *WSP
subject      = non-wsp [ *any-char non-wsp ]
non-wsp      = %x0-8 / %xA-1F / %x21-D7FF / %xE000-10FFFF
hash-prefix  = 8*64hex-digit
```

A text meets the schema `ack-line` when, and only when, it matches the
production `ack-line`.

### 4.42 The form of inline citations

@schema inline-destination=v1
@cites {
    #{
        inline-citation=v1, destination=v1, kind-word=v1, name=v1,
        revision=v1, external-id=v1,
    },
    text#{text=v1, code-span=v1, production=v1, rule-name=v1},
}

This production gives the form of the destination of an inline
citation:

```
inline-destination  = %s"sinter:" [ kind-word ":" ]
                      ( name "=" revision / external-ref )
```

A text meets the schema `inline-destination` when, and only when, it
matches the production `inline-destination`.

### 4.43 Inputs

@term input=v1
@cites {
    #{
        continuation-line=v1, citation=v1, link=v1, id-pattern=v1, id=v1,
        external-namespaces=v1,
    },
    text#{
        input=v1, conforming-program=v1, line=v1, text=v1, result=v1,
        code-span=v1,
    },
}

The inputs of a conforming program are these:

- each line of a text that the conforming program reads, except a
  continuation line: a citation and its continuation lines are one
  input;
- each link and each image of the markdown document of a text that the
  conforming program reads;
- each id pattern that the conforming program takes on its own or in a
  pair of an id pattern and an id; the id patterns of a binding of
  `external-namespaces` belong to the binding and are not inputs of
  their own;
- each binding of `external-namespaces` that the conforming program
  takes, and each binding of `external-namespaces` under which the
  conforming program reads a line, a link, or an image;
- each pair of an id pattern and an id that the conforming program
  takes, when the conforming program gives the result "valid" for the id
  pattern of that pair of an id pattern and an id.

### 4.44 Matches

@term match=v1
@cites text#{
    text=v1, run=v1, character=v1, production=v1, rule-name=v1,
    code-span=v1,
}

A match of a text by a production is one way in which the production
matches the whole text: one set of the choices with which the production
gives terminal values that match the characters of the text, one each,
in their order. These choices are one alternative at each `/`; one
number of repetitions at each repetition, including an optional sequence
in `[ ]`; one terminal value at each range of terminal values; and one
case at each letter of a quoted string that matches either case. In a
match, each use of a rule through a rule name matches a run of the text:
the run of the characters that the terminal values of that use match. A
use is within another use when the other use reaches the first use
through the rule names of the rule of the other use, directly or through
other rules.

- A match uses a rule when a use of that rule matches a run in the
  match. The text that the rule matches in the match is the text of that
  run.
- In a run that a use of a rule matches, the text that another rule
  matches is the text of the run of a use of the other rule within that
  use of the first rule.
- A text uses a rule by a production when a match of the text by the
  production uses the rule.

### 4.45 The matches of inputs

@term input-match=v1
@cites {
    #{
        input=v1, tag-line=v1, tag-line-text=v1, inline-citation=v1,
        destination=v1, declaration=v1, citation=v1, status-tag=v1,
        directive=v1, extern-line=v1, ack-line=v1, declaration-line=v1,
        citation-line=v1, status-line=v1, inline-destination=v1,
        external-target=v1, external-id=v1, citation-entry=v1, target=v1,
        kind-word=v1, match=v1, namespace-name=v1, external-namespaces=v1,
        external-namespace=v1, id=v1, id-pattern=v1, fit=v1,
    },
    text#{text=v1, run=v1, code-span=v1, production=v1},
}

A match of an input is a match of the text of a tag line, or of the
destination of an inline citation, by one of these productions:

- `declaration-line` for a declaration;
- `citation-line` for a citation;
- `status-line` for a status tag;
- `extern-line` for an `@extern` line;
- `ack-line` for an `@ack` line;
- `inline-destination` for the destination of an inline citation;

in which each of these conditions holds:

- When the input is a declaration, its target is not an external target.
- For the target of an inline citation and for each citation entry of
  the match of a citation, when that target or citation entry is an
  external target and starts with a kind word, that target or citation
  entry without that kind word and the `:` after that kind word matches
  `external-ref`. For the target of an inline citation and for each
  citation entry of the match of a citation, when that target or
  citation entry is an external target and does not start with a kind
  word, that target or citation entry matches `external-ref`.
- For each run that `external-id` matches in the match, two conditions
  hold. First, the text that `namespace-name` matches in that run is the
  namespace name of an external namespace of the tag line or the inline
  citation. Second, the text that `id-text` matches in that run, as an
  id, fits the id pattern of that external namespace.

### 4.46 Values

@term value=v1
@cites {#{tag-line=v1, input=v1}, text#{text=v1, conforming-program=v1, result=v1}}

A value is a text or a fact that a conforming program gives together
with a result, under a value name. The value name tells what the value
is. A conforming program gives a value under a value name when it gives
the value together with something that stands for that value name and
for no other value name. A conforming program gives a value that is a
fact, such as every part or the type of tag line, when the conforming
program gives something that stands for that fact and for no other fact.
Where an input stands in its text, and an explanation of the result of
an input, are not values.

### 4.47 Canonical identifiers

@term canonical-id=v1
@cites {
    #{kind-word=v1, slug=v1, full-name=v1, external-id=v1},
    text#{
        text=v1, code-span=v1, algorithm=v1, production=v1, rule-name=v1,
    },
}

In this term, *k* is a kind word or the empty text. In this term, *n* is
a text that matches `slug`, `full-name`, or `external-ref`.

The canonical identifier of a kind word *k* and a name *n* is the text
that these steps give.

1. Let *form* be the empty text.
2. If *k* is not empty, then:
   1. Append *k* to *form*.
   2. Append `:` to *form*.
3. Append *n* to *form*.
4. Give *form*.

### 4.48 Canonical forms of citation entries

@term canonical-entry=v1
@cites {
    #{
        canonical-id=v1, citation=v1, tag-line-text=v1, citation-entry=v1,
        citation-line=v1, slug=v1, kind-word=v1, vector-selection=v1,
        match=v1, inline-citation=v1, destination=v1, target=v1,
        inline-destination=v1, name=v1, external-id=v1,
    },
    text#{
        text=v1, character=v1, code-span=v1, algorithm=v1, production=v1,
        rule-name=v1,
    },
}

In this term, *c* is a citation entry of a match of the text of a
citation by `citation-line`, or the target of an inline citation whose
destination has a match by `inline-destination`. In this term, *s* is a
slug or the empty text. In this term, *k* is a kind word or the empty
text. For the target of an inline citation whose destination has a match
by `inline-destination`, the entry name of that target is the text that
`name` or `external-ref` matches in that match of the destination.

The canonical form of a citation entry *c* with a slug *s* and a kind
word *k* is the text that these steps give.

1. Let *n* be the entry name of *c*.
2. If *s* is not empty and the first character of *n* is `#`, then:
   1. Let *full* be *s*.
   2. Append *n* to *full*.
   3. Set *n* to *full*.
3. Let *form* be the empty text.
4. If the first character of *n* is `#`, then:
   1. If *k* is not empty, then:
      1. Append *k* to *form*.
      2. Append `:` to *form*.
   2. Append *n* to *form*.
5. Otherwise, set *form* to the canonical identifier of *k* and *n*.
6. If *c* is a citation entry whose match uses `vector-selection`,
   append the vector selection of *c* to *form*.
7. If *c* is a citation entry whose match uses `every-part`, append `#*`
   to *form*.
8. Give *form*.

### 4.49 Line results

@atom line-result=v1
@cites {
    #{
        tag-line=v1, tag-word=v1, sinter-tag-word=v1, declaration=v1,
        citation=v1, status-tag=v1, directive=v1, declaration-line=v1,
        citation-line=v1, status-line=v1, extern-line=v1, ack-line=v1,
        tag-line-text=v1, input=v1, input-match=v1,
        external-namespaces=v1,
    },
    text#{line=v1, text=v1, result=v1, code-span=v1},
}

For a declaration, a citation, a status tag, or a directive, the schema
for its kind of tag line is `declaration-line` for a declaration,
`citation-line` for a citation, `status-line` for a status tag,
`extern-line` for an `@extern` line, and `ack-line` for an `@ack` line.
Under a binding of `external-namespaces` that meets the schema
`external-namespaces`, the line result of a line that is an input is one
of four results:

- "not a tag line", when the line is not a tag line;
- "other tag word", when the line is a tag line whose tag word is not a Sinter tag word;
- "valid", when all three of these conditions hold:
- the line is a declaration, a citation, a status tag, or a directive;
- the text of the tag line meets the schema for its kind of tag line;
- that input has a match of the input under that binding;
- "invalid", when the line is a declaration, a citation, a status tag, or a directive, and one or more of these conditions hold:
- the text of the tag line does not meet the schema for its kind of tag line;
- that input has no match of the input under that binding.

### 4.50 Link results

@atom link-result=v1
@cites {
    #{
        link=v1, inline-citation=v1, destination=v1,
        inline-destination=v1, link-text=v1, plain-string-content=v1,
        blank-character=v1, input=v1, input-match=v1,
        external-namespaces=v1,
    },
    text#{character=v1, result=v1, code-span=v1},
}

Under a binding of `external-namespaces` that meets the schema
`external-namespaces`, the link result of a link or an image that is an
input is one of three results:

- "not an inline citation", when the link or the image is not an inline citation;
- "valid", when the link or the image is an inline citation and all three of these conditions hold:
- the destination of the inline citation meets the schema `inline-destination`;
- the inline citation has a match of the input under that binding;
- the link text of the inline citation has a plain string content that holds at least one character other than blank characters;
- "invalid", when the link or the image is an inline citation and one or more of these conditions hold:
- the destination of the inline citation does not meet the schema `inline-destination`;
- the inline citation has no match of the input under that binding;
- the link text of the inline citation has a plain string content that holds no character other than blank characters.

## 5. Requirements

### 5.1 One binding for each line, link, and image

@req use-one-binding=v1
@cites {
    #{external-namespaces=v1, link=v1},
    text#{conforming-program=v1, requirement=v1, line=v1, code-span=v1},
}

A conforming program must read each line, link, and image under exactly
one binding of `external-namespaces`.

### 5.2 Validation of id patterns

@req validate-id-patterns=v1
@cites {
    #{input=v1, id-pattern=v1, valid-id-pattern=v1},
    text#{conforming-program=v1, requirement=v1, result=v1},
}

For each id pattern that is an input, a conforming program must give
exactly one result, and the program must give only "valid" or "invalid"
as that result. For each id pattern that is an input, when the id
pattern is not a valid id pattern, a conforming program must give the
result "invalid". For each id pattern that is an input, when the id
pattern is a valid id pattern, a conforming program must give the result
"valid".

### 5.3 The fit of ids

@req decide-fit=v1
@cites {
    #{input=v1, id-pattern=v1, id=v1, fit=v1},
    text#{conforming-program=v1, requirement=v1, result=v1},
}

For each input that is a pair of an id pattern and an id, a conforming
program must give exactly one result, and the program must give only
"fits" or "does not fit" as that result. For each input that is a pair
of an id pattern and an id, when the id fits the id pattern, a
conforming program must give the result "fits". For each input that is a
pair of an id pattern and an id, when the id does not fit the id
pattern, a conforming program must give the result "does not fit".

### 5.4 Validation of bindings

@req validate-bindings=v1
@cites {
    #{input=v1, external-namespaces=v1},
    text#{conforming-program=v1, requirement=v1, result=v1, code-span=v1},
}

For each binding of `external-namespaces` that is an input, a conforming
program must give exactly one result, and the program must give only
"valid" or "invalid" as that result. For each binding of
`external-namespaces` that is an input, when the binding does not meet
the schema `external-namespaces`, a conforming program must give the
result "invalid". For each binding of `external-namespaces` that is an
input, when the binding meets the schema `external-namespaces`, a
conforming program must give the result "valid".

### 5.5 Rejected bindings

@req give-no-results-under-rejected-bindings=v1
@cites {
    #{external-namespaces=v1, link=v1},
    text#{
        conforming-program=v1, requirement=v1, result=v1, line=v1,
        code-span=v1,
    },
}

Under a binding of `external-namespaces` for which a conforming program
gives the result "invalid", the program must give no result for a line,
a link, or an image.

### 5.6 Results for lines

@req give-line-results=v1
@cites {
    #{external-namespaces=v1, input=v1, line-result=v1},
    text#{
        conforming-program=v1, requirement=v1, result=v1, line=v1,
        code-span=v1,
    },
}

Under a binding of `external-namespaces` for which a conforming program
gives the result "valid", for each line that is an input, the program
must give exactly one result, and the program must give only "not a tag
line", "other tag word", "valid", or "invalid" as that result. Under a
binding of `external-namespaces` for which a conforming program gives
the result "valid", for each line that is an input, the program must
give the line result of that input under that binding.

### 5.7 Results for links and images

@req give-link-results=v1
@cites {
    #{external-namespaces=v1, input=v1, link=v1, link-result=v1},
    text#{
        conforming-program=v1, requirement=v1, result=v1, code-span=v1,
    },
}

Under a binding of `external-namespaces` for which a conforming program
gives the result "valid", for each link and each image that is an input,
the program must give exactly one result, and the program must give only
"not an inline citation", "valid", or "invalid" as that result. Under a
binding of `external-namespaces` for which a conforming program gives
the result "valid", for each link and each image that is an input, the
program must give the link result of that input under that binding.

### 5.8 The tag word

@req give-tag-words=v1
@cites {
    #{external-namespaces=v1, input=v1, tag-line=v1, tag-word=v1, value=v1},
    text#{conforming-program=v1, requirement=v1, result=v1, code-span=v1},
}

Under a binding of `external-namespaces` for which a conforming program
gives the result "valid", for each tag line, the program must give the
value of this table exactly once, together with the value name in the
first cell of the row of that value:

| value name | input | value |
|---|---|---|
| the tag word | a tag line | its tag word |

### 5.9 Values

@req give-values=v1
@cites {
    #{
        external-namespaces=v1, input=v1, value=v1, tag-line=v1,
        tag-word=v1, sinter-tag-word=v1, declaration=v1, citation=v1,
        status-tag=v1, directive=v1, ack-line=v1,
        inline-citation=v1, target=v1, inline-description=v1,
        link-text=v1, input-match=v1, citation-entry=v1, kind-word=v1,
        slug=v1, segment=v1, part-name=v1, citation-line=v1,
        vector-selection=v1, external-id=v1, namespace-name=v1,
        revision=v1, label=v1, match=v1,
    },
    text#{
        conforming-program=v1, requirement=v1, result=v1, text=v1,
        code-span=v1, production=v1,
    },
}

Under a binding of `external-namespaces` for which a conforming program
gives the result "valid", for each declaration, citation, status tag,
directive, and inline citation for which the program gives the result
"valid", the program must give these values, each value together with
the value name in the first cell of the row of that value:

- each value of the first table in a row whose second cell describes the input, exactly once for the input;
- for a citation, a separate list of values for each citation entry, in the order of the citation entries: the list of a citation entry holds each value of the second table in a row whose second cell describes the match of that citation entry, exactly once, and no list holds a value of another citation entry;
- for each other input, each value of the second table in a row whose second cell describes a match of the input, exactly once for the input.

| value name | input | value |
|---|---|---|
| the type of tag line | a tag line with a Sinter tag word | declaration, citation, status tag, or directive: the one that the tag line is |
| the inline description | a declaration, a citation, a status tag, or an `@extern` line | its inline description |
| the subject | an `@ack` line | the text that `subject` matches, or the empty text when the match uses no `subject` |
| the hash prefix | an `@ack` line | the text that `hash-prefix` matches |
| the link text | an inline citation | its link text |

| value name | match | value |
|---|---|---|
| the kind word | a match that uses `kind-word` | the text that `kind-word` matches |
| the slug | a match that uses `slug` | the text that `slug` matches |
| the slug | a match of a declaration whose tag word is `@spec` and whose target holds no `#` | the text that `segment` matches |
| the custom namespace | a match that uses `slug`, when the text that `slug` matches holds a `/` | the text that `slug` matches, before its last `/` |
| the part name | a match that uses `part-name` | the text that `part-name` matches |
| every part | a match that uses `every-part` | no text |
| the group name | a match that uses `group-name` | the text that `group-name` matches |
| every vector | a match that uses `every-vector` | no text |
| the namespace name | a match that uses `external-id` | the text that `namespace-name` matches in `external-id` |
| the id | a match that uses `external-id` | the text that `id-text` matches |
| the revision | a match that uses `revision` or `label` | the text that `revision` matches, or the text that `label` matches when the match uses no `revision` |

### 5.10 No other values

@req give-no-other-values=v1
@cites {
    #{input=v1, value=v1, give-values=v1, give-tag-words=v1},
    text#{conforming-program=v1, requirement=v1, code-span=v1},
}

A conforming program must give no value for an input other than the
values that the requirements `give-values` and `give-tag-words` state
for that input.

### 5.11 Things that are not inputs

@req give-no-results-for-non-inputs=v1
@cites {
    #{input=v1},
    text#{conforming-program=v1, requirement=v1, result=v1},
}

A conforming program must give no result for anything that is not an
input.

### 5.12 Canonical forms of citation entries

@req give-canonical-entries=v1
@cites {
    #{
        external-namespaces=v1, citation=v1, citation-entry=v1,
        canonical-entry=v1, slug=v1, kind-word=v1, inline-citation=v1,
        target=v1,
    },
    text#{
        conforming-program=v1, requirement=v1, result=v1, text=v1,
        code-span=v1,
    },
}

Under a binding of `external-namespaces` for which a conforming program
gives the result "valid", when the program gives the canonical form of a
citation entry of a citation for which the program gives the result
"valid", together with a slug or no slug and a kind word or no kind
word, the program must give the canonical form of that citation entry
with that slug (or with the empty text when there is no slug) and with
that kind word (or with the empty text when there is no kind word), and
the program must give nothing else as that canonical form. Under a
binding of `external-namespaces` for which a conforming program gives
the result "valid", when the program gives the canonical form of the
target of an inline citation for which the program gives the result
"valid", together with a slug or no slug and a kind word or no kind
word, the program must give the canonical form of that target with that
slug (or with the empty text when there is no slug) and with that kind
word (or with the empty text when there is no kind word), and the
program must give nothing else as that canonical form.

## 6. Conformance

A program conforms to this design when it is a
[conforming program](sinter:text#conforming-program=v1) of this design.

The vectors of this design are in the file
[`identifiers.test-vectors.jsonl`](identifiers.test-vectors.jsonl), in
the same directory as this design. Each vector follows from the
requirements and adds nothing to them. The schema `vector-line` in
subsection 6.1 defines the shared layout of the file and its vector
lines. The other schemas in the subsections below name the requirements
that the vectors of each group follow from. Those schemas define the
JSON forms of the vector lines of these groups. Where a definition of
section 4 cites a term of Text and notation, such as the lines or the
body of a text, the vectors follow the definition of that term in Text
and notation.

### 6.1 Vector lines

@schema vector-line=v1
@cites {
    rfc/8259,
    #{
        part-name=v1, label=v1, vector-selection=v1, input=v1,
        external-namespaces=v1, namespace-name=v1, id-pattern=v1,
        citation=v1, citation-entry=v1, value=v1,
    },
    text#{
        canonical-vector-line=v1, design=v1, byte-sequence=v1,
        valid-utf-8=v1, text-of-a-byte-sequence=v1, text=v1,
        character=v1, carriage-return=v1, line=v1, line-feed=v1, tab=v1,
        u-numeral=v1, code-span=v1, production=v1,
        conforming-program=v1, result=v1, sequence=v1,
    },
}

A vector gives an input of the vector, which holds one or more inputs of
a conforming program, and what a conforming program gives for them. The
vectors are in groups, and each group has a name, such as `citations`.
The vector file, `identifiers.test-vectors.jsonl` in the same directory
as this design, is a byte sequence that is valid UTF-8. The text of the
file does not start with U+FEFF. The text of the file holds no carriage
return. The text of the file has no empty line. When the text of the
file is not empty, the text of the file ends with a line feed. Only a
line feed ends a line of the vector file. A JSON string of the vector
file can hold U+0085, U+2028, or U+2029. These characters do not end a
line. The vector file holds zero or more vector lines.

The text of each line of the vector file is a vector line: a JSON text,
as RFC 8259 defines a JSON text, that meets the schema
`canonical-vector-line` of Text and notation. The JSON object of a
vector line holds the required members `form`, `group`, and `input`, at
least one of `result` and `values`, and the optional member `note`, and
no other member:

- `form`: a JSON string of `#`, the part name of the schema of this
  design for the group of the vector, `=`, and a label, such as
  `"#tag-line-vector=v1"`.
- `group`: the name of the group of the vector, as a JSON string that
  matches `group-name`.
- `input`: the input of the vector, which holds one or more inputs of a
  conforming program (such as a binding of `external-namespaces` and a
  text whose lines are inputs too).
- `note`: an optional JSON string that explains the vector. A conforming
  program does not give that string.
- `result`: a JSON string that holds a result that a conforming program
  gives for one input, without the double quotes of that result. For
  that input, a conforming program gives the result that `result` holds,
  once, and no other result.
- `values`: a JSON object that holds what a conforming program gives for
  the inputs that the schema of the group names, other than each result
  and each value that the vectors of the group do not state, and, when
  the vector has `result`, other than the result that `result` holds.
  The schema of each group gives the members of this JSON object, and it
  names each result and each value that a conforming program gives and
  that the vectors of the group do not state. In `values`, or in the
  `values` member of an element of an array that a group schema names,
  an empty JSON object, `{}`, says that a conforming program gives no
  value for that input.

A vector writes each text, binding of `external-namespaces`, and
sequence in one fixed JSON form:

- A text, such as a line, an id pattern, or a text value, is a JSON
  string whose characters are the characters of the text, in order. So
  the text `@req`, a tab, `size-limit=v2` is `"@req\tsize-limit=v2"`,
  and the empty text is `""`.
- A binding of `external-namespaces` is a JSON array with one element
  for each pair of the binding. Each element is a JSON object with two
  members: `namespace-name`, the namespace name of the pair, and
  `id-pattern`, the id pattern of the pair. The order of the elements
  has no meaning. So the binding that holds only the pair of the
  namespace name `gh` and the id pattern `[1-9][0-9]*` is
  `[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"}]`, and the empty
  set is `[]`.
- A sequence, such as the citation entries of a citation, is a JSON
  array of the elements of the sequence, in order.

A vector line meets the schema `vector-line` when, and only when, it
meets what this schema states for one vector line: what this schema
states from "The text of each line of the vector file" up to this
paragraph, this paragraph left out. All vector lines in the vector file
with the same `group` have the same `#` and part name in `form`, and
their labels in `form` may differ. The vector file meets the schema
`vector-line` when, and only when, the vector file meets what this
schema states before "The text of each line of the vector file" and
what this paragraph states on `group` and `form`, and the text of each
line of the vector file is a vector line that meets the schema
`vector-line`.

### 6.2 Tag lines

@schema tag-line-vector=v1
@cites {
    #{
        vector-line=v1, give-line-results=v1, give-tag-words=v1,
        give-values=v1, give-no-other-values=v1, validate-bindings=v1,
        external-namespaces=v1, namespace-name=v1, input=v1, value=v1,
        line-result=v1, tag-line=v1, tag-word=v1, sinter-tag-word=v1,
        declaration=v1, citation=v1, citation-line=v1, status-tag=v1,
        directive=v1, ack-line=v1, inline-description=v1,
        citation-entry=v1, vector-selection=v1, link=v1, link-text=v1,
        slug=v1, part-name=v1, kind-word=v1, revision=v1, id=v1,
        match=v1,
    },
    text#{
        conforming-program=v1, line=v1, text=v1, result=v1, space=v1,
        code-span=v1,
    },
}

Five groups hold the vectors of texts that have one line each. Each
group holds one kind of line:

- The group `other-lines` holds lines that are not tag lines, and tag
  lines whose tag word is not a Sinter tag word.
- The group `declarations` holds declarations.
- The group `citations` holds citations.
- The group `status-tags` holds status tags.
- The group `directives` holds directives: `@extern` lines and `@ack`
  lines.

The vectors of these groups follow from the requirements
`give-line-results`, `give-tag-words`, `give-values`, and
`give-no-other-values`. Each vector gives a text of one line under a
binding of `external-namespaces`, and what a conforming program gives
for that line. Each vector line of these groups meets the schema
`vector-line`.

- `input`: a JSON object with two members, `binding` and `text`.
  `binding` is a binding of `external-namespaces` as a JSON array of
  `{"id-pattern":...,"namespace-name":...}` objects. `text` is a JSON
  string whose text has one line and whose markdown document holds no
  link and no image. The program takes the binding, and it reads the
  text under that binding. In the file, `binding` holds two pairs: `gh`
  with `[1-9][0-9]*`, and `rfc` with `[1-9][0-9]*`. A conforming program
  gives the result "valid" for this binding under `validate-bindings`.
  These vectors do not state that result.
- `result`: the line result of the line: `"not a tag line"` or
  `"other tag word"` in the group `other-lines`, and `"valid"` or
  `"invalid"` in the other four groups.
- `values`: a JSON object that holds the values of the line:
  - For a line that is not a tag line, the empty JSON object, `{}`.
  - For a tag line with the result `"other tag word"` or `"invalid"`, a
    JSON object with one member, `tag-word`.
  - For a tag line with the result `"valid"`, a JSON object with the
    members `tag-word` and `type-of-tag-line`, and with each other value
    that `give-values` states for the line. A declaration, a citation, a
    status tag, and an `@extern` line have the member
    `inline-description`. When the inline description is empty,
    `inline-description` is `""`. An `@ack` line has the members
    `subject` and `hash-prefix`. The values of the match of a
    declaration, an `@extern` line, or an `@ack` line are members of the
    JSON object itself. For a citation, the member `entries` is a JSON
    array with one element for each citation entry, in order; each
    element is a JSON object holding the values of that citation entry
    (even when a citation has one citation entry). `tag-word`,
    `type-of-tag-line`, and `inline-description` stand on the outer JSON
    object, not inside `entries`.

Each value member uses the key of this table. Each key is the value name
without "the" at its start and with hyphens in place of spaces.

| key | value name | JSON value |
|---|---|---|
| `tag-word` | the tag word | a JSON string |
| `type-of-tag-line` | the type of tag line | `"declaration"`, `"citation"`, `"status tag"`, or `"directive"` |
| `inline-description` | the inline description | a JSON string, which can be empty |
| `subject` | the subject | a JSON string, which can be empty |
| `hash-prefix` | the hash prefix | a JSON string |
| `link-text` | the link text | a JSON string |
| `kind-word` | the kind word | a JSON string |
| `slug` | the slug | a JSON string |
| `custom-namespace` | the custom namespace | a JSON string |
| `part-name` | the part name | a JSON string |
| `every-part` | every part | the JSON literal `true` |
| `group-name` | the group name | a JSON string |
| `every-vector` | every vector | the JSON literal `true` |
| `namespace-name` | the namespace name | a JSON string |
| `id` | the id | a JSON string |
| `revision` | the revision | a JSON string |

For the line, a conforming program gives each value that `values` holds,
exactly once. For a citation, it also gives one list of values for each
element of `entries`, in the order of the elements, and the list of an
element holds each value of that element, exactly once. It gives each of
these values together with its value name, and it gives no other value.
An empty JSON object, `{}`, says that a conforming program gives no
value for the line.

```
{"form":"#tag-line-vector=v1","group":"declarations","input":{"binding":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"},{"id-pattern":"[1-9][0-9]*","namespace-name":"rfc"}],"text":"@req size-limit=v2 A descriptor has at most 1 MiB."},"result":"valid","values":{"inline-description":"A descriptor has at most 1 MiB.","revision":"v2","slug":"size-limit","tag-word":"@req","type-of-tag-line":"declaration"}}
{"form":"#tag-line-vector=v1","group":"citations","input":{"binding":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"},{"id-pattern":"[1-9][0-9]*","namespace-name":"rfc"}],"text":"@cites {gh/42, rfc/8259#section-6}"},"result":"valid","values":{"entries":[{"id":"42","namespace-name":"gh"},{"id":"8259","namespace-name":"rfc","part-name":"section-6"}],"inline-description":"","tag-word":"@cites","type-of-tag-line":"citation"}}
{"form":"#tag-line-vector=v1","group":"citations","input":{"binding":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"},{"id-pattern":"[1-9][0-9]*","namespace-name":"rfc"}],"text":"@cites {docs=v1}x"},"note":"no space or tab after the `}`","result":"invalid","values":{"tag-word":"@cites"}}
```

### 6.3 Citations over several lines

@schema continuation-line-vector=v1
@cites {
    #{
        vector-line=v1, tag-line-vector=v1, give-line-results=v1,
        give-tag-words=v1, give-values=v1, give-no-other-values=v1,
        give-no-results-for-non-inputs=v1, validate-bindings=v1,
        external-namespaces=v1, input=v1, value=v1, continuation-line=v1,
        citation=v1, tag-line=v1, link=v1,
    },
    text#{
        conforming-program=v1, line=v1, text=v1, result=v1, code-span=v1,
    },
}

The group `continuation-lines` holds texts that start with a tag line.
Each text tests which lines after that tag line are continuation lines
of that tag line, and which lines are inputs of their own. Only a
citation has continuation lines. A text of the group can have one line.
The vectors of the group follow from `give-line-results`,
`give-tag-words`, `give-values`, `give-no-other-values`, and
`give-no-results-for-non-inputs`. Each vector gives a text and what a
conforming program gives for the inputs that the lines of the text make.
A citation and its continuation lines are one input. Each other line is
an input of its own. Each vector line of the group meets the schema
`vector-line`.

- `input`: a JSON object with `binding` and `text`, the binding and the
  text as `tag-line-vector` describes them, except that `text` can have
  more than one line. The markdown document of `text` holds no link and
  no image.
- `result`: no vector of the group has this member.
- `values`: a JSON object with one member, `inputs`: a JSON array with
  one element for each input that the lines of the text make, in the
  order of the first lines of these inputs. Each element is a JSON
  object with two members: `result` and `values`. Each of those two
  members has the form that `tag-line-vector` defines.

For the k-th input, a conforming program gives the result of the k-th
element of `inputs`, once, and no other result. For the k-th input, a
conforming program gives each value that the `values` of the k-th
element of `inputs` holds, exactly once. For a citation, it also gives
one list of values for each element of `entries`, in the order of the
elements, and the list of an element holds each value of that element,
exactly once. It gives each of these values together with its value
name, and it gives no other value. An empty JSON object, `{}`, says that
a conforming program gives no value for that input. A conforming program
gives no result for a continuation line on its own.

```
{"form":"#continuation-line-vector=v1","group":"continuation-lines","input":{"binding":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"},{"id-pattern":"[1-9][0-9]*","namespace-name":"rfc"}],"text":"@cites {docs=v1,\n@req size-limit=v2"},"note":"the target list is not closed, and the next line is a tag line; the line `@req size-limit=v2` is an input of its own","values":{"inputs":[{"result":"invalid","values":{"tag-word":"@cites"}},{"result":"valid","values":{"inline-description":"","revision":"v2","slug":"size-limit","tag-word":"@req","type-of-tag-line":"declaration"}}]}}
```

### 6.4 Inline citations

@schema inline-citation-vector=v1
@cites {
    #{
        vector-line=v1, tag-line-vector=v1, give-link-results=v1,
        give-values=v1, give-no-other-values=v1,
        give-no-results-for-non-inputs=v1, validate-bindings=v1,
        external-namespaces=v1, input=v1, value=v1, link=v1,
        link-text=v1, inline-citation=v1, link-result=v1, tag-line=v1,
        match=v1,
    },
    text#{
        conforming-program=v1, line=v1, text=v1, result=v1, code-span=v1,
    },
}

The group `inline-citations` holds texts whose markdown documents can
hold links and images. Its vectors follow from `give-link-results`,
`give-values`, `give-no-other-values`, and
`give-no-results-for-non-inputs`. Each vector gives a text and what a
conforming program gives for the links and the images of the markdown
document of the text. Each vector line of the group meets the schema
`vector-line`.

- `input`: a JSON object with `binding` and `text`, the binding and the
  text as `tag-line-vector` describes them, except that `text` can have
  any number of lines and the markdown document of `text` can hold links
  and images.
- `result`: no vector of the group has this member.
- `values`: a JSON object with one member, `links`: a JSON array with
  one element for each link and each image of the markdown document of
  the text, in the order in which they start in the markdown document.
  When the markdown document holds no link and no image, `links` is the
  empty JSON array. Each element is a JSON object with two members:
  - `result`: the link result of the link or the image:
    `"not an inline citation"`, `"valid"`, or `"invalid"`.
  - `values`: for an inline citation with the result `"valid"`, a JSON
    object with the member `link-text` and with each value that
    `give-values` states for the match of the inline citation. That JSON
    object uses the keys of `tag-line-vector`. For each other link and
    image, the empty JSON object, `{}`.

For the k-th link or image, a conforming program gives the result of the
k-th element of `links`, once, and no other result. For the k-th link or
image, a conforming program gives each value that the `values` of the
k-th element of `links` holds, exactly once, together with its value
name. For the k-th link or image, a conforming program gives no other
value. An empty JSON object, `{}`, says that a conforming program gives
no value for the link or the image. A conforming program gives a result
as the result of a link or an image only for these links and images. So
a conforming program gives no result for a text in an indented code
block that has the form of a link.

No line of these texts is a tag line. So a conforming program gives the
result "not a tag line" for each line of the text. The vectors do not
state these results.

```
{"form":"#inline-citation-vector=v1","group":"inline-citations","input":{"binding":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"},{"id-pattern":"[1-9][0-9]*","namespace-name":"rfc"}],"text":"[the size limit](sinter:req:catalog#size-limit=v2)"},"values":{"links":[{"result":"valid","values":{"kind-word":"req","link-text":"the size limit","part-name":"size-limit","revision":"v2","slug":"catalog"}}]}}
```

### 6.5 Id patterns

@schema id-pattern-vector=v1
@cites {
    #{
        vector-line=v1, validate-id-patterns=v1,
        give-no-other-values=v1, input=v1, value=v1, id-pattern=v1,
    },
    text#{
        conforming-program=v1, line=v1, text=v1, result=v1, code-span=v1,
    },
}

The group `id-patterns` holds id patterns that a program takes on their
own. The vectors of the group follow from `validate-id-patterns` and
`give-no-other-values`. Each vector line of the group meets the schema
`vector-line`.

- `input`: the id pattern, as a JSON string.
- `result`: `"valid"` or `"invalid"`.
- `values`: the empty JSON object, `{}`: a conforming program gives no
  value with the result.

```
{"form":"#id-pattern-vector=v1","group":"id-patterns","input":"[1-9][0-9]*","result":"valid","values":{}}
```

### 6.6 Fit

@schema fit-vector=v1
@cites {
    #{
        vector-line=v1, decide-fit=v1, validate-id-patterns=v1,
        give-no-other-values=v1, input=v1, value=v1, id-pattern=v1,
        id=v1, fit=v1,
    },
    text#{
        conforming-program=v1, line=v1, text=v1, result=v1, code-span=v1,
    },
}

The group `fit` holds pairs of an id pattern and an id that a program
takes. The vectors of the group follow from `decide-fit`,
`validate-id-patterns`, and `give-no-other-values`. The id pattern of
each pair is valid. For each pair, the group `id-patterns` holds a
vector of the id pattern of that pair, with the result "valid". The id
pattern of a pair is an input too. The vectors of the group `fit` do not
state the result of that id pattern. Each vector line of the group meets
the schema `vector-line`.

- `input`: a JSON object with two members: `id-pattern`, the id pattern,
  and `id`, the id. Each is a JSON string.
- `result`: the result of the pair: `"fits"` or `"does not fit"`.
- `values`: the empty JSON object, `{}`: a conforming program gives no
  value with the result.

```
{"form":"#fit-vector=v1","group":"fit","input":{"id":"42","id-pattern":"[1-9][0-9]*"},"result":"fits","values":{}}
{"form":"#fit-vector=v1","group":"fit","input":{"id":"042","id-pattern":"[1-9][0-9]*"},"result":"does not fit","values":{}}
```

### 6.7 Bindings of `external-namespaces`

@schema binding-vector=v1
@cites {
    #{
        vector-line=v1, validate-bindings=v1, give-no-other-values=v1,
        input=v1, value=v1, external-namespaces=v1,
    },
    text#{conforming-program=v1, line=v1, result=v1, code-span=v1},
}

The group `bindings` holds bindings of `external-namespaces` that a
program takes. The vectors of the group follow from `validate-bindings`
and `give-no-other-values`. Each vector line of the group meets the
schema `vector-line`.

- `input`: the binding of `external-namespaces`, as a JSON array of
  `{"id-pattern":...,"namespace-name":...}` objects.
- `result`: `"valid"` or `"invalid"`.
- `values`: the empty JSON object, `{}`: a conforming program gives no
  value with the result.

```
{"form":"#binding-vector=v1","group":"bindings","input":[],"result":"valid","values":{}}
{"form":"#binding-vector=v1","group":"bindings","input":[{"id-pattern":"[1-9][0-9]*","namespace-name":"GH"}],"note":"`GH` does not match `namespace-name`","result":"invalid","values":{}}
```

### 6.8 Rejected bindings

@schema rejected-binding-vector=v1
@cites {
    #{
        vector-line=v1, give-no-results-under-rejected-bindings=v1,
        validate-bindings=v1, give-no-other-values=v1, input=v1,
        value=v1, external-namespaces=v1, link=v1,
    },
    text#{
        conforming-program=v1, line=v1, text=v1, result=v1, code-span=v1,
    },
}

The group `rejected-bindings` holds texts that a program reads under a
binding of `external-namespaces` for which the program gives the result
"invalid". The vectors of the group follow from
`give-no-results-under-rejected-bindings`, `validate-bindings`, and
`give-no-other-values`. Each vector line of the group meets the schema
`vector-line`.

- `input`: a JSON object with two members, `binding` and `text`.
  `binding` is a binding of `external-namespaces` as a JSON array of
  `{"id-pattern":...,"namespace-name":...}` objects. `text` is the text
  as a JSON string. The program takes the binding, and it reads the text
  under that binding.
- `result`: the result of the binding: `"invalid"`.
- `values`: a JSON object with one member, `inputs`: a JSON array with
  one element for each result that a conforming program gives for a
  line, a link, or an image of the text. Under a binding for which a
  conforming program gives the result "invalid", that conforming program
  gives no such result, and no value. So `inputs` is the empty JSON
  array.

```
{"form":"#rejected-binding-vector=v1","group":"rejected-bindings","input":{"binding":[{"id-pattern":"[1-9][0-9]*","namespace-name":"GH"}],"text":"@req size-limit=v2"},"result":"invalid","values":{"inputs":[]}}
```

### 6.9 Canonical forms

@schema canonical-entry-vector=v1
@cites {
    #{
        vector-line=v1, tag-line-vector=v1, give-canonical-entries=v1,
        validate-bindings=v1, external-namespaces=v1, input=v1, value=v1,
        citation=v1, citation-entry=v1, continuation-line=v1,
        inline-citation=v1, canonical-entry=v1, slug=v1, kind-word=v1,
        tag-line=v1, link=v1, target=v1,
    },
    text#{
        conforming-program=v1, line=v1, text=v1, result=v1, code-span=v1,
    },
}

The group `canonical-entries` holds valid citations and valid inline
citations, each with a slug or no slug, and with a kind word or no kind
word for each of its citation entries or for its target. The vectors of
the group follow from `give-canonical-entries`. Each vector gives a text
and the canonical form of each citation entry of the citation of the
text, or of the target of the inline citation of the text. Each vector
line of the group meets the schema `vector-line`.

- `input`: a JSON object with these members. `binding` and `text` are
  the binding and the text as `tag-line-vector` describes them, except
  that `text` meets one of these two conditions: either the first line
  of the text is a citation, its other lines are the continuation lines
  of that citation, and the markdown document of the text holds no link
  and no image; or no line of the text is a tag line, and the markdown
  document of the text holds one link and no image, and that link is an
  inline citation. `slug` is the slug, as a JSON string, only when there
  is a slug. `entries` is a JSON array with one element for each
  citation entry of the citation, in their order, or with one element
  for the target of the inline citation. Each element of `entries` is a
  JSON object. When there is a kind word for the citation entry or
  target of an element, that element has the member `kind-word`, which
  is that kind word as a JSON string. When there is no kind word for the
  citation entry or target of an element, that element has no member.
- `result`: no vector of the group has this member. A conforming program
  gives the result "valid" for the citation or the inline citation. The
  vectors do not state this result or the values for the citation or the
  inline citation. When no line of the text is a tag line, a conforming
  program also gives the result "not a tag line" for each line of the
  text, and the vectors do not state these results.
- `values`: a JSON object with one member, `forms`. `forms` is a JSON
  array with one element for each citation entry of the citation, in
  their order, or with one element for the target of the inline
  citation. Each element of `forms` is the canonical form of that
  citation entry or that target, as a JSON string.

When a conforming program gives the canonical form of the k-th citation
entry of the citation, or of the target of the inline citation, together
with the slug of `input`, or no slug when `input` has no member `slug`,
and with the kind word of the k-th element of `entries`, or no kind word
when that element has no member, that conforming program gives the k-th
element of `forms`, and no other text as that canonical form.

```
{"form":"#canonical-entry-vector=v1","group":"canonical-entries","input":{"binding":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"},{"id-pattern":"[1-9][0-9]*","namespace-name":"rfc"}],"entries":[{"kind-word":"req"},{"kind-word":"spec"}],"text":"@cites catalog#{size=v1, descriptor=v2}"},"note":"each part of a scoped list gives the canonical form of the single target for which it stands","values":{"forms":["req:catalog#size","spec:catalog#descriptor"]}}
```
