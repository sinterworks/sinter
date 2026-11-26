<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Identifiers
@design identifiers=v1
@cites {
    conformance=v1, text=v1, rfc/5234, rfc/7405, rfc/8259,
    commonmark/0.31.2,
}
Sinter identifiers name items and external references through tag lines, inline Markdown citations, external-namespace ID patterns, and canonical entry forms.

Names, revision labels, content IDs, and external IDs identify items
inside a design and artifacts outside a repository. Tag lines in plain
text and inline citations in Markdown prose carry those references in
compact written forms. Canonical forms write each reference as a single
uniform text.

## Definitions

### Segment

@term segment=v1
@cites text#{text=v1, production=v1}

A segment is a text that matches the production `segment`:

```
alnum      = ALPHA / DIGIT
segment    = 1*alnum *( ( "-" / "_" / "." ) 1*alnum )
```

### Slug

@term slug=v1
@cites {#{segment=v1}, text#{text=v1, production=v1}}

A slug is a text that matches the production `slug`:

```
slug       = segment *( "/" segment )
```

### Part name

@term part-name=v1
@cites {#{segment=v1}, text#{text=v1, production=v1}}

A part name is a text that matches the production `part-name`:

```
part-name  = segment
```

### Full name

@term full-name=v1
@cites {#{slug=v1, part-name=v1}, text#{text=v1, production=v1}}

A full name is a text that matches the production `full-name`:

```
full-name  = slug "#" part-name
```

### Name

@term name=v1
@cites {
    #{slug=v1, part-name=v1, full-name=v1},
    text#{text=v1, production=v1},
}

A name is a text that matches the production `name`:

```
name       = slug / full-name / "#" part-name
```

### Kind word

@term kind-word=v1
@cites text#{text=v1, production=v1}

A kind word is a text that matches the production `kind-word`:

```
kind-word  = %s"atom" / %s"decision" / %s"design" / %s"req"
           / %s"schema" / %s"spec" / %s"term"
```

### Label

@term label=v1
@cites text#{text=v1, production=v1}

A label is a text that matches the production `label`:

```
label     = 1*( %x21-22 / %x24-29 / %x2B / %x2D-2E / %x30-3C
              / %x3E-3F / %x41-5A / %x5C / %x5E-7A / %x7C / %x7E )
```

### Revision

@term revision=v1
@cites {#{label=v1}, text#{text=v1, production=v1}}

A revision is a text that matches the production `revision`:

```
revision  = label / "*"
```

The revision `*` stands for any label.

### Content ID

@term content-id=v1
@cites text#{text=v1, hex-digit=v1, production=v1}

A content ID is a text that matches the production `content-id`, and an
object kind word is a text that matches the production
`object-kind-word`:

```
content-id        = object-kind-word ":" 32hex-digit
object-kind-word  = %s"abandoned" / %s"approval" / %s"atom" / %s"decision"
                  / %s"decline" / %s"delivered" / %s"design" / %s"done"
                  / %s"example" / %s"ext" / %s"name" / %s"pin" / %s"plan"
                  / %s"plan-def" / %s"progress" / %s"req" / %s"schema"
                  / %s"scope" / %s"spec" / %s"task" / %s"task-def"
                  / %s"term" / %s"vector-group" / %s"vector-group-def"
                  / %s"vector-set" / %s"void"
```

### Match

@term match=v1
@cites text#{character=v1, text=v1, slice=v1, production=v1}

A **match** of a text by a production is one complete derivation in which
the text **matches the production**. That derivation fixes one
alternative at each `/`, one repeat count at each repetition (including
an optional sequence in `[ ]`), one terminal value at each range of
terminal values, and one letter case at each case-insensitive string
literal, such that the terminal values equal the characters of the text
in order.

In a match, each use of a rule through a rule name matches a slice of the
text: the slice that holds the characters equal to the terminal values of
that use. One rule use lies **within** another rule use when the
enclosing use reaches the inner use through rule names, directly or
through other rules.

- A match **uses** a rule when a use of that rule matches a slice in that
  match. The text that the rule matches in that match is the text of that
  slice.
- Inside a slice that a use of a first rule matches, the text that a
  second rule matches is the text of the slice of a use of the second
  rule that lies within that use of the first rule.
- A text **uses** a rule by a production when a match of that text by
  that production uses that rule.

## External namespaces and ID patterns

@spec external-ids=v1

External references identify artifacts outside a repository, such as
issue numbers or published standards, under named external namespaces.
ID patterns constrain the syntax of external IDs within each namespace.

### Parameters

@schema external-namespaces=v1
@cites {
    #{namespace-name=v1, id-pattern=v1, valid-id-pattern=v1},
    text#{text=v1, production=v1},
}

A binding of the parameter `external-namespaces` is a finite set of
pairs. Each pair is an **external namespace** of the binding and holds
two texts: a namespace name and an ID pattern. A binding can be empty.

A binding meets the schema `external-namespaces` when all of these
conditions hold:

- Each external namespace's namespace name matches the production
  `namespace-name`.
- No two external namespaces in the binding have the same namespace name.
- Each external namespace's ID pattern is a valid ID pattern
  (`valid-id-pattern`).

Otherwise, the binding does not meet the schema `external-namespaces` and
is invalid.

### Definitions

#### ID patterns

@term id-pattern=v1
@cites text#{text=v1, decimal-numeral=v1, production=v1}

An ID pattern is a text. These productions define the syntax of ID
patterns:

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

The count value of a `count` is the non-negative integer that its
`decimal-numeral` writes. The quantifiers `{n}`, `{n,}`, and `{n,m}` are
the forms `"{" count "}"`, `"{" count ",}"`, and
`"{" count "," count "}"`, where `n` is the count value of the first
`count` and `m` is the count value of the second `count`.

#### ID matches

@atom id-match=v1
@cites {
    #{id-pattern=v1, match=v1},
    text#{
        character=v1, text=v1, slice=v1, code-point-order=v1,
        production=v1,
    },
}

A text of `len` characters matches an ID pattern `P` that matches the
production `pattern` when the slice `(0, len)` of the text matches the
element `pattern` that is the whole match of `P` by the production
`pattern`. An **element** of `P` is a use of a rule in that match of `P`
by the production `pattern`.

A sequence of `k` adjacent slices divides a slice `(from, to)` when:

- `k = 0` and `from = to` (the slice is empty); or
- `k >= 1` and boundaries `b_0, b_1, ..., b_k` of the slice satisfy
  `from = b_0 <= b_1 <= ... <= b_k = to` and form the slices
  `(b_0, b_1), (b_1, b_2), ..., (b_{k-1}, b_k)` in order.

Slices in such a sequence can be empty and can hold different characters.

These rules state when a slice **matches an element** of `P`:

- **`literal`:** the slice holds one character equal to the character of
  that `literal`.
- **`range`:** the slice holds one character that comes neither before
  the first character of that `range` nor after the last character of
  that `range` in `code-point-order`.
- **`single`:** the slice holds one character equal to the character of
  that `single`.
- **`edge-dash`:** the slice holds one character equal to `-`.
- **`class-member`:** the slice matches the element `range` or the
  element `single` of that `class-member`.
- **`char-class`:** the slice matches the element `class-member` of at
  least one `class-member` of that `char-class`, or matches the element
  `edge-dash` of at least one `edge-dash` of that `char-class`.
- **`unit`:** when the `unit` is a `literal` or a `char-class`, the slice
  matches the element `literal` or `char-class`; when the `unit` has the
  form `"(" pattern ")"`, the slice matches the element `pattern` inside
  the parentheses.
- **`piece`:** when the `piece` has no `quantifier`, the slice matches
  the element `unit` of that `piece`; when the `piece` has a
  `quantifier`, a sequence of `k` adjacent slices divides the slice, each
  slice in the sequence matches the element `unit` of that `piece`, and
  `k` satisfies the quantifier: `0 <= k <= 1` for `?`, `k >= 0` for `*`,
  `k >= 1` for `+`, `k = n` for `{n}`, `k >= n` for `{n,}`, and
  `n <= k <= m` for `{n,m}`.
- **`branch`:** a sequence of adjacent slices, one for each `piece` of
  that `branch` in order, divides the slice, and each slice matches the
  corresponding element `piece`.
- **`pattern`:** the slice matches the element `branch` of at least one
  `branch` of that `pattern`.

For an ID pattern that matches the production `pattern` and a text, the
ID match outcome is `"matches"` when the text matches that ID pattern,
and `"does not match"` otherwise.

@example Under the [ID pattern](sinter:#id-pattern=v1) `(a|ab)(c|bcd)`,
the text `abcd` has outcome `"matches"` because the
[slice](sinter:text#slice=v1) `(0, 1)` (`a`) matches the element `branch`
`a` of `(a|ab)` and `(1, 4)` (`bcd`) matches the element `branch` `bcd`
of `(c|bcd)`. Under `(a*){2}b`, the text `b` has outcome `"matches"`
because two empty slices each match the element `unit` `(a*)`.

#### Valid ID patterns

@term valid-id-pattern=v1
@cites {
    #{id-pattern=v1, id-match=v1, match=v1},
    text#{character=v1, text=v1, code-point-order=v1, production=v1},
}

A text is a **valid ID pattern** when all of these conditions hold:

- The text matches the production `pattern`.
- In its match by the production `pattern`, no `range` has a first
  character that comes after its last character in `code-point-order`.
- In its match by the production `pattern`, no quantifier `{n,m}` has
  `n > m`.
- Under `id-match`, the empty text has outcome `"does not match"` against
  that ID pattern.

An ID pattern that does not meet all of these conditions is invalid.

@example The [ID pattern](sinter:#id-pattern=v1) `a{0}b` is valid because
the empty text has outcome `"does not match"` under
[id-match](sinter:#id-match=v1), whereas `a|b*` is invalid because the
empty text matches its second branch.

#### Namespace names

@term namespace-name=v1
@cites text#{text=v1, production=v1}

The production `namespace-name` defines the valid form of a namespace
name:

```
namespace-name  = %x61-7A *( %x61-7A / DIGIT )
                  *( "-" 1*( %x61-7A / DIGIT ) )
```

#### External IDs

@term external-id=v1
@cites {
    #{part-name=v1, namespace-name=v1},
    text#{text=v1, production=v1},
}

An external ID is a text that matches the production `external-id`, and
an external reference is a text that matches the production
`external-ref`:

```
external-ref  = external-id [ "#" part-name ]
external-id   = namespace-name "/" id-text
id-text       = 1*( %x21-22 / %x24-2B / %x2D-2E / %x30-3C / %x3E-3F
                    / %x41-5A / %x5F-7A / %x7C / %x7E )
```

#### External targets

@term external-target=v1
@cites {
    #{
        kind-word=v1, content-id=v1, match=v1,
        external-namespaces=v1, namespace-name=v1,
        external-id=v1, id-match=v1,
    },
    text#{text=v1, production=v1},
}

A text **starts with a kind word** when the text contains `:` and the
text before its first `:` matches the production `kind-word`. The
**unprefixed text** of a text is the text after that kind word and the
first `:` when the text starts with a kind word, and the whole text
otherwise. The **head** of a text is the prefix of its unprefixed text
before the first `#`, `=`, or `[` in that unprefixed text, or the whole
unprefixed text when that unprefixed text contains no `#`, `=`, or `[`.

Under a valid binding of `external-namespaces`, a text is an **external
target** when the text does not match the production `content-id` and
either of these conditions holds:

- The head contains `/`, and the text of the head before its first `/`
  equals the namespace name of an external namespace in the binding.
- The head contains no `/`, and the whole head equals the namespace name
  of an external namespace in the binding.

Under a valid binding of `external-namespaces`, a text is a **valid
external target** when all of these conditions hold:

- The text is an external target under that binding.
- The unprefixed text of that text matches the production `external-ref`.
- In that match by the production `external-ref`, the text that `id-text`
  matches has outcome `"matches"` under `id-match` against the ID pattern
  of the external namespace in the binding whose namespace name equals
  the text that `namespace-name` matches.

@example Under a valid [external-namespaces](sinter:#external-namespaces=v1)
binding that holds two external namespaces, `gh` and
`abcdef0123456789abcdef0123456789`, each with the ID pattern
`[1-9][0-9]*`:

- `gh/42` and `spec:gh/42#section-1` are valid external targets
  ([kind-word](sinter:#kind-word=v1),
  [external-id](sinter:#external-id=v1), [id-match](sinter:#id-match=v1)).
- `gh=v1` and `gh/0` are external targets, but neither is a valid
  external target: `gh=v1` does not match `external-ref`, and `0` has
  outcome `"does not match"` under [id-match](sinter:#id-match=v1)
  against `[1-9][0-9]*`.
- `req:abcdef0123456789abcdef0123456789` matches
  [content-id](sinter:#content-id=v1) and is not an external target,
  whereas `req:abcdef0123456789abcdef0123456789#x=v1` does not match
  `content-id` and is an external target.

### Validating ID patterns

@req validate-id-patterns=v1
@cites {
    conformance#conforming-program=v1,
    #{id-pattern=v1, valid-id-pattern=v1},
    text#text=v1,
}

When a conforming program validates a text as an ID pattern, the program
must return `"valid"` when the text is a valid ID pattern
(`valid-id-pattern`), and must return `"invalid"` otherwise.

### Matching IDs

@req match-ids=v1
@cites {
    conformance#conforming-program=v1,
    #{id-pattern=v1, valid-id-pattern=v1, id-match=v1},
    text#text=v1,
}

When a conforming program matches a text against a valid ID pattern
(`valid-id-pattern`), the program must return the `id-match` outcome for
that ID pattern and text.

### Validating external-namespace bindings

@req validate-bindings=v1
@cites {
    conformance#conforming-program=v1,
    #{external-namespaces=v1},
}

When a conforming program validates a binding of `external-namespaces`,
the program must return `"valid"` when the binding meets the schema
`external-namespaces`, and must return `"invalid"` otherwise.

### Test vectors

#### ID patterns

@schema id-pattern-vector=v1
@cites {
    #{
        vector-line=v1, validate-id-patterns=v1, id-pattern=v1,
        valid-id-pattern=v1,
    },
    text#text=v1,
}

Group `id-patterns` tests `validate-id-patterns`. Each line meets the
schema `vector-line`.

| field | type | meaning |
|---|---|---|
| `input` | string | text to validate as an ID pattern |
| `result` | string | `"valid"` when `input` is a `valid-id-pattern`, `"invalid"` otherwise |
| `values` | object | always `{}` (no output values) |

@example Sample lines testing
[validate-id-patterns](sinter:#validate-id-patterns=v1) with
[valid-id-pattern](sinter:#valid-id-pattern=v1):

```json
{"form":"#id-pattern-vector=v1","group":"id-patterns","input":"[1-9][0-9]*","result":"valid","values":{}}
{"form":"#id-pattern-vector=v1","group":"id-patterns","input":"[0-9]*","note":"the empty id matches it","result":"invalid","values":{}}
```

#### ID matches

@schema id-match-vector=v1
@cites {
    #{
        vector-line=v1, match-ids=v1, id-pattern=v1,
        valid-id-pattern=v1, id-match=v1,
    },
    text#text=v1,
}

Group `id-matches` tests `match-ids`. Each line meets the schema
`vector-line`.

| field | type | meaning |
|---|---|---|
| `input.id-pattern` | string | valid ID pattern (`valid-id-pattern`) |
| `input.id` | string | text matched against `input.id-pattern` |
| `result` | string | `"matches"` or `"does not match"` under `id-match` |
| `values` | object | always `{}` (no output values) |

@example Sample lines testing [match-ids](sinter:#match-ids=v1) with
[id-match](sinter:#id-match=v1):

```json
{"form":"#id-match-vector=v1","group":"id-matches","input":{"id":"42","id-pattern":"[1-9][0-9]*"},"result":"matches","values":{}}
{"form":"#id-match-vector=v1","group":"id-matches","input":{"id":"042","id-pattern":"[1-9][0-9]*"},"result":"does not match","values":{}}
```

#### External-namespace bindings

@schema binding-vector=v1
@cites {
    #{
        vector-line=v1, validate-bindings=v1, external-namespaces=v1,
        namespace-name=v1, id-pattern=v1,
    },
    text#text=v1,
}

Group `bindings` tests `validate-bindings`. Each line meets the schema
`vector-line`.

| field | type | meaning |
|---|---|---|
| `input` | array of objects | binding of `external-namespaces` (`[]` for the empty binding; element order has no meaning) |
| `input[].namespace-name` | string | namespace name of a pair |
| `input[].id-pattern` | string | ID pattern of that pair |
| `result` | string | `"valid"` when `input` meets `external-namespaces`, `"invalid"` otherwise |
| `values` | object | always `{}` (no output values) |

@example Sample lines testing
[validate-bindings](sinter:#validate-bindings=v1) with
[external-namespaces](sinter:#external-namespaces=v1):

```json
{"form":"#binding-vector=v1","group":"bindings","input":[],"result":"valid","values":{}}
{"form":"#binding-vector=v1","group":"bindings","input":[{"id-pattern":"[1-9][0-9]*","namespace-name":"GH"}],"note":"`GH` does not match `namespace-name`","result":"invalid","values":{}}
```

## Tag lines

@spec tag-lines=v1

Tag lines declare items, cite targets, mark status, carry directives,
and introduce examples in text files. A citation can continue on the
next lines while a braced list stays open.

### Definitions

#### Tag lines

@term tag-line=v1
@cites text#{character=v1, line=v1}

A tag line is a line whose first character after any leading spaces
(U+0020) and tabs (U+0009) is `@`.

#### Tag words

@term tag-word=v1
@cites {
    #{tag-line=v1},
    text#{line=v1, text=v1, slice=v1, production=v1},
}

The tag word of a tag line is the text of the longest slice of the line
that starts at the boundary immediately before the first `@` of the line
and matches the production `tag-word`:

```
tag-word  = "@" *( ALPHA / DIGIT / "-" )
```

#### Sinter tag words

@term sinter-tag-word=v1
@cites {#{tag-word=v1}, text#text=v1}

The Sinter tag words are these sixteen tag words, in five sets:

- declaration words: `@atom`, `@decision`, `@design`, `@req`, `@schema`,
  `@spec`, and `@term`;
- citation words: `@cites`, `@refines`, `@satisfies`, `@supersedes`, and
  `@verifies`;
- status word: `@deprecated`;
- directive words: `@ack` and `@extern`;
- example word: `@example`.

A tag word is a Sinter tag word when it equals one of these sixteen
texts.

#### Declarations

@term declaration=v1
@cites #{tag-line=v1, tag-word=v1, sinter-tag-word=v1}

A declaration is a tag line whose tag word is a declaration word.

#### Citations

@term citation=v1
@cites #{tag-line=v1, tag-word=v1, sinter-tag-word=v1}

A citation is a tag line whose tag word is a citation word.

#### Status tags

@term status-tag=v1
@cites #{tag-line=v1, tag-word=v1, sinter-tag-word=v1}

A status tag is a tag line whose tag word is the status word.

#### Directives

@term directive=v1
@cites #{tag-line=v1, tag-word=v1, sinter-tag-word=v1}

A directive is a tag line whose tag word is a directive word. An `@ack`
line is a directive whose tag word is `@ack`. An `@extern` line is a
directive whose tag word is `@extern`.

#### Example tags

@term example-tag=v1
@cites #{tag-line=v1, tag-word=v1, sinter-tag-word=v1}

An example tag is a tag line whose tag word is the example word
(`@example`).

#### Continuation lines

@term continuation-line=v1
@cites {
    #{tag-line=v1, tag-word=v1, citation=v1},
    text#{character=v1, text=v1, line=v1},
}

A blank line is a line that holds zero characters or holds only spaces
(U+0020) and tabs (U+0009).

Only a citation has continuation lines. A citation has continuation
lines only when the character immediately after its tag word is a space
(U+0020) or a tab (U+0009).

For such a citation, a scan determines its continuation lines and builds
a working text. The working text starts as the text of the citation's
line. The scan begins at the first character after the spaces (U+0020)
and tabs (U+0009) that immediately follow the tag word, or at the end of
the working text when no character follows them. At any position of the
scan, the brace count holds two numbers over the characters scanned from
that start before the current position: the count of `{` characters and
the count of `}` characters. At each position, one case applies:

- At a space (U+0020), at a tab (U+0009), or at the end of the working
  text, when the count of `{` does not exceed the count of `}`, the scan
  stops.
- At the end of the working text, when the count of `{` exceeds the
  count of `}` and the next line of the same text exists and is neither
  a tag line nor a blank line, that next line is a continuation line of
  the citation. The scan appends a line feed (U+000A) and the text of
  that line without its leading spaces (U+0020) and tabs (U+0009) to the
  working text, and resumes at that line feed.
- At the end of the working text, when the count of `{` exceeds the
  count of `}` and either no next line exists or the next line is a tag
  line or a blank line, the scan stops.
- At any other character, the scan reads that character (incrementing
  the count of `{` for `{` or the count of `}` for `}`) and advances to
  the next position.

The next line is the line of the same text whose 1-based line number is
1 greater than the line number of the last added continuation line, or 1
greater than the line number of the citation's line when the scan adds
no earlier continuation line.

@example An open [citation](sinter:#citation=v1) continues across
non-blank lines that are not [tag lines](sinter:#tag-line=v1); each
continuation line loses only its leading spaces and tabs:

```text
@cites #{
    segment=v1,
    slug=v1,
}
```

Because an [example tag](sinter:#example-tag=v1) is a
[tag line](sinter:#tag-line=v1), `@example text` after an unclosed
`@cites {docs=v1,` stops the continuation scan and forms its own line
input. Likewise, `@example {` followed by `x` has no continuation line
because only a [citation](sinter:#citation=v1) has continuation lines.

#### Tag-line text

@term tag-line-text=v1
@cites {
    #{tag-line=v1, tag-word=v1, citation=v1, continuation-line=v1},
    text#{character=v1, text=v1, line=v1},
}

For a citation whose character immediately after the tag word is a space
(U+0020) or a tab (U+0009), the text of the tag line is the final
working text that `continuation-line` builds when its scan stops. For
every other tag line, the text of the tag line is the text of its line.

#### Vector selections

@term vector-selection=v1
@cites text#{text=v1, production=v1}

A vector selection is a text that matches the production
`vector-selection`:

```
vector-selection  = "[" group-name "]" / every-vector
group-name        = %x61-7A *( %x61-7A / DIGIT )
                    *( "-" 1*( %x61-7A / DIGIT ) )
every-vector      = "[*]"
```

#### Targets

@term target=v1
@cites {
    #{
        tag-line=v1, tag-word=v1, declaration=v1, citation=v1,
        directive=v1, tag-line-text=v1,
    },
    text#{character=v1, text=v1, slice=v1},
}

The target of a declaration, a citation, or an `@extern` line is the
text of the slice of the text of the tag line that starts immediately
after any spaces (U+0020) and tabs (U+0009) following the tag word. That
slice ends immediately before the first space (U+0020) or tab (U+0009)
before which the characters from the start of that slice hold no more
`{` than `}`, or at the end of the text of the tag line when no such
space or tab follows.

#### Inline descriptions

@term inline-description=v1
@cites {
    #{
        tag-line=v1, tag-word=v1, declaration=v1, citation=v1,
        status-tag=v1, directive=v1, example-tag=v1, tag-line-text=v1,
        target=v1,
    },
    text#{character=v1, text=v1},
}

The inline description of a tag line is a text (which can be empty):

- For a declaration, a citation, or an `@extern` line, the inline
  description is the text of the tag line after its target, without any
  leading spaces (U+0020) and tabs (U+0009).
- For a status tag or an example tag, the inline description is the text
  of the tag line after its tag word, without any leading spaces
  (U+0020) and tabs (U+0009).

An `@ack` line has no inline description.

#### Tag-line layout

@term tag-line-layout=v1
@cites {#{tag-line=v1}, text#{character=v1, production=v1}}

These productions define the horizontal whitespace and trailing content
of a tag line:

```
line-char = %x0-9 / %xB-D7FF / %xE000-10FFFF
indent    = *WSP
gap       = 1*WSP
rest      = [ gap *line-char ]
```

#### Declaration lines

@schema declaration-line=v1
@cites {
    #{
        declaration=v1, tag-line-layout=v1, segment=v1, slug=v1,
        full-name=v1, label=v1,
    },
    text#{text=v1, production=v1},
}

A text meets the schema `declaration-line` when it matches the
production `declaration-line`:

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

#### Citation lines

@schema citation-line=v1
@cites {
    #{
        citation=v1, tag-line-text=v1, tag-line-layout=v1, kind-word=v1,
        content-id=v1, name=v1, slug=v1, part-name=v1, label=v1,
        revision=v1, external-id=v1, vector-selection=v1, match=v1,
    },
    text#{text=v1, slice=v1, production=v1},
}

These productions define the syntax of the text of a citation:

```
citation-line      = indent %s"@cites" gap ( cites-target / cites-list )
                     rest
                   / indent %s"@verifies" gap
                     ( verifies-target / verifies-list ) rest
                   / indent ( %s"@refines" / %s"@satisfies"
                     / %s"@supersedes" ) gap
                     ( fixed-target / fixed-list ) rest
cites-list         = "{" list-space cites-target
                     *( comma cites-target ) [ list-space "," ]
                     list-space "}"
verifies-list      = "{" list-space verifies-target
                     *( comma verifies-target ) [ list-space "," ]
                     list-space "}"
fixed-list         = "{" list-space fixed-target
                     *( comma fixed-target ) [ list-space "," ]
                     list-space "}"
cites-target       = cites-single / cites-scoped
verifies-target    = verifies-single / verifies-scoped
fixed-target       = fixed-single / fixed-scoped
cites-single       = [ kind-word ":" ]
                     ( name "=" revision
                     / name vector-selection
                     / external-ref )
                   / content-id
verifies-single    = [ kind-word ":" ]
                     ( name "=" label
                     / name vector-selection
                     / external-ref )
                   / content-id
fixed-single       = [ kind-word ":" ] ( name "=" label / external-ref )
                   / content-id
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

In a match of a text by the production `citation-line`, the entries of
the match are each slice that `cites-single`, `verifies-single`, or
`fixed-single` matches, and, inside each slice that `cites-scoped`,
`verifies-scoped`, or `fixed-scoped` matches, each slice that
`cites-part`, `verifies-part`, or `fixed-part` matches:

- For a `cites-single`, `verifies-single`, or `fixed-single` slice, the
  entry name is the text that `name`, `external-ref`, or `content-id`
  matches in that slice. When that slice uses `vector-selection`, its
  vector selection is the text that `vector-selection` matches in that
  slice.
- For a `cites-part`, `verifies-part`, or `fixed-part` slice inside an
  enclosing `cites-scoped`, `verifies-scoped`, or `fixed-scoped` slice,
  the entry name is the text that `slug` matches in the enclosing slice,
  `#`, and the text that `part-name` matches in the part slice when the
  enclosing slice uses `slug`, or `#` followed by the text that
  `part-name` matches in the part slice when the enclosing slice uses no
  `slug`. When the part slice uses `vector-selection`, its vector
  selection is the text that `vector-selection` matches in that part
  slice.

A text meets the schema `citation-line` when it has a match by the
production `citation-line` in which no two entries have the same entry
name when neither of the two entries has a vector selection or both
entries have the same vector selection.

@example `@cites {#a=v1, req:#a=v2}` fails `citation-line` because both
entries share entry name `#a` with no
[vector selection](sinter:#vector-selection=v1) (the leading
[kind word](sinter:#kind-word=v1) and [revision](sinter:#revision=v1) do
not distinguish them). By contrast,
`@cites {catalog#descriptor=v1, catalog#descriptor[*]}` meets
`citation-line` because only the second entry carries a
[vector selection](sinter:#vector-selection=v1). Likewise,
`@cites {req:0123456789abcdef0123456789abcdef, term:0123456789abcdef0123456789abcdef}`
meets `citation-line` because the two
[content IDs](sinter:#content-id=v1) have different entry names.

#### Citation entries

@term citation-entry=v1
@cites {
    #{
        citation=v1, tag-word=v1, sinter-tag-word=v1, tag-line-text=v1,
        vector-selection=v1, citation-line=v1, match=v1,
    },
    text#{text=v1, slice=v1, production=v1},
}

In a match of the text of a citation by the production `citation-line`:

- A single target is a slice that `cites-single`, `verifies-single`, or
  `fixed-single` matches.
- A scoped list is a slice that `cites-scoped`, `verifies-scoped`, or
  `fixed-scoped` matches. Each slice inside a scoped list that
  `cites-part`, `verifies-part`, or `fixed-part` matches stands for a
  single target that combines the text of the scoped list before its `{`
  and the text of that part slice.

The citation entries of the match are, in their order in the text of the
citation, the texts of the single targets of the match and the single
targets for which the parts of the scoped lists of the match stand.

The match of a citation entry is its match by the production
`cites-single` when the citation's tag word is `@cites`, by
`verifies-single` when the citation's tag word is `@verifies`, and by
`fixed-single` for every other citation word. The entry name of a
citation entry is the entry name that `citation-line` defines for the
corresponding single-target or scoped-part entry in the match of the
citation. When the match of a citation entry uses `vector-selection`,
the vector selection of the citation entry is the text that
`vector-selection` matches in that match.

#### Status lines

@schema status-line=v1
@cites {
    #{status-tag=v1, tag-line-layout=v1},
    text#{text=v1, production=v1},
}

A text meets the schema `status-line` when it matches the production
`status-line`:

```
status-line  = indent %s"@deprecated" rest
```

#### Extern lines

@schema extern-line=v1
@cites {
    #{directive=v1, tag-line-layout=v1, kind-word=v1, part-name=v1},
    text#{text=v1, production=v1},
}

A text meets the schema `extern-line` when it matches the production
`extern-line`:

```
extern-line  = indent %s"@extern" gap kind-word ":" part-name rest
```

#### Ack lines

@schema ack-line=v1
@cites {
    #{directive=v1, tag-line-layout=v1, slug=v1},
    text#{text=v1, hex-digit=v1, production=v1},
}

A text meets the schema `ack-line` when it matches the production
`ack-line`:

```
ack-line     = indent %s"@ack" gap slug [ gap subject ] gap hash-prefix
               *WSP
subject      = non-wsp [ *line-char non-wsp ]
non-wsp      = %x0-8 / %xB-1F / %x21-D7FF / %xE000-10FFFF
hash-prefix  = 8*64hex-digit
```

#### Example lines

@schema example-line=v1
@cites {
    #{example-tag=v1, tag-line-layout=v1},
    text#{text=v1, production=v1},
}

A text meets the schema `example-line` when it matches the production
`example-line`:

```
example-line  = indent %s"@example" rest
```

#### Line results

@atom line-result=v1
@cites {
    #{
        tag-line=v1, tag-word=v1, sinter-tag-word=v1, declaration=v1,
        citation=v1, status-tag=v1, directive=v1, example-tag=v1,
        continuation-line=v1, tag-line-text=v1, target=v1,
        declaration-line=v1, citation-line=v1, citation-entry=v1,
        status-line=v1, extern-line=v1, ack-line=v1, example-line=v1,
        match=v1, external-namespaces=v1, namespace-name=v1,
        external-id=v1, external-target=v1, id-pattern=v1, id-match=v1,
    },
    text#{text=v1, slice=v1, line=v1, production=v1},
}

For a tag line whose tag word is a Sinter tag word, the schema of the
tag line is `declaration-line` for a declaration, `citation-line` for a
citation, `status-line` for a status tag, `extern-line` for an `@extern`
line, `ack-line` for an `@ack` line, and `example-line` for an example
tag.

Under a valid binding of `external-namespaces`, a match of the text of
such a tag line by its schema's production is a valid tag-line match
when all of these conditions hold:

- For a citation, the match satisfies the duplicate-entry constraint of
  `citation-line`.
- For a declaration, its target is not an external target under that
  binding.
- For a citation, the unprefixed text of each citation entry of the
  match that is an external target under that binding matches the
  production `external-ref`.
- For each slice that `external-id` matches in the match, the text that
  `namespace-name` matches in that slice is the namespace name of a pair
  in that binding, and the text that `id-text` matches in that slice has
  outcome `"matches"` under `id-match` against the ID pattern of that
  pair.

Under a valid binding of `external-namespaces`, the line result of a
line that is not a continuation line of a preceding citation is one of
four outcomes:

- `"not a tag line"`, when the line is not a tag line;
- `"other tag word"`, when the line is a tag line whose tag word is not
  a Sinter tag word;
- `"valid"`, when the line is a declaration, a citation, a status tag, a
  directive, or an example tag, and the text of the tag line has a valid
  tag-line match under that binding;
- `"invalid"`, when the line is a declaration, a citation, a status tag,
  a directive, or an example tag, and the text of the tag line has no
  valid tag-line match under that binding.

### Returning line results

@req give-line-results=v1
@cites {
    conformance#conforming-program=v1,
    #{
        external-namespaces=v1, tag-line=v1, tag-word=v1,
        declaration=v1, citation=v1, status-tag=v1, directive=v1,
        example-tag=v1, continuation-line=v1, target=v1,
        inline-description=v1, citation-entry=v1, ack-line=v1,
        line-result=v1, kind-word=v1, slug=v1, segment=v1, part-name=v1,
        vector-selection=v1, external-id=v1, namespace-name=v1,
        content-id=v1, revision=v1, label=v1, match=v1,
    },
    text#{text=v1, line=v1},
}

Given a text and a valid binding of `external-namespaces`, a conforming
program must return the results of the line inputs of the text in the
order of their first lines. Each citation together with its continuation
lines forms one line input, and each other line of the text forms one
line input. A conforming program must return no separate result for a
continuation line.

For each line input, a conforming program must return its `line-result`
under that binding and its extracted values as follows:

- When `line-result` is `"not a tag line"`, the program must return no
  extracted values.
- When `line-result` is `"other tag word"` or `"invalid"`, the program
  must return only `tag-word` (the line's tag word).
- When `line-result` is `"valid"`, the program must return `tag-word`,
  each applicable line-level value from the first table, and the
  applicable match-level values from the second table. For a citation,
  the program must return `entries` as an ordered sequence holding one
  set of match-level values per citation entry in citation-entry order,
  from the match of that citation entry. For a declaration, an `@extern`
  line, or an `@ack` line, the program must return each applicable
  match-level value directly on the line, from its valid tag-line match.

| field | applies to | value |
|---|---|---|
| `tag-line-kind` | every valid tag line | `"declaration"`, `"citation"`, `"status tag"`, `"directive"`, or `"example tag"`: the one that the tag line is |
| `inline-description` | declaration, citation, status tag, `@extern` line, or example tag | its `inline-description` (can be empty) |
| `subject` | `@ack` line | text that `subject` matches, or empty text when the match uses no `subject` |
| `hash-prefix` | `@ack` line | text that `hash-prefix` matches |

| field | condition | value |
|---|---|---|
| `kind-word` | match uses `kind-word` | text that `kind-word` matches |
| `slug` | match uses `slug` | text that `slug` matches |
| `slug` | `@spec` declaration whose target contains no `#` | text that `segment` matches |
| `custom-namespace` | match uses `slug` and that `slug` contains `/` | text of that `slug` before its last `/` |
| `part-name` | match uses `part-name` | text that `part-name` matches |
| `group-name` | match uses `group-name` | text that `group-name` matches |
| `every-vector` | match uses `every-vector` | fact that every vector is selected |
| `namespace-name` | match uses `external-id` | text that `namespace-name` matches in `external-id` |
| `id` | match uses `external-id` | text that `id-text` matches in `external-id` |
| `content-id` | match uses `content-id` | text that `content-id` matches |
| `revision` | match uses `revision` or `label` | text that `revision` matches, or text that `label` matches when the match uses no `revision` |

### Test vectors

#### Tag lines

@schema tag-line-vector=v1
@cites {
    #{
        vector-line=v1, give-line-results=v1, external-namespaces=v1,
        line-result=v1, tag-line=v1, tag-word=v1, sinter-tag-word=v1,
        declaration=v1, citation=v1, status-tag=v1, directive=v1,
        example-tag=v1, inline-description=v1, ack-line=v1,
        citation-entry=v1, kind-word=v1, slug=v1, segment=v1,
        part-name=v1, vector-selection=v1, namespace-name=v1,
        content-id=v1, label=v1, revision=v1,
    },
    text#{text=v1, line=v1},
}

Six groups test `give-line-results` on one-line texts under a valid
binding of `external-namespaces`: `other-lines` (lines that are not tag
lines or that carry a tag word other than a Sinter tag word),
`declarations`, `citations`, `status-tags`, `directives` (`@extern` and
`@ack` lines), and `examples`. Each line meets the schema `vector-line`.

| field | type | meaning |
|---|---|---|
| `input.binding` | array of objects | valid binding of `external-namespaces` (`[]` for the empty binding; element order has no meaning) |
| `input.binding[].namespace-name` | string | namespace name of a pair in `input.binding` |
| `input.binding[].id-pattern` | string | ID pattern of that pair |
| `input.text` | string | one-line `text` |
| `result` | string | `line-result` (`"not a tag line"` or `"other tag word"` in `other-lines`; `"valid"` or `"invalid"` in the other five groups) |
| `values` | object | extracted values from `give-line-results` (`{}` for `"not a tag line"`, `{"tag-word": ...}` for `"other tag word"` or `"invalid"`, or the valid-line keys for `"valid"`) |

For a valid tag line, `values` holds these keys (with match-level keys
directly on `values` for declarations, `@extern` lines, and `@ack`
lines, and inside each object of `values.entries[]` in citation-entry
order for citations):

| key | JSON type | meaning |
|---|---|---|
| `tag-word` | string | tag word of the line |
| `tag-line-kind` | string | `"declaration"`, `"citation"`, `"status tag"`, `"directive"`, or `"example tag"` |
| `inline-description` | string | inline description (can be `""`; absent for `@ack`) |
| `subject` | string | `@ack` subject (can be `""`) |
| `hash-prefix` | string | `@ack` hash prefix |
| `entries` | array of objects | citation entries in order (citations only) |
| `kind-word` | string | leading kind word |
| `slug` | string | slug (or `segment` for `@spec` without `#`) |
| `custom-namespace` | string | prefix of `slug` before its last `/` |
| `part-name` | string | part name |
| `group-name` | string | vector-selection group name |
| `every-vector` | boolean (`true`) | every-vector selection (`[*]`) |
| `namespace-name` | string | external namespace name |
| `id` | string | external ID text |
| `content-id` | string | content ID |
| `revision` | string | revision (`label` or `*`) |

@example Sample lines testing
[give-line-results](sinter:#give-line-results=v1) for a
[citation](sinter:#citation=v1) and an
[example tag](sinter:#example-tag=v1) under
[external-namespaces](sinter:#external-namespaces=v1):

```json
{"form":"#tag-line-vector=v1","group":"citations","input":{"binding":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"},{"id-pattern":"[1-9][0-9]*","namespace-name":"rfc"}],"text":"@cites {gh/42, rfc/8259#section-6}"},"result":"valid","values":{"entries":[{"id":"42","namespace-name":"gh"},{"id":"8259","namespace-name":"rfc","part-name":"section-6"}],"inline-description":"","tag-line-kind":"citation","tag-word":"@cites"}}
{"form":"#tag-line-vector=v1","group":"examples","input":{"binding":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"},{"id-pattern":"[1-9][0-9]*","namespace-name":"rfc"}],"text":"@example A short example.  "},"result":"valid","values":{"inline-description":"A short example.  ","tag-line-kind":"example tag","tag-word":"@example"}}
```

#### Continuation lines

@schema continuation-line-vector=v1
@cites {
    #{
        vector-line=v1, give-line-results=v1, external-namespaces=v1,
        line-result=v1, tag-line=v1, citation=v1, continuation-line=v1,
        citation-entry=v1, vector-selection=v1,
    },
    text#{text=v1, line=v1},
}

Group `continuation-lines` tests `give-line-results` on texts of one or
more lines that start with a tag line to check which following lines
join a citation as continuation lines and which lines form separate line
inputs. Each line meets the schema `vector-line` and omits `result`.

| field | type | meaning |
|---|---|---|
| `input.binding` | array of objects | valid binding of `external-namespaces` (`[]` for the empty binding; element order has no meaning) |
| `input.binding[].namespace-name` | string | namespace name of a pair in `input.binding` |
| `input.binding[].id-pattern` | string | ID pattern of that pair |
| `input.text` | string | `text` of one or more lines starting with a tag line |
| `values.inputs` | array of objects | one element per line input of `input.text`, in first-line order |
| `values.inputs[].result` | string | `line-result` for that line input |
| `values.inputs[].values` | object | extracted values from `give-line-results` for that line input (`{}` when none); each text field is a JSON string, `every-vector` is `true`, and `entries` is a JSON array of entry objects in citation-entry order |

@example Sample lines testing
[give-line-results](sinter:#give-line-results=v1) and
[continuation-line](sinter:#continuation-line=v1) with an
[example tag](sinter:#example-tag=v1):

```json
{"form":"#continuation-line-vector=v1","group":"continuation-lines","input":{"binding":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"},{"id-pattern":"[1-9][0-9]*","namespace-name":"rfc"}],"text":"@cites {docs=v1,\n@example text"},"note":"the target list is not closed, and the next line is an `@example` tag line; the line `@example text` is an input of its own","values":{"inputs":[{"result":"invalid","values":{"tag-word":"@cites"}},{"result":"valid","values":{"inline-description":"text","tag-line-kind":"example tag","tag-word":"@example"}}]}}
{"form":"#continuation-line-vector=v1","group":"continuation-lines","input":{"binding":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"},{"id-pattern":"[1-9][0-9]*","namespace-name":"rfc"}],"text":"@example {\nx"},"note":"only a citation has continuation lines","values":{"inputs":[{"result":"valid","values":{"inline-description":"{","tag-line-kind":"example tag","tag-word":"@example"}},{"result":"not a tag line","values":{}}]}}
```

## Inline citations

@spec inline-citations=v1

Markdown documents embed references to Sinter items and external IDs
inside prose as links. CommonMark 0.31.2 determines which links and
images a document holds.

### Definitions

#### Links

@term link=v1
@cites {commonmark/0.31.2, text#{text=v1, slice=v1, body=v1}}

The Markdown document of a text is the text of its `body`.

A link of a Markdown document is an inline link, a full reference link,
a collapsed reference link, a shortcut reference link, or an autolink of
that Markdown document, each as CommonMark 0.31.2 defines it. An image
of a Markdown document is an inline image or a reference image of that
Markdown document, as CommonMark 0.31.2 defines it. An image is not a
link.

Each link starts at the 1-based character index of its opening `[` or
`<` in the Markdown document. Each image starts at the 1-based character
index of its opening `!` in the Markdown document.

#### Destinations

@term destination=v1
@cites {
    commonmark/0.31.2,
    #{link=v1},
    text#{character=v1, text=v1},
}

The destination of an inline link or a reference link is its link
destination as CommonMark 0.31.2 defines it. The destination of an
autolink is its URI as CommonMark 0.31.2 defines it.

Neither percent-encoding nor percent-decoding applies to a destination.

@example For the [link](sinter:#link=v1)
`[x](sinter:catalog%23size-limit=v2)`, the destination is
`sinter:catalog%23size-limit=v2` rather than
`sinter:catalog#size-limit=v2`. For `[x](<sinter:docs=v1 x>)`, the
destination is `sinter:docs=v1 x` and keeps its space unencoded. For
`[x](sinter:docs\=v1)` and `[x](sinter:docs&#61;v1)`,
[CommonMark 0.31.2](sinter:commonmark/0.31.2) resolves the backslash
escape and character reference, so both destinations are
`sinter:docs=v1`.

#### Inline citations

@term inline-citation=v1
@cites {#{link=v1, destination=v1}, text#{character=v1, text=v1}}

An inline citation is a link whose destination starts with the exact
seven characters `sinter:`.

The **target** of an inline citation is the text of its destination
after the leading `sinter:`.

#### Link text

@term link-text=v1
@cites {
    commonmark/0.31.2,
    #{link=v1},
    text#{character=v1, text=v1, algorithm=v1},
}

A CommonMark line is a line as CommonMark 0.31.2 defines it, after
CommonMark 0.31.2 replaces each U+0000 with U+FFFD.

The raw content of a paragraph or heading *b* is the text that these
steps give.

1. Let *lines* be the sequence of the CommonMark lines of *b*, in order.
2. If *b* is a setext heading, remove the underline of *b* from *lines*.
3. Let *content* be the empty text.
4. For each *l* of *lines*, in order:
   1. Let *t* be *l* without the markers and indentation of the block
      quotes and list items that hold *b*, as CommonMark 0.31.2 defines
      them.
   2. If *b* is an ATX heading, set *t* to *t* without its opening
      sequence of `#` and its closing sequence of `#`.
   3. While *t* is not empty and the character at 1-based character
      index 1 of *t* is a space (U+0020) or a tab (U+0009):
      1. Remove the character at 1-based character index 1 of *t* from
         *t*.
   4. Append *t* to *content*.
   5. Append a line feed (U+000A) to *content*.
5. If *lines* is not empty, remove the last character of *content* from
   *content*.
6. While *content* is not empty and the last character of *content* is a
   space (U+0020) or a tab (U+0009):
   1. Remove the last character of *content* from *content*.
7. Give *content*.

The link text of an inline link or a reference link is the text between
the `[` that starts the link and the `]` that closes that `[`, as
CommonMark 0.31.2 parses the link, in the raw content of the paragraph
or heading that holds the link. The link text of an autolink is the text
of that autolink between `<` and `>`. Link text keeps every backslash
escape, entity reference, and numeric character reference unchanged.

@example For the [link](sinter:#link=v1)
`[*the* limit](sinter:catalog#size-limit=v2)`, the link text keeps its
markup and is `*the* limit`. Inside a block quote,
`> [the` followed by `> limit](sinter:catalog#size-limit=v2)` has the
link text `the`, U+000A, `limit`. For `[a  ` followed by
`b](sinter:catalog#size-limit=v2)`, step 6 strips trailing spaces only at
the end of the raw content, so the link text keeps the two spaces before
U+000A, although [CommonMark 0.31.2](sinter:commonmark/0.31.2) reads
those spaces as a hard line break.

#### Plain string content

@term plain-string-content=v1
@cites {
    commonmark/0.31.2,
    #{link=v1, link-text=v1},
    text#{character=v1, text=v1},
}

The plain string content of a sequence of inline elements inside the
link text of a link, as CommonMark 0.31.2 parses them, joins in element
order the texts that these rules produce:

- Textual content produces its characters after CommonMark 0.31.2
  replaces each backslash escape, entity reference, and numeric
  character reference.
- A CommonMark 0.31.2 code span produces its code span content.
- Emphasis and strong emphasis each produce the plain string content of
  their enclosed inline elements.
- An autolink produces its text between `<` and `>`, and keeps every
  backslash escape, entity reference, and numeric character reference
  unchanged.
- An image produces the plain string content of the inline elements of
  its image description.
- A soft line break and a hard line break each produce a single line
  feed (U+000A).
- Raw HTML produces the empty text.

The plain string content of the link text of an inline link or a
reference link is the plain string content of the inline elements that
CommonMark 0.31.2 parses between the `[` that starts the link and the
`]` that closes that `[`. The plain string content of the link text of
an autolink is that link text.

@example For `[*the* limit](sinter:catalog#size-limit=v2)`, the
[link text](sinter:#link-text=v1) is `*the* limit`, while its plain
string content is `the limit`. For
`[<!-- -->&nbsp;](sinter:catalog#size-limit=v2)`, raw HTML produces the
empty text and `&nbsp;` resolves under
[CommonMark 0.31.2](sinter:commonmark/0.31.2) to U+00A0, so the plain
string content is U+00A0 alone.

#### Inline destinations

@schema inline-destination=v1
@cites {
    rfc/5234, rfc/7405,
    #{
        inline-citation=v1, destination=v1, kind-word=v1, content-id=v1,
        name=v1, revision=v1, external-id=v1,
    },
    text#{text=v1, production=v1},
}

An inline destination is a destination of an inline citation that
matches the production `inline-destination`:

```
inline-destination  = %s"sinter:"
                      ( [ kind-word ":" ]
                        ( name "=" revision / external-ref )
                      / content-id )
```

#### Link results

@atom link-result=v1
@cites {
    commonmark/0.31.2,
    #{
        link=v1, inline-citation=v1, destination=v1,
        inline-destination=v1, link-text=v1, plain-string-content=v1,
        external-namespaces=v1, external-target=v1, external-id=v1,
        namespace-name=v1, id-pattern=v1, id-match=v1, match=v1,
    },
    text#{character=v1, text=v1, slice=v1, production=v1},
}

A blank character is one of these characters:

- a Unicode whitespace character as CommonMark 0.31.2 defines it; or
- U+200B, U+200C, U+200D, U+2060, or U+FEFF.

Under a valid binding of `external-namespaces`, the link result of a
link or an image of a Markdown document is one of three outcomes:

- `"not an inline citation"`: for an image, or for a link that is not an
  inline citation.
- `"valid"`: for an inline citation when all of these conditions hold:
  1. Its destination matches the production `inline-destination`.
  2. When its target is an `external-target` under that binding, that
     match uses `external-ref`.
  3. When that match uses `external-id`, the text that `namespace-name`
     matches in the slice matched by `external-id` is the namespace name
     of a pair in that binding, and the text that `id-text` matches in
     that slice has outcome `"matches"` under `id-match` against the ID
     pattern of that pair.
  4. The plain string content of its link text holds at least one
     character that is not a blank character.
- `"invalid"`: for an inline citation when one or more of those four
  conditions do not hold.

@example Under an [external-namespaces](sinter:#external-namespaces=v1)
binding that holds two external namespaces, `gh` and
`abcdef0123456789abcdef0123456789`, each with the ID pattern
`[1-9][0-9]*`:

- `[auth](sinter:billing/auth=v3)` has outcome `"valid"`:
  `billing/auth=v3` matches `name "=" revision` in
  [inline-destination](sinter:#inline-destination=v1), and because
  `billing` is not a bound namespace name, its
  [target](sinter:#inline-citation=v1) is not an
  [external target](sinter:#external-target=v1).
- `[x](sinter:gh/42=v2)` has outcome `"invalid"` because its
  [target](sinter:#inline-citation=v1) `gh/42=v2` is an
  [external target](sinter:#external-target=v1) under `gh` and does not
  match `external-ref` ([external-id](sinter:#external-id=v1)).
- `[x](sinter:spec:abcdef0123456789abcdef0123456789)` has outcome
  `"valid"` because a [target](sinter:#inline-citation=v1) that matches
  [content-id](sinter:#content-id=v1) is never an
  [external target](sinter:#external-target=v1).

### Returning link results

@req give-link-results=v1
@cites {
    conformance#conforming-program=v1,
    #{
        external-namespaces=v1, link=v1, destination=v1,
        inline-citation=v1, link-text=v1, inline-destination=v1,
        link-result=v1, kind-word=v1, slug=v1, part-name=v1,
        external-id=v1, namespace-name=v1, content-id=v1, revision=v1,
        match=v1,
    },
    text#{text=v1, production=v1},
}

Given a text and a valid binding of `external-namespaces`, a conforming
program must return the `link-result` under that binding for each link
and each image of the text's Markdown document—and for no other part of
the text—in the order in which those links and images start in the
Markdown document.

For each link whose `link-result` is `"valid"`, the program must also
return every applicable field in this table from its `link-text` and
from the match of its `destination` by the production
`inline-destination`, each once, and no other extracted field. For each
image and each link whose `link-result` is `"not an inline citation"` or
`"invalid"`, the program must return no extracted field.

| field | condition | value |
|---|---|---|
| `link-text` | always | `link-text` of the inline citation |
| `kind-word` | match uses `kind-word` | text that `kind-word` matches |
| `slug` | match uses `slug` | text that `slug` matches |
| `custom-namespace` | match uses `slug` and that `slug` contains `/` | text of that `slug` before its last `/` |
| `part-name` | match uses `part-name` | text that `part-name` matches |
| `namespace-name` | match uses `external-id` | text that `namespace-name` matches in `external-id` |
| `id` | match uses `external-id` | text that `id-text` matches in `external-id` |
| `content-id` | match uses `content-id` | text that `content-id` matches |
| `revision` | match uses `revision` | text that `revision` matches |

### Test vectors

@schema inline-citation-vector=v1
@cites {
    #{
        vector-line=v1, give-link-results=v1, external-namespaces=v1,
        namespace-name=v1, link=v1, link-result=v1, link-text=v1,
        kind-word=v1, slug=v1, part-name=v1, content-id=v1,
        revision=v1,
    },
    text#{text=v1},
}

Group `inline-citations` tests `give-link-results`. Each line meets the
schema `vector-line` and omits `result`.

| field | type | meaning |
|---|---|---|
| `input.binding` | array of objects | valid binding of `external-namespaces` (`[]` for the empty binding; element order has no meaning) |
| `input.binding[].namespace-name` | string | namespace name of a pair in `input.binding` |
| `input.binding[].id-pattern` | string | ID pattern of that pair |
| `input.text` | string | input `text` whose Markdown document can hold links and images |
| `values.links` | array of objects | one element per link and per image of the Markdown document of `input.text`, in start order (`[]` when none exist) |
| `values.links[].result` | string | `link-result` for that link or image |
| `values.links[].values` | object | extracted fields when `result` is `"valid"`; `{}` otherwise |
| `values.links[].values.link-text` | string (optional) | `link-text` field of `give-link-results`; present when `result` is `"valid"` |
| `values.links[].values.kind-word` | string (optional) | `kind-word` field of `give-link-results` |
| `values.links[].values.slug` | string (optional) | `slug` field of `give-link-results` |
| `values.links[].values.custom-namespace` | string (optional) | `custom-namespace` field of `give-link-results` |
| `values.links[].values.part-name` | string (optional) | `part-name` field of `give-link-results` |
| `values.links[].values.namespace-name` | string (optional) | `namespace-name` field of `give-link-results` |
| `values.links[].values.id` | string (optional) | `id` field of `give-link-results` |
| `values.links[].values.content-id` | string (optional) | `content-id` field of `give-link-results` |
| `values.links[].values.revision` | string (optional) | `revision` field of `give-link-results` |

@example Sample lines that test
[give-link-results](sinter:#give-link-results=v1) with
[link-result](sinter:#link-result=v1), [link-text](sinter:#link-text=v1),
and [plain-string-content](sinter:#plain-string-content=v1):

```json
{"form":"#inline-citation-vector=v1","group":"inline-citations","input":{"binding":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"},{"id-pattern":"[1-9][0-9]*","namespace-name":"rfc"}],"text":"[the size limit](sinter:req:catalog#size-limit=v2)"},"values":{"links":[{"result":"valid","values":{"kind-word":"req","link-text":"the size limit","part-name":"size-limit","revision":"v2","slug":"catalog"}}]}}
{"form":"#inline-citation-vector=v1","group":"inline-citations","input":{"binding":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"},{"id-pattern":"[1-9][0-9]*","namespace-name":"rfc"}],"text":"[&nbsp;](sinter:catalog#size-limit=v2)"},"note":"the plain string content of the link text is U+00A0, a blank character","values":{"links":[{"result":"invalid","values":{}}]}}
```

## Canonical forms

@spec canonical-forms=v1

Different citation entries and different inline citations can name the
same thing. A canonical form writes each of them as one text.

### Definitions

#### Canonical forms of entries and targets

@term canonical-entry=v1
@cites {
    #{
        slug=v1, name=v1, kind-word=v1, content-id=v1, match=v1,
        external-id=v1, citation=v1, tag-line-text=v1,
        vector-selection=v1, citation-line=v1, citation-entry=v1,
        destination=v1, inline-citation=v1, inline-destination=v1,
    },
    text#{character=v1, text=v1, production=v1, algorithm=v1},
}

In this term, *c* is either a citation entry from a match of the text of
a citation by the production `citation-line`, or the target of an inline
citation whose destination matches the production `inline-destination`.
In this term, *s* is a slug or the empty text. In this term, *k* is a
kind word or the empty text. For the target of an inline citation whose
destination has a match by the production `inline-destination`, the
**entry name** of that target is the text that `name`, `external-ref`,
or `content-id` matches in that match of the destination.

The canonical form of *c* with a slug *s* and a kind word *k* is the
text that these steps give.

1. Let *n* be the entry name of *c*.
2. If *c* matches the production `content-id`, give *n*.
3. If *s* is not empty and the first character of *n* is `#`, then:
   1. Let *full* be *s*.
   2. Append *n* to *full*.
   3. Set *n* to *full*.
4. Let *form* be the empty text.
5. If *k* is not empty, then:
   1. Append *k* to *form*.
   2. Append `:` to *form*.
6. Append *n* to *form*.
7. If *c* is a citation entry whose match uses `vector-selection`,
   append the vector selection of *c* to *form*.
8. Give *form*.

@example Canonical forms of [citation entries](sinter:#citation-entry=v1)
and [inline-citation](sinter:#inline-citation=v1) targets across
[slugs](sinter:#slug=v1), [kind words](sinter:#kind-word=v1),
[vector selections](sinter:#vector-selection=v1),
[external IDs](sinter:#external-id=v1) (under an
[external-namespaces](sinter:#external-namespaces=v1) binding that holds
`gh`), and [content IDs](sinter:#content-id=v1):

| entry or target | enclosing slug | kind word | canonical form |
|---|---|---|---|
| `#notation=v1` | `docs` | `term` | `term:docs#notation` |
| `#notation=v1` | none | `req` | `req:#notation` |
| `spec:catalog#size=*` | `docs` | `req` | `req:catalog#size` |
| `docs#descriptor[offsets]` | none | `spec` | `spec:docs#descriptor[offsets]` |
| `gh/42` | `docs` | none | `gh/42` |
| `task:0123456789abcdef0123456789abcdef` | `docs` | `req` | `task:0123456789abcdef0123456789abcdef` |

For the inline citation `[the notation](sinter:#notation=v1)`, the
target is `#notation=v1`, so with the enclosing slug `docs` and the kind
word `term`, its canonical form is `term:docs#notation`.

### Returning canonical forms

@req give-canonical-entries=v1
@cites {
    conformance#conforming-program=v1,
    #{
        external-namespaces=v1, slug=v1, kind-word=v1, citation=v1,
        citation-entry=v1, line-result=v1, inline-citation=v1,
        link-result=v1, canonical-entry=v1,
    },
    text#text=v1,
}

Given a text and a valid binding of `external-namespaces`, a conforming
program takes a `slug` or no `slug`, a `kind-word` or no `kind-word`,
and either a citation entry of a citation in that text whose
`line-result` is `"valid"` or the target of an inline citation in that
text whose `link-result` is `"valid"`. When the program returns the
canonical form of that citation entry or target, the program must return
its canonical form (`canonical-entry`) with that `slug` (or the empty
text when the program takes no `slug`) and with that `kind-word` (or the
empty text when the program takes no `kind-word`).

### Test vectors

@schema canonical-entry-vector=v1
@cites {
    #{
        vector-line=v1, give-canonical-entries=v1,
        external-namespaces=v1, slug=v1, kind-word=v1, tag-line=v1,
        citation=v1, continuation-line=v1, citation-entry=v1,
        line-result=v1, link=v1, inline-citation=v1, link-result=v1,
        canonical-entry=v1,
    },
    text#{text=v1, line=v1},
}

Group `canonical-entries` tests `give-canonical-entries`. Each line
meets the schema `vector-line` and omits `result`.

| field | type | meaning |
|---|---|---|
| `input.binding` | array of objects | valid binding of `external-namespaces` (`[]` for the empty binding; element order has no meaning) |
| `input.binding[].namespace-name` | string | namespace name of a pair in `input.binding` |
| `input.binding[].id-pattern` | string | ID pattern of that pair |
| `input.text` | string | `text` holding either one `citation` (`line-result` is `"valid"`, all remaining lines are its `continuation-line` lines, and the Markdown document holds no `link` or image) or no `tag-line` and one `inline-citation` (`link-result` is `"valid"`, and the Markdown document holds no other `link` or image) |
| `input.slug` | string (optional) | enclosing `slug`; absent when the input supplies no `slug` |
| `input.entries` | array of objects | one element per `citation-entry` of the `citation`, in order, or one element for the target of the `inline-citation` |
| `input.entries[].kind-word` | string (optional) | `kind-word` for that entry or target; absent when the input supplies no `kind-word` (leaving `{}`) |
| `values.forms` | array of strings | canonical form (`canonical-entry`) for each corresponding element of `input.entries`, in order |

@example Sample lines testing
[give-canonical-entries](sinter:#give-canonical-entries=v1) with
[canonical-entry](sinter:#canonical-entry=v1) on a
[citation](sinter:#citation=v1) and an
[inline-citation](sinter:#inline-citation=v1):

```json
{"form":"#canonical-entry-vector=v1","group":"canonical-entries","input":{"binding":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"},{"id-pattern":"[1-9][0-9]*","namespace-name":"rfc"}],"entries":[{"kind-word":"req"},{"kind-word":"spec"}],"text":"@cites catalog#{size=v1, descriptor=v2}"},"note":"each part of a scoped list gives the canonical form of the single target for which it stands","values":{"forms":["req:catalog#size","spec:catalog#descriptor"]}}
{"form":"#canonical-entry-vector=v1","group":"canonical-entries","input":{"binding":[{"id-pattern":"[1-9][0-9]*","namespace-name":"gh"},{"id-pattern":"[1-9][0-9]*","namespace-name":"rfc"}],"entries":[{"kind-word":"term"}],"slug":"docs","text":"[the notation](sinter:#notation=v1)"},"note":"the target of an inline citation: the slug goes before a name that starts with `#`, and the revision is dropped","values":{"forms":["term:docs#notation"]}}
```

## Test vectors

@schema vector-line=v1
@cites {
    rfc/8259,
    conformance#{design=v1, conforming-program=v1, input=v1},
    text#{
        canonical-vector-line=v1, byte-sequence=v1, valid-utf-8=v1,
        utf-8-text=v1, character=v1, text=v1, line=v1, production=v1,
    },
    #{part-name=v1, label=v1},
}

The test-vector file
[`identifiers.test-vectors.jsonl`](identifiers.test-vectors.jsonl) is a
`valid-utf-8` byte sequence that holds zero or more vector lines. Its
`utf-8-text` has no leading byte order mark (U+FEFF), no carriage return
(U+000D), and no empty line. When non-empty, its `utf-8-text` ends with a
single line feed (U+000A). Only a line feed ends a line of the file.
Characters U+0085, U+2028, and U+2029 can appear inside JSON strings and
do not end a line.

Each line of the file is a vector line: a JSON text (RFC 8259) that meets
`canonical-vector-line` and holds only these members, with at least one
of `result` or `values` present. All vector lines in the file with the
same `group` name the same `#` and `part-name` in `form` (their `label`
values can differ).

| field | type | meaning |
|---|---|---|
| `form` | string | `"#<part-name>=<label>"`, where `<part-name>` matches the production `part-name` and names a vector-group schema of this design and `<label>` matches the production `label` |
| `group` | string | lowercase hyphenated group name (an ASCII lowercase letter followed by zero or more ASCII lowercase letters or digits, plus zero or more `-` each followed by one or more ASCII lowercase letters or digits) that equals one of the group names that the vector-group schema named in `form` states |
| `input` | JSON value | input data handed to a conforming program in the form defined by the group schema |
| `note` | string (optional) | non-normative explanation; ignored by conforming programs |
| `result` | string (optional) | expected result string, without surrounding quotation marks, when the group tests one |
| `values` | object (optional) | expected structured outputs defined by the group schema; `{}` when no output values apply |

In every vector of this file, a text appears as a JSON string that holds
its characters in order (`""` for the empty text), and an ordered
sequence appears as a JSON array of its elements in order (`[]` for an
empty sequence).
