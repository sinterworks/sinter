<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Identifiers
@design identifiers/v1
Each tag line, target, and inline citation of Sinter has one written form, which tells a parser whether the text is valid.

## 1. Terms

In this design, "must" states a requirement, "must not" states a
prohibition, and "can" states a permission.

| term | meaning |
|---|---|
| line | the text of one line of a comment or of a markdown paragraph, without its line ending, without the characters that open, continue, or close a comment, and without a list marker or a task marker |
| tag line | a line whose first character, after the spaces and tabs at its start, is `@` (section 2.2) |
| tag word | the `@` at the start of a tag line, with the run of ASCII letters, ASCII digits, and `-` right after it (section 2.2) |
| Sinter tag word | one of the fifteen tag words of section 2.3 |
| declaration, citation, status tag, directive | the four classes of the Sinter tag words (section 2.3) |
| token | a run of characters that holds no space and no tab |
| target | the token after the tag word of a declaration, of a citation, or of `@extern`, which names a thing; also the text of an inline citation after `sinter:` |
| inline description | the text of a tag line after its target, or after its tag word when the tag word takes no target (section 2.2) |
| segment | a run of ASCII letters and ASCII digits, with one `-`, `_`, or `.` at most between two of them (section 2.4) |
| slug | one or more segments joined by `/`, such as `packs` or `billing/auth` |
| custom namespace | the segments of a slug before its last segment, such as `billing` in `billing/auth` |
| part name | a segment that names one part of a thing, such as a requirement of a design or a section of an external document; in a target it follows `#`, and in the target of `@extern` it follows `:` |
| full name | a slug, `#`, and a part name, such as `packs#descriptor` |
| kind word | a word before `:` at the start of a target that states what kind of thing the target names, such as `req` (section 2.5) |
| reserved | without a meaning now; text that uses a reserved word or character is invalid until a revision of this design gives it a meaning |
| head | the text of a target without its kind word and the `:` after it, up to the first `#`; when that text holds no `#`, all of it |
| external namespace | a name, such as `gh`, that stands for a set of things outside the repository, such as the issues of a tracker; the parameter `external-namespaces` gives the set of them (section 3) |
| external id | an external namespace, `/`, and an **id**, such as `gh/42`: the id names one thing of the namespace (section 2.6) |
| id pattern | an expression that matches the ids of one external namespace (section 2.7) |
| revision | a label or `*`, written after a `/` at the end of a name (section 2.8) |
| label | a revision other than `*`, such as `v2` |
| inline citation | a markdown link whose destination starts with `sinter:` (section 2.12) |
| link text | the text of a markdown link that a reader sees, such as `the size limit` in `[the size limit](sinter:req:packs#size-limit)` |
| parameter | a named value that some conditions depend on, and that a program binds before it reads text (section 3) |
| valid, invalid | a tag line with a Sinter tag word, a target, an inline citation, an id pattern, or a binding of a parameter is valid when it meets every condition of this design that applies to it, and invalid when it fails one of them |
| conforming parser | a program that accepts all valid text, rejects all invalid text, and gives the parts of valid text that this design defines |

## 2. Design

### 2.1 Notation

The grammars in this section use these forms:

| form | matches |
|---|---|
| `"abc"` | the characters `abc` |
| `#x09` | the character with the hexadecimal code 09, a tab |
| `[a-z]` | one character of the range; `[A-Za-z0-9]` joins ranges |
| `[!-~]` | one printable ASCII character other than a space |
| `A B` | what `A` matches, and then what `B` matches |
| `A \| B` | what `A` matches, or what `B` matches |
| `A - B` | what `A` matches, when `B` does not match the same text |
| `A?`, `A*`, `A+` | `A` 0 or 1 times, 0 or more times, 1 or more times |
| `A{n,m}` | `A` from `n` to `m` times |
| `( A )` | what `A` matches |

A grammar here matches the whole of a token, a line, or a destination,
never a part of one. `char` is any one character of a line.

### 2.2 Tag lines

A line is a tag line when its first character, after the spaces and
tabs at its start, is `@`. Every such line is a tag line, whatever its
tag word is.

The tag word of a tag line is its `@` and the longest run of ASCII
letters, ASCII digits, and `-` right after that `@`. The run can be
empty.

| line | tag word |
|---|---|
| `@req size-limit/v2` | `@req` |
| `   @finding-class late-fee/v1` | `@finding-class` |
| `@foo-bar: text` | `@foo-bar` |
| `@param x The input.` | `@param` |
| `@ alone` | `@` |
| `see @req size-limit/v2` | none: the line is not a tag line |

Two tag words are equal only when their bytes are equal, so `@Req` is
not `@req`. A tag line whose tag word is not a Sinter tag word is
neither valid nor invalid, and its tag word is still defined.

A tag line with a Sinter tag word takes the form that the class of its
tag word gives. In these productions, the line starts at its tag word,
after the spaces and tabs before it:

```
gap               ::= ( " " | #x09 )+
rest              ::= ( gap char* )?
declaration-line  ::= declaration-word gap declaration-target rest
citation-line     ::= citation-word gap citation-target rest
status-line       ::= status-word rest
extern-line       ::= "@extern" gap extern-target rest
ack-line          ::= "@ack" gap slug ( gap subject )? gap hash
                      ( " " | #x09 )*
```

`declaration-word`, `citation-word`, and `status-word` are the tag
words of each class in section 2.3. Section 2.10 gives the targets of
declarations and citations, and section 2.11 gives the forms of
`@extern` and `@ack`.

A space, a tab, or the end of the line must follow a Sinter tag word.
So `@req:size-limit/v2` and `@deprecated.` are invalid. A target is one
token, so it ends at the first space or tab after it.

The inline description of a tag line is the text that `char*` matches
in `rest`, without the spaces and tabs at its start. It can be empty.
An `@ack` line has no inline description.

### 2.3 Tag words

The Sinter tag words are a closed list of fifteen words in four classes.
A word joins the list only in a new revision of this design.

| tag word | class | target | revision in the target |
|---|---|---|---|
| `@decision` | declaration | a slug | a label |
| `@design` | declaration | a slug | a label |
| `@finding-class` | declaration | a slug | a label |
| `@req` | declaration | a slug or a full name | a label |
| `@spec` | declaration | a slug of one segment, or a full name | a label |
| `@cites` | citation | section 2.10 | a label or `*`; none after an external id |
| `@refines` | citation | section 2.10 | a label; none after an external id |
| `@satisfies` | citation | section 2.10 | a label; none after an external id |
| `@supersedes` | citation | section 2.10, also with `#*` | a label; none after an external id |
| `@verifies` | citation | section 2.10 | a label; none after an external id |
| `@deferred` | status tag | none | none |
| `@deprecated` | status tag | none | none |
| `@rejected` | status tag | none | none |
| `@ack` | directive | none; a form of its own (section 2.11) | none |
| `@extern` | directive | a kind word, `:`, and a part name (section 2.11) | none |

### 2.4 Segments, slugs, and full names

```
alnum      ::= [A-Za-z0-9]
segment    ::= alnum+ ( ( "-" | "_" | "." ) alnum+ )*
slug       ::= segment ( "/" segment )*
part-name  ::= segment
full-name  ::= slug "#" part-name
```

Examples of segments: `packs`, `size-limit`, `my_docs.v2`, `Auth`. The
texts `-docs`, `docs-`, `docs--x`, and `docs x` are not segments.

A segment keeps its case. Two segments are equal only when their bytes
are equal, so `Auth-Lockout` and `auth-lockout` are two segments. The
same holds for slugs, part names, and full names.

A slug holds one segment, such as `packs`, or several segments, such as
`billing/auth`. The segments before the last one are the custom
namespace of the slug. Any segments can form a custom namespace, and no
parameter lists them.

A full name holds exactly one `#`, and its part name holds no `/`.
Examples: `packs#descriptor`, `billing/auth#lockout`. A target can also
start with `#` and a part name, with no slug before the `#`, as in
`#descriptor`.

### 2.5 Kind words

The kind words are a closed list of six words. The reserved kind words
are a closed list of two words. A word joins either list only in a new
revision of this design.

```
kind-word      ::= "decision" | "design" | "finding-class" | "req"
                 | "spec" | "term"
reserved-kind  ::= "plan" | "task"
```

A target states a kind word when the text before its first `:` is a
kind word. The kind word and the `:` stand at the start of the target:
`req:packs#size-limit`, `spec:rfc/8259`. When the text before the first
`:` is not a kind word, the target states no kind word, and the `:`
stays part of the rest of the target.

A kind word can stand in the target of a citation, in an inline
citation, and in the target of `@extern`, where it is required. The
target of a declaration holds no kind word, because its tag word gives
the kind. A target with the part name `*` holds no kind word (section
2.8). A target whose text before its first `:` is a reserved kind word
is invalid.

### 2.6 External ids

```
namespace-name  ::= [a-z] [a-z0-9]* ( "-" [a-z0-9]+ )*
external-id     ::= namespace-name "/" id
id              ::= ( [!-~] - ( "#" | "@" ) )+
```

The parameter `external-namespaces` (section 3) gives each external
namespace and its id pattern. One rule decides whether the target of a
declaration, of a citation, or of an inline citation holds an external
id:

- When the text of the head before its first `/` is the name of an
  external namespace, the head must be an external id of that
  namespace, and the id pattern of that namespace must match its id.
  When the head holds no `/`, the whole head is that text.
- Otherwise, the target holds no external id.

So the same text can read in two ways. In the target of `@cites`,
`gh/42` is the external id `gh/42` when `gh` is an external namespace.
When `gh` is not one, `gh/42` is the slug `gh` with the revision `42`.

An external id can take `#` and a part name, which names a part of the
external thing, as in `rfc/8259#section-6`. An external id carries no
revision. Examples of targets: `gh/42`, `spec:rfc/8259`,
`term:rfc/8259#value`.

### 2.7 Id patterns

An id pattern is a small regular expression. It matches the whole id of
an external id. It is built from these parts:

| part | form | matches |
|---|---|---|
| literal | one printable ASCII character, `!` to `~`, other than `\ . [ ] ( ) { } * + ? \| ^ $ # @` | that character |
| class | `[`, one or more members, `]` | one character that a member matches |
| member | one printable ASCII character, `!` to `~`, other than `\`, `[`, `]`, `^`, `#`, and `@`; or a range `x-y` | that character; or each character from `x` to `y` |
| group | `(`, a pattern, `)` | what the pattern matches |
| sequence | parts one after another | what each part matches, one after another |
| alternation | `a\|b` | what `a` matches, or what `b` matches |
| quantifier | `?`, `*`, `+`, `{n}`, `{n,}`, or `{n,m}` after a literal, a class, or a group | the part 0 or 1 times; 0 or more times; 1 or more times; `n` times; `n` or more times; from `n` to `m` times |

Alternation binds loosest: `ab|c` means `(ab)|c`.

These rules apply:

1. A pattern matches an id only when it matches the whole id. A `^`
   anywhere, or a `$` outside a class, makes the pattern invalid.
2. Case always matters. A pattern has no flags.
3. A `.` outside a class makes the pattern invalid. A `\`, a `#`, or an
   `@` anywhere makes the pattern invalid. A class can match the other
   characters that a literal leaves out, such as `.` and `+`: `[.]`,
   `[+]`. No pattern matches `\`, `[`, `]`, `^`, `#`, or `@`.
4. The two ends of a range are both digits, both upper-case letters, or
   both lower-case letters, and the first end does not come after the
   second. Examples: `0-9`, `A-F`, `a-z`. A `-` is a member when it is
   first or last in its class. Any other `-` in a class stands between
   the two ends of a range.
5. In a quantifier, `n` and `m` are decimal numbers from 0 to 255, and
   `n` is not greater than `m`.
6. A part takes one quantifier at most: `a**` and `a+?` are invalid. An
   empty class, an empty group, and an empty alternative are invalid.
7. A pattern that matches the empty id is invalid. Example: `[0-9]*`.
8. An id that holds a space, or a character outside printable ASCII,
   matches no pattern.
9. When each quantifier is written out as copies of its part, a pattern
   holds 1,000 literals and classes at most. `{n}` and `{n,m}` count as
   the largest number of copies, `n` or `m`, and as one copy at least.
   `{n,}` counts as `n` copies and one more. `?`, `*`, and `+` count as
   one copy. A larger pattern is invalid. Examples: `([0-9]{3}-){10}`
   holds 40, and `((a{0,255}){0,255})b` holds 65,026, so it is invalid.

A pattern of this language matches the same ids in POSIX extended
regular expressions, in RE2, and in ECMAScript, when each of them must
match the whole id.

| pattern | ids that it matches |
|---|---|
| `[1-9][0-9]*` | the numbers of GitHub issues and pull requests, such as `42` |
| `[A-Z]+-[1-9][0-9]*` | Jira keys, such as `PROJ-1` |

### 2.8 Revisions

```
label     ::= ( [!-~] - ( "/" | "#" | "@" | "*" ) )+
revision  ::= label | "*"
```

A label is free-form: `v2`, `2026-11`, `v1.2.0`, and `rc1` are labels.
The form `v1`, `v2`, and so on is the recommended form. Two labels are
equal only when their bytes are equal.

The tag word decides whether its target carries a revision. Each tag
word either always puts a revision in its target or never does, as the
table of section 2.3 gives. The one exception is an external id, which
never carries a revision. The target of an inline citation never
carries a revision. No revision has a default: a target that must carry
a revision spells it. Only the target of `@cites` can take the revision
`*`, which stands for any revision.

A revision follows the name that it pins, after a `/`:

| target | name | revision |
|---|---|---|
| `docs/v3` | the slug `docs` | `v3` |
| `billing/auth/v3` | the slug `billing/auth` | `v3` |
| `docs#size/v2` | the full name `docs#size` | `v2` |
| `#size/v2` | `#` and the part name `size` | `v2` |
| `docs/*` | the slug `docs` | `*` |
| `docs/v3#*` | the slug `docs` | `v3` |

The last row is the one form in which the part name is `*`. It stands
for every part of the thing that the slug names, and only the target of
`@supersedes` can take it. In this form the revision follows the slug,
because it pins the thing that the slug names. The form holds no kind
word.

Two facts follow from these rules:

- The revision is the text after the last `/`. So in a target that
  carries a revision, the text after the last `/` is never part of the
  name: `billing/auth` in the target of `@cites` is the slug `billing`
  with the label `auth`.
- A label ends at the first space or tab. So a character right after a
  target is part of its label: in `@cites docs/v1, and more`, the label
  is `v1,`.

### 2.9 The reserved `@`

`@` is a reserved character in a target. A target that holds `@` is
invalid, in a tag line and in an inline citation. The rule does not
apply to the `@` of a tag word, or to an `@` in an inline description
or in the subject of an `@ack`, because these are not in a target.

### 2.10 Targets

The targets of declarations and of citations take these forms:

```
declaration-target  ::= slug "/" label
                      | full-name "/" label
citation-target     ::= ( kind-word ":" )? citation-name
                      | slug "/" label "#*"
citation-name       ::= slug "/" revision
                      | full-name "/" revision
                      | "#" part-name "/" revision
                      | external-id ( "#" part-name )?
```

These conditions also apply:

1. The target of `@decision`, `@design`, or `@finding-class` matches
   `slug "/" label`. The target of `@spec` matches
   `segment "/" label` or `full-name "/" label`. The target of `@req`
   matches either form of `declaration-target`.
2. The rule of section 2.6 chooses between `external-id` and the other
   forms of `citation-name`. The first segment of the target of a
   declaration is not the name of an external namespace.
3. Only the target of `@cites` takes the revision `*`.
4. Only the target of `@supersedes` takes the form
   `slug "/" label "#*"`.

A parser reads the target of a declaration, of a citation, or of an
inline citation in these steps. A step that finds the target invalid
ends the reading.

1. When the target holds `@`, the target is invalid.
2. The text after the first `#` of the target, when the target holds a
   `#`, is the text of the part name. The text before it is the text of
   the head and of the kind word.
3. When the text of the target before its first `:` is a kind word,
   that word is the kind word of the target. When that text is a
   reserved kind word, the target is invalid. The head starts after the
   `:` of the kind word.
4. When the text of the head before its first `/` is the name of an
   external namespace, the head is an external id, and the target
   carries no revision (section 2.6).
5. Otherwise, when the tag word puts a revision in its target, the
   parser takes the revision from the end of a name. When the text of
   the part name is `*`, the revision is the text after the last `/` of
   the head. When the text of the part name is another text, the
   revision is the text after its last `/`. When the target holds no
   `#`, the revision is the text after the last `/` of the head. When
   no `/` stands where the revision must be, the target is invalid.
6. What remains of the head is a slug, or empty when the target starts
   with `#` after its kind word. What remains of the text of the part
   name is a part name, or `*`.
7. The parts must then meet the grammar and the conditions above.

A conforming parser gives these parts of a valid target, each when the
target has it: the kind word; the slug; the part name or `*`; the
external namespace and the id; and the revision. Each part is a run of
the characters of the target.

### 2.11 The directives `@extern` and `@ack`

```
extern-target  ::= kind-word ":" part-name
hash           ::= [0-9a-f]{8,64}
```

The target of `@extern` is a kind word, `:`, and a part name, such as
`spec:descriptor`. The kind word is required. The target holds no slug,
no `#`, and no revision.

An `@ack` line holds two or more tokens after `@ack`:

- The last token is the **hash**: from 8 to 64 lower-case hexadecimal
  digits.
- The first token is a slug.
- The text between these two tokens, without the spaces and tabs at its
  two ends, is the **subject** of the line. The subject can be empty,
  and it can hold any character, spaces included. In `ack-line`,
  `subject` is such a text.

Example: in `@ack retired docs#size/v2 3f2a9c1d`, the slug is
`retired`, the subject is `docs#size/v2`, and the hash is `3f2a9c1d`.
The line ends with the hash, so an `@ack` line has no inline
description.

### 2.12 Inline citations

An inline citation is a link of markdown, as CommonMark defines a link,
whose destination starts with the seven characters `sinter:`. The form
of the link does not matter: an inline link, a reference link, and an
autolink are all links. The destination is the text that CommonMark
gives as the destination of the link. A `%` in it is a character of the
text, so `%23` is not `#`.

The rest of the destination, after `sinter:`, is the target of the
inline citation:

```
inline-destination  ::= "sinter:" ( kind-word ":" )? inline-name
inline-name         ::= slug
                      | full-name
                      | "#" part-name
                      | external-id ( "#" part-name )?
```

The target of an inline citation carries no revision. So
`sinter:billing/auth` names the slug `billing/auth`. The rule of
external ids (section 2.6), the reserved kind words (section 2.5), and
the reserved `@` (section 2.9) apply as they apply in a tag line. A
destination that starts with `sinter:` and does not match
`inline-destination` is invalid.

The link text can be empty, as in `[](sinter:packs#size-limit)`. An
autolink has its destination as its link text.

## 3. Parameters

### 3.1 `external-namespaces`

The parameter `external-namespaces` is a finite set of pairs. Each
pair holds the name of an external namespace and the id pattern of that
namespace. A program binds the parameter before it reads text. The
binding can be the empty set.

A binding of `external-namespaces` must meet these conditions:

1. Each name matches `namespace-name` (section 2.6).
2. No two pairs have the same name.
3. Each id pattern is valid by section 2.7.

## 4. Alternatives

- **Lists of tag words and kind words that other tools can extend.**
  Not chosen now: such lists wait until a need for them shows.
- **An id in the name of a design,** in the form `<slug>@<id>` that
  the name of a plan has today. Not chosen: within one repository, the
  checks of Sinter already stop a slug that comes back after a deletion
  from taking over the citations of the deleted thing.
- **`/` between a design and a part name.** Not chosen: it would clash
  with external ids and with custom namespaces, and it would need a
  rule to resolve each clash.
- **A part name alone, with no `#`, to cite a part of the design that
  holds the citation.** Not chosen: such a name could hide another
  name, and a new name elsewhere could change the meaning of a citation
  that already exists.
- **A default kind for each external namespace.** Not chosen: the kind
  would be implicit, and a citation should say what it means.
- **No part name after an external id.** Not chosen: Sinter could not
  tell two terms of one external document apart.
- **A custom namespace that must be declared.** Not chosen: a citation
  with a misspelled custom namespace already names no declared thing,
  so the mistake shows.
- **Citations of plans and tasks,** the units of work that Sinter
  tracks. Not chosen: whether a citation resolves would then depend on
  the state of the work, and not on the text alone. So `plan` and
  `task` are reserved kind words.
- **The tag word `@class` and the kind word `class`.** Not chosen:
  JSDoc and Doxygen already use `@class`.
- **Successors by name as the default of `@supersedes` between two
  designs, with no form `#*`.** Not chosen: a part whose name changed
  its meaning would get a wrong successor. So `#*` asks for successors
  by name, and nothing gives them by default.
- **A citation, or a keyword after the target of `@spec`, in place of
  `@extern`.** Not chosen: a citation links to a thing, and `@extern`
  says that a thing belongs to the design that holds the `@extern`. A
  keyword after a target is part of the inline description, which no
  parser reads for a meaning.
- **A path in the target of `@extern`.** Not chosen: each move of a
  file would break the `@extern`.

## 5. Requirements

### 5.1 Tag lines

@req tag-line/v1

A line must be a tag line when, and only when, its first character
after the spaces and tabs at its start is `@`. The tag word of a tag
line must be its `@` and the longest run of ASCII letters, ASCII
digits, and `-` right after that `@`. The run can be empty.

### 5.2 The list of tag words

@req tag-words/v1

The Sinter tag words must be the fifteen words of the table in section
2.3, each in the class that the table gives, and no other word. A tag
word must be a Sinter tag word only when its bytes equal the bytes of a
word of that list. A conforming parser must report a tag line whose tag
word is not a Sinter tag word as neither valid nor invalid, and must
give its tag word.

### 5.3 The forms of tag lines

@req line-forms/v1

A tag line with a Sinter tag word must match the production of its
class in section 2.2: `declaration-line`, `citation-line`,
`status-line`, `extern-line`, or `ack-line`. A Sinter tag word must
be followed by a space, a tab, or the end of the line. The inline
description must be the text of `rest` after the spaces and tabs at its
start. An `@ack` line must have no inline description.

### 5.4 Segments and slugs

@req segments/v1

A segment must match the production `segment`, and a slug must match
the production `slug` (section 2.4). The custom namespace of a slug
must be its segments before the last one. Two segments, two slugs, two
part names, or two full names must be equal only when their bytes are
equal.

### 5.5 Full names

@req full-names/v1

A full name must match the production `full-name`: a slug, one `#`, and
a part name. A part name must be one segment, except in the form
`slug "/" label "#*"` of the target of `@supersedes`. A target must not
hold a second `#`.

### 5.6 Kind words

@req kind-words/v1

The kind words must be `decision`, `design`, `finding-class`, `req`,
`spec`, and `term`, and no other word. The reserved kind words must be
`plan` and `task`, and no other word. A target must state a kind word
when, and only when, the text before its first `:` is a kind word. The
text before the first `:` of a target must not be a reserved kind word.
The target of a declaration, and a target with the part name `*`, must
hold no kind word.

### 5.7 External ids

@req external-ids/v1

Take the head of the target of a declaration, of a citation, or of an
inline citation. When the text of the head before its first `/`, or the
whole head when it holds no `/`, is the name of an external namespace,
the head must match `external-id`, the id pattern of that namespace
must match its id, and the target must carry no revision. Otherwise the
head must not be read as an external id. After an external id, a target
can hold `#` and a part name.

### 5.8 Id patterns

@req id-patterns/v1

An id pattern must be built only from the parts of the table in section
2.7, and it must meet the nine rules of that section. A valid pattern
must match an id when, and only when, the parts of the pattern match
the whole id with the meanings of that table.

### 5.9 The binding of external namespaces

@req namespace-binding/v1

A binding of the parameter `external-namespaces` must meet the three
conditions of section 3.1. A conforming parser must reject a binding
that fails one of them.

### 5.10 Revisions

@req revisions/v1

A revision must match the production `revision` (section 2.8). The
target of a declaration must end with `/` and a label. The target of a
citation must end with `/` and a revision, except in two cases: a
target that holds an external id carries no revision, and the form
`slug "/" label "#*"` carries its revision before `#*`. Only the target
of `@cites` can take the revision `*`. The target of `@extern` and the
target of an inline citation must carry no revision.

### 5.11 The reserved `@`

@req reserved-at/v1

A target must not hold `@`, in a tag line and in an inline citation.

### 5.12 The targets of declarations

@req declaration-targets/v1

The target of `@decision`, `@design`, or `@finding-class` must match
`slug "/" label`. The target of `@spec` must match `segment "/" label`
or `full-name "/" label`. The target of `@req` must match
`declaration-target`. The first segment of the target of a declaration
must not be the name of an external namespace.

### 5.13 The targets of citations

@req citation-targets/v1

The target of a citation must match `citation-target`. The rule of
requirement `#external-ids` must choose between `external-id` and the
other forms of `citation-name`. Only the target of `@supersedes` can
take the form `slug "/" label "#*"`.

### 5.14 The reading of a target

@req target-reading/v1

A conforming parser must read the target of a declaration, of a
citation, or of an inline citation in the steps of section 2.10. For a
valid target, it must give the kind word, the slug, the part name
or `*`, the external namespace and the id, and the revision, each when
the target has it, and each as a run of the characters of the target.

### 5.15 The target of `@extern`

@req extern-target/v1

The target of `@extern` must match `extern-target`: a kind word, `:`,
and a part name.

### 5.16 The form of `@ack`

@req ack-line/v1

An `@ack` line must match `ack-line`. Its last token must be its hash,
from 8 to 64 lower-case hexadecimal digits. Its first token after
`@ack` must be a slug. Its subject must be the text between these two
tokens, without the spaces and tabs at its two ends, and the subject
can be empty.

### 5.17 Inline citations

@req inline-citations/v1

A markdown link, in any form that CommonMark defines, must be an
inline citation when, and only when, its destination starts with the
seven characters `sinter:`. The destination of an inline citation must
match `inline-destination`, and requirements `#kind-words`,
`#external-ids`, and `#reserved-at` must apply to its target. The link
text of an inline citation can be empty.

## 6. Test plan

A conforming parser is tested in four ways:

1. **Test vectors.** Each row of the tables below is one test. The tests
   bind `external-namespaces` to two pairs: `gh` with the id pattern
   `[1-9][0-9]*`, and `rfc` with the id pattern `[1-9][0-9]*`. A test
   gives the parser the line, the link, the pattern, or the binding of
   its row, and checks the result and every part that the row gives.
   Each requirement of section 5 has at least one valid row and one
   invalid row, except `#tag-line` and `#tag-words`, whose rows are
   tag lines and other lines.
2. **Round trip.** A property test builds random valid targets from the
   productions of section 2, writes each one from its parts, reads it
   again, and checks that the parser gives the same parts.
3. **Any input.** A property test gives the parser random lines,
   random destinations, random id patterns, and valid ones with random
   changes. For each input, the parser gives a result and never fails.
4. **Id patterns.** A property test builds random valid id patterns and
   random ids. It checks that the parser matches an id when, and only
   when, RE2 matches the whole id with the same pattern.

### 6.1 Tag lines

| line | result |
|---|---|
| `@req size-limit/v2 A descriptor has at most 1 MiB.` | valid declaration: slug `size-limit`, revision `v2`, inline description `A descriptor has at most 1 MiB.` |
| `   @design identifiers/v1` | valid declaration: slug `identifiers`, revision `v1` |
| `see @req size-limit/v2` | not a tag line |
| `@param x The input.` | tag line with the tag word `@param`, which is not a Sinter tag word |
| `@Req size-limit/v2` | tag line with the tag word `@Req`, which is not a Sinter tag word |
| `@ alone` | tag line with the tag word `@`, which is not a Sinter tag word |
| `@req:size-limit/v2` | invalid: no space or tab after `@req` |
| `@deprecated.` | invalid: no space or tab after `@deprecated` |
| `@req` | invalid: no target |
| `@deprecated` | valid status tag |
| `@deferred Waits for a measurement.` | valid status tag: inline description `Waits for a measurement.` |
| `@design billing/auth/v2` | valid declaration: slug `billing/auth`, custom namespace `billing`, revision `v2` |
| `@design docs#size/v1` | invalid: the target of `@design` is a slug |
| `@design gh/v1` | invalid: the first segment, `gh`, is an external namespace |
| `@spec descriptor/v2` | valid declaration: slug `descriptor`, revision `v2` |
| `@spec packs#descriptor/v3` | valid declaration: slug `packs`, part name `descriptor`, revision `v3` |
| `@spec a/b/v1` | invalid: with no `#`, the target of `@spec` holds a slug of one segment |
| `@req ledger#chunk-size/v1` | valid declaration: slug `ledger`, part name `chunk-size`, revision `v1` |
| `@req size-limit` | invalid: no revision |
| `@req size-limit/*` | invalid: the revision of a declaration is a label |
| `@req req:size-limit/v1` | invalid: the target of a declaration holds no kind word |
| `@decision layered-designs/v1` | valid declaration: slug `layered-designs`, revision `v1` |
| `@finding-class billing/late-fee/v1` | valid declaration: slug `billing/late-fee`, revision `v1` |
| `@cites -docs/v1` | invalid: `-docs` is not a segment |
| `@cites docs--x/v1` | invalid: `docs--x` is not a segment |
| `@cites my_docs.v2/v1` | valid citation: slug `my_docs.v2`, revision `v1` |
| `@cites docs/*` | valid citation: slug `docs`, revision `*` |
| `@cites docs#size/v2` | valid citation: slug `docs`, part name `size`, revision `v2` |
| `@cites #size/v2` | valid citation: part name `size`, revision `v2` |
| `@cites req:#size/v2` | valid citation: kind word `req`, part name `size`, revision `v2` |
| `@cites billing/auth/v3` | valid citation: slug `billing/auth`, revision `v3` |
| `@cites billing/auth` | valid citation: slug `billing`, revision `auth` |
| `@cites docs` | invalid: no revision |
| `@cites docs/v1.2.0` | valid citation: slug `docs`, revision `v1.2.0` |
| `@cites docs/v1, and more` | valid citation: slug `docs`, revision `v1,`, inline description `and more` |
| `@satisfies docs#size/*` | invalid: only `@cites` takes the revision `*` |
| `@cites docs/v3#size` | invalid: no revision after the part name |
| `@cites docs#a/b/v1` | invalid: `a/b` is not a part name |
| `@cites docs#a#b/v1` | invalid: a second `#` |
| `@supersedes docs/v3#*` | valid citation: slug `docs`, revision `v3`, part name `*` |
| `@supersedes docs#*/v3` | invalid: with `#*`, the revision follows the slug |
| `@cites docs/v3#*` | invalid: only `@supersedes` takes `#*` |
| `@supersedes design:docs/v3#*` | invalid: the form with `#*` holds no kind word |
| `@cites plan:upkeep/*` | invalid: `plan` is a reserved kind word |
| `@cites spec:docs/v2` | valid citation: kind word `spec`, slug `docs`, revision `v2` |
| `@cites gh/42` | valid citation: external namespace `gh`, id `42` |
| `@cites spec:rfc/8259#section-6` | valid citation: kind word `spec`, external namespace `rfc`, id `8259`, part name `section-6` |
| `@cites gh/0` | invalid: the id pattern of `gh` does not match `0` |
| `@cites gh/42/*` | invalid: the id pattern of `gh` does not match `42/*` |
| `@cites gh` | invalid: `gh` is an external namespace, and no id follows it |
| `@cites jira/PROJ-1/*` | valid citation: slug `jira/PROJ-1`, revision `*` |
| `@cites docs@3f2a9c/*` | invalid: `@` in a target |
| `@extern spec:descriptor` | valid directive: kind word `spec`, part name `descriptor` |
| `@extern descriptor` | invalid: no kind word |
| `@extern spec:packs#descriptor` | invalid: the target of `@extern` holds no slug |
| `@ack retired docs#size/v2 3f2a9c1d` | valid directive: slug `retired`, subject `docs#size/v2`, hash `3f2a9c1d` |
| `@ack unexercised 3f2a9c1d0b7e` | valid directive: slug `unexercised`, empty subject, hash `3f2a9c1d0b7e` |
| `@ack retired 3F2A9C1D` | invalid: the hash holds upper-case digits |
| `@ack retired 3f2a9c` | invalid: the hash has fewer than 8 digits |
| `@ack 3f2a9c1d` | invalid: no slug before the hash |

### 6.2 Inline citations

| link | result |
|---|---|
| `[the size limit](sinter:req:packs#size-limit)` | valid: link text `the size limit`, kind word `req`, slug `packs`, part name `size-limit` |
| `[](sinter:packs#size-limit)` | valid: empty link text, slug `packs`, part name `size-limit` |
| `[the limit](sinter:#size-limit)` | valid: part name `size-limit` |
| `[RFC 8259](sinter:spec:rfc/8259)` | valid: kind word `spec`, external namespace `rfc`, id `8259` |
| `[auth](sinter:billing/auth)` | valid: slug `billing/auth` |
| `<sinter:req:packs#size-limit>` | valid: link text `sinter:req:packs#size-limit`, kind word `req`, slug `packs`, part name `size-limit` |
| `[x](sinter:packs#size-limit/v2)` | invalid: an inline citation carries no revision |
| `[x](sinter:)` | invalid: no target |
| `[x](sinter:plan:upkeep)` | invalid: `plan` is a reserved kind word |
| `[x](sinter:docs@3f2a9c)` | invalid: `@` in a target |
| `[x](Sinter:req:packs#size-limit)` | not an inline citation: the destination does not start with `sinter:` |

### 6.3 Id patterns

| pattern | result |
|---|---|
| `[1-9][0-9]*` | valid: matches `42`; does not match `0` or `042` |
| `[A-Z]+-[1-9][0-9]*` | valid: matches `PROJ-1`; does not match `proj-1` |
| `[.]x` | valid: matches `.x` |
| `[a-]+` | valid: matches `a-a` |
| `([0-9]{3}-){10}` | valid: holds 40 literals and classes |
| `^[0-9]+$` | invalid: `^` and `$` (rule 1) |
| `.+` | invalid: `.` outside a class (rule 3) |
| `[#0-9]+` | invalid: `#` (rule 3) |
| `[z-a]` | invalid: the first end comes after the second (rule 4) |
| `x{3,2}` | invalid: `n` is greater than `m` (rule 5) |
| `[0-9]{256}` | invalid: `n` is greater than 255 (rule 5) |
| `a**` | invalid: two quantifiers (rule 6) |
| `a\|` | invalid: an empty alternative (rule 6) |
| `[0-9]*` | invalid: matches the empty id (rule 7) |
| `((a{0,255}){0,255})b` | invalid: holds 65,026 literals and classes (rule 9) |

### 6.4 Bindings of `external-namespaces`

| binding | result |
|---|---|
| `gh` with `[1-9][0-9]*` | valid |
| `my-tracker` with `[A-Z]+-[1-9][0-9]*` | valid |
| `GH` with `[1-9][0-9]*` | invalid: `GH` does not match `namespace-name` |
| `my--tracker` with `[1-9][0-9]*` | invalid: `my--tracker` does not match `namespace-name` |
| `9ns` with `[1-9][0-9]*` | invalid: `9ns` does not match `namespace-name` |
| `gh` with `[1-9][0-9]*`, and `gh` with `[a-z]+` | invalid: two pairs with the name `gh` |
| `gh` with `[0-9]*` | invalid: the id pattern matches the empty id |

## 7. Open questions

- **The form of revisions, and which tag words carry one.** Options put
  forward: (a) a separate token `vN` after the target, optional on a
  declaration, where it means `v1` when it is absent, and optional on
  `@cites` (`spec/vocabulary.md` section 5); (b) a free-form label
  after the name and a `/`, as `target/rev`, spelled on every target of
  a tag word that carries a revision, with `/*` for any revision on
  `@cites` (put forward by the maintainer; the draft design "The work
  model of Sinter", section 7); (c) `target@rev` and (d) `target=rev`
  (put forward with the maintainer). For successors by name, the forms
  `docs#*/v3` and `docs/v3#*` were put forward. The text follows the
  lean of the maintainer: (b), with `docs/v3#*`, because a revision
  follows the name that it pins. These points of the text have no
  ruling of their own: a label holds no `#` and no `@`, which follows
  from the reading of `#` and from the reserved `@`; a label holds no
  `*`, so that `*` has one meaning; `@refines`, `@satisfies`,
  `@supersedes`, and `@verifies` require a label, which was assumed in
  the discussion with the maintainer and not ruled; and a character
  right after a target, such as a comma, becomes part of its label.
- **A pin in an inline citation.** Options put forward: an inline
  citation can carry a revision; it cannot, which is the lean of the
  maintainer (the draft design "The work model of Sinter", section 7).
  The text follows the lean: an inline citation carries no revision.
- **Link text in every inline citation.** Options put forward: link
  text is required; link text can be empty (the draft design "The work
  model of Sinter", section 7). No lean is recorded. The text makes the
  smaller choice, which adds no condition: link text can be empty.
- **The meaning of `@` in a target.** Options put forward: an exact pin
  by the first digits of an extent hash, for references across
  repositories (the draft design "The work model of Sinter", section
  7); the separator of a revision, `target@rev` (put forward with the
  maintainer). The text reserves `@` and gives it no meaning.
- **A custom namespace for the designs of this repository.** The
  question is put forward in the draft design "The work model of
  Sinter", sections 3.22 and 7, with no options. The text makes the
  smaller choice: the slug of this design is `identifiers`, with no
  custom namespace.
- **The tag word `@term`.** Option put forward: a tag word `@term` that
  declares one term of a dictionary of terms (`docs/roadmap.md`; the
  draft design "The work model of Sinter", section 7). The text makes
  the smaller choice: `@term` is not a Sinter tag word. The kind word
  `term` is in the list, for the terms of external documents. Also
  open: how the rule of revisions applies to a citation of a term. The
  roadmap gives a term no revision and writes a citation of a term as
  `@cites term:ledger/claim`. Under section 2.8, that target reads as
  the slug `ledger` with the label `claim`.
- **The name of a rule in `@ack`.** How `@ack` names a rule that lives
  in a decision record (the draft design "The work model of Sinter",
  section 7). No option is put forward. The text requires a slug as the
  first token of `@ack`, which is the form of the name of a finding
  class today.
