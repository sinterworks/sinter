<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Text and notation
@design text=v1
@cites {
    conformance=v1,
    rfc/3629,
    rfc/5234,
    rfc/7405,
    rfc/8259,
}
Text processing converts between UTF-8 byte sequences and Unicode scalar-value texts, divides bodies into lines, and locates characters and spans by line and column, and designs use notations for grammars, algorithms, and test vectors.

Raw files arrive as byte sequences, while syntax tools work on decoded
characters. A file can start with a byte order mark. Line endings divide
the content of a text into lines. A line number and a column locate a
character or a span.

Designs can also use exact notations for grammars, for computed values,
and for test cases.

## Definitions

### Characters

@term character=v1

A code point is an integer from 0 to 1,114,111 (U+0000 to U+10FFFF). A
Unicode scalar value is a code point from 0 to 55,295 (U+0000 to U+D7FF) or
from 57,344 to 1,114,111 (U+E000 to U+10FFFF), excluding surrogate code
points (U+D800 to U+DFFF). Each character has one code point, which is a
Unicode scalar value. Each Unicode scalar value is the code point of one
character.

### Texts

@term text=v1
@cites #{character=v1}

A text is a finite sequence of characters. The empty text is the text of
zero characters.

For a text of `n` characters, its 1-based character indices are the integers
from 1 to `n`. The character at 1-based character index `k` is the `k`-th
character of the text, starting with the first character at index 1.

Two texts are equal when they have the same number of characters and the
same character at every 1-based character index. Text equality is exact:
letter case matters (`a` and `A` are distinct), and no Unicode
normalization applies (U+00E9 and `e` followed by U+0301 are distinct).

### Code point order

@term code-point-order=v1
@cites #{character=v1, text=v1}

Character A comes before character B in code point order (and B comes after
A) when the code point of A is less than the code point of B.

Text A comes before text B in code point order (and B comes after A) when
either of these conditions holds:

- At the first 1-based character index where A and B differ, the character
  of A comes before the character of B in code point order.
- A has fewer characters than B, and A and B hold the same character at
  every 1-based character index of A.

Code point order compares raw Unicode scalar values directly, with no
UTF-16 surrogate ordering, locale collation, or Unicode normalization. A
leading U+FEFF compares as any other character.

### Slices

@term slice=v1
@cites #{character=v1, text=v1}

A boundary of a text of `n` characters is an integer from 0 to `n`. Boundary
0 lies before 1-based character index 1. Each boundary `k` from 1 to `n`
lies right after 1-based character index `k`.

A slice of a text is identified by a start boundary `from` and an end
boundary `to` of that text, written `(from, to)`, with
`0 <= from <= to <= n`. The slice holds the characters at 1-based character
indices `from + 1` through `to`, in order, each at its original index; those
indices are the character indices of the slice. When `from = to`, the slice
is empty and holds no character.

The text of a slice is the text formed by its characters in order. A
boundary of a slice is any boundary `b` of the text with
`from <= b <= to`.

Two slices of a text are equal when they have the same `from` boundary and
the same `to` boundary.

@example In the [text](sinter:#text=v1) `aba`, the slice from boundary 0 to
boundary 1 and the slice from boundary 2 to boundary 3 are distinct slices
even though both have the text `a`. Likewise, the empty slice `(1, 1)` and
the empty slice `(2, 2)` are distinct slices.

### Bodies

@term body=v1
@cites #{character=v1, text=v1, slice=v1}

A text has a byte order mark when the character at 1-based character index
1 is U+FEFF (code point 65,279). That character at index 1 is the byte
order mark of the text. Any U+FEFF at a later character index is an
ordinary character.

The body of a text of `n` characters is the slice `(1, n)` when the text
has a byte order mark, and the slice `(0, n)` otherwise. A character index
of the body is a character index of that slice. A boundary of the body is a
boundary of that slice.

### Lines

@term line=v1
@cites #{character=v1, text=v1, slice=v1, body=v1}

A line ending of a text is a slice of the text ending at boundary `p`, where
1-based character index `p` lies in the body and holds a line feed (U+000A):

- When index `p - 1` also lies in the body and holds a carriage return
  (U+000D), the line ending is the slice `(p - 2, p)`.
- Otherwise, the line ending is the slice `(p - 1, p)`.

No other character forms a line ending. A carriage return not immediately
followed by a line feed, and other Unicode line-break characters (U+000B,
U+000C, U+0085, U+2028, and U+2029), belong to lines as ordinary characters.

A line of a text is a slice of the text that meets all of these conditions:

- The slice starts at the start boundary of the body, or at the end boundary
  of a line ending.
- The slice ends at the earliest boundary at or after its start where a line
  ending starts, or at the end boundary of the body when no line ending
  starts at or after its start.
- When the slice ends at the end boundary of the body, the slice is
  non-empty.

An empty body has no lines. A body that ends with a line ending has no
trailing empty line after that line ending.

Each line has a 1-based line number. The line starting at the start boundary
of the body has line number 1, and each later line has a line number 1
greater than the preceding line. The lines of a text stand in line-number
order.

@example Lines of [texts](sinter:#text=v1) with line feeds, a CRLF line
ending, a lone carriage return, a byte order mark, and U+2028, as
[slices](sinter:#slice=v1) of the [body](sinter:#body=v1):

| text | line slices | line texts |
|---|---|---|
| `a`, U+000A, `b` | `(0, 1)`, `(2, 3)` | `a`; `b` |
| `a`, U+000A | `(0, 1)` | `a` |
| U+000A | `(0, 0)` | empty text |
| empty text | none | none |
| `ab`, U+000D, U+000A, `c` | `(0, 2)`, `(4, 5)` | `ab`; `c` |
| `a`, U+000D | `(0, 2)` | `a`, U+000D |
| U+FEFF, `x` | `(1, 2)` | `x` |
| `a`, U+2028, `b` | `(0, 3)` | `a`, U+2028, `b` |

### Positions

@term position=v1
@cites #{character=v1, text=v1, slice=v1, body=v1, line=v1}

A position is a pair of positive integers: a 1-based line number and a
1-based column. Columns count characters (Unicode scalar values), not
bytes; a tab (U+0009) counts as one column.

Every boundary `b` of the body of a text has a position given by the first
matching case:

1. A line starts at boundary `s <= b` and ends at boundary `e >= b`: the
   line number is the line number of that line, and the column is
   `(b - s) + 1`.
2. A line ending starts at boundary `e < b` and ends at boundary `f > b`
   (boundary `b` sits between the carriage return and the line feed of a
   CRLF line ending): the line number is the line number of the line that
   ends at boundary `e`, and the column is `(e - s) + 1`, where `s` is the
   start boundary of that line.
3. Otherwise (the body is empty or ends with a line ending, and `b` is the
   end boundary of the body): the line number is `L + 1`, where `L` is the
   number of lines of the text (no line has that line number), and the
   column is 1.

The position of a 1-based character index `p` in the body (and of the
character at index `p`) is the position of boundary `p - 1`.

@example Character positions in the [body](sinter:#body=v1) of a
[text](sinter:#text=v1) across [lines](sinter:#line=v1), CRLF line
endings, multi-byte characters, and a leading byte order mark:

| text | 1-based character index | position |
|---|---|---|
| `ab`, U+000A, `c` | 4 (`c`) | line 2, column 1 |
| `ab`, U+000D, U+000A, `c` | 3 (U+000D) | line 1, column 3 |
| `ab`, U+000D, U+000A, `c` | 4 (U+000A) | line 1, column 3 |
| U+00E9, `x` | 2 (`x`) | line 1, column 2 |
| `e`, U+0301, `x` | 3 (`x`) | line 1, column 3 |
| U+FEFF, `x` | 2 (`x`) | line 1, column 1 |

### Spans

@term span=v1
@cites #{text=v1, slice=v1, body=v1, line=v1, position=v1}

A span of a text is a slice of the text whose `from` and `to` boundaries
are both boundaries of the body.

The start of a span is the position of its `from` boundary. When one or
more character indices of the span belong to a line, the end of the span is
the position of boundary `k`, where `k` is the last 1-based character index
of the span that belongs to a line. Otherwise (including for any empty span
or any span holding only line-ending characters), the end of the span is
the start of the span.

@example Span [positions](sinter:#position=v1) of a
[slice](sinter:#slice=v1) in the [body](sinter:#body=v1) of a
[text](sinter:#text=v1), showing that trailing [line](sinter:#line=v1)
endings do not advance the end position and empty spans have `end = start`:

| text | span slice | start | end |
|---|---|---|---|
| `abc` | `(1, 2)` | line 1, column 2 | line 1, column 3 |
| `ab`, U+000D, U+000A, `cd` | `(1, 5)` | line 1, column 2 | line 2, column 2 |
| `ab`, U+000D, U+000A, `cd` | `(0, 4)` | line 1, column 1 | line 1, column 3 |
| `a =` | `(3, 3)` | line 1, column 4 | line 1, column 4 |
| `a`, U+000A | `(2, 2)` | line 2, column 1 | line 2, column 1 |
| empty text | `(0, 0)` | line 1, column 1 | line 1, column 1 |

### Productions

@term production=v1
@cites {
    rfc/5234, rfc/7405, conformance#design=v1,
    #{character=v1, text=v1},
}

ABNF is the grammar notation of RFC 5234 extended with the case-sensitive
string literals (`%s"..."`) of RFC 7405. A declared item `R` of a design
holds each ABNF rule written in a fenced code block of `R`.

A rule name inside an ABNF rule held by `R` resolves case-insensitively to
any rule with that name that is one of these:

- a core rule of RFC 5234, Appendix B.1;
- an ABNF rule held by `R`; or
- an ABNF rule held by a definition `Q` that `R` cites.

A production is an ABNF rule held by a declared item of a design such that
the rule itself, and every non-core rule that it reaches through rule names,
contains no prose value (`<...>`) and has each rule name resolve to a single
rule.

Each terminal value in a production, or in any core rule that a production
uses, matches the character whose code point equals that terminal value. A
terminal value that is not a Unicode scalar value matches no character.

A text matches a production when the production derives the characters of
the whole text in order, choosing one alternative at each `/` (regardless of
alternative order), one terminal value from each range of terminal values,
one letter case at each case-insensitive string literal, and one repeat
count at each repetition. A character matches a production when the
one-character text holding that character matches the production.

### Decimal numerals

@term decimal-numeral=v1
@cites #{text=v1, production=v1}

A decimal numeral is a text that matches the production `decimal-numeral`:

```
decimal-numeral  = "0" / ( %x31-39 *DIGIT )
```

A decimal numeral writes a non-negative integer in base 10 with no leading
zero except `"0"` for 0. The decimal numeral of a non-negative integer is
the unique decimal numeral that writes that integer.

### Hex digits

@term hex-digit=v1
@cites #{character=v1, production=v1}

A hex digit is a character that matches the production `hex-digit`:

```
hex-digit  = DIGIT / %x61-66
```

A hex digit writes an integer from 0 to 15: `0` to `9` write 0 to 9, and
lowercase `a` to `f` write 10 to 15. Uppercase `A` to `F` are not hex
digits. The hex digit of an integer from 0 to 15 is the hex digit that
writes that integer.

### Byte sequences

@term byte-sequence=v1
@cites #{character=v1, text=v1}

A byte is an integer from 0 to 255. A byte is distinct from a character.

A byte sequence is a finite sequence of bytes. The empty byte sequence is
the byte sequence of zero bytes. A byte sequence is distinct from a text.

For a byte sequence of `n` bytes, its 1-based byte indices are the integers
from 1 to `n`, where the byte at 1-based byte index `k` is the `k`-th byte
in order. Two byte sequences are equal when they have the same number of
bytes and the same byte at every 1-based byte index.

### Valid UTF-8

@term valid-utf-8=v1
@cites {rfc/3629, #{byte-sequence=v1}}

A byte sequence is valid UTF-8 when the `UTF8-octets` rule of RFC 3629
matches the whole byte sequence, with each terminal value interpreted as
one byte.

### UTF-8 texts

@term utf-8-text=v1
@cites {rfc/3629, #{character=v1, text=v1, byte-sequence=v1, valid-utf-8=v1}}

For a byte sequence that is valid UTF-8, its UTF-8 text is the text holding,
in order, the character encoded by each `UTF8-char` matched by the
`UTF8-octets` rule of RFC 3629.

The UTF-8 text keeps a leading U+FEFF (0xEF, 0xBB, 0xBF) at 1-based
character index 1, keeps every carriage return, and keeps every character
without Unicode normalization.

### UTF-8 encodings

@term utf-8-encoding=v1
@cites {rfc/3629, #{character=v1, text=v1, byte-sequence=v1}}

The UTF-8 encoding of a text is the byte sequence holding, in order, the
bytes that encode each character of the text as RFC 3629 defines UTF-8.

### Algorithms

@term algorithm=v1
@cites {
    conformance#design=v1,
    #{character=v1, text=v1, byte-sequence=v1, decimal-numeral=v1},
}

An algorithm inside a definition of a design specifies a computed value
through a single-sentence header paragraph followed by a numbered list of
steps. An algorithm defines only the value it gives, not how a program
computes that value.

The header has the form `The <name> of <inputs> is the <kind> that these
steps give.`, where `<name>` contains no ` of `. A value name is one or
more lowercase ASCII words (`a` to `z`) joined by `-` and written in
italics (such as `*s*` or `*next-line*`). Each input value name appears
once in `<inputs>` and nowhere in `<name>` or `<kind>`. In an algorithm, a
text is a sequence of characters indexed from 1, a byte sequence is a
sequence of bytes indexed from 1, and a code span stands for the literal
text of its characters.

Top-level steps and nested substeps are numbered sequentially from 1 using
decimal numerals followed by `.` and a space. Steps ending in `:` take one
or more indented substeps; no other step has substeps. Each step uses one
of these forms (where `*n*`, `*m*`, and `*s*` are value names, `V` is a
value, `C` is a condition, and `S` is a sequence):

- `Let *n* be V.` — introduces a new mutable value name `*n*` bound to `V`
  for the remaining steps at the same level and their substeps.
- `Set *n* to V.` — rebinds an existing `Let` value name `*n*` to `V`.
- `If C, then:` (with substeps) or `If C, <action>.` (where `<action>` is a
  lowercase `set`, `append`, `remove`, or `give` step) — executes when `C`
  holds.
- `Otherwise:` (with substeps) or `Otherwise, <action>.` — immediately
  follows an `If` step at the same level and executes only when that `If`
  condition does not hold.
- `For each *m* of S, in order:` (with substeps) — takes the elements of
  `S` as evaluated at loop entry and executes the substeps once per element
  in order with `*m*` bound to that element.
- `While C:` (with substeps) — repeats its substeps while `C` holds.
- `Append V to *s*.` — updates `*s*` with `V` appended. When `*s*` holds a
  text and `V` is a text, or `*s*` holds a byte sequence and `V` is a byte
  sequence, this step appends the elements of `V` in order; otherwise it
  appends `V` as a single element. When `*s*` was last initialized by `Let`
  or `Set` to `the empty sequence`, `*s*` is a generic sequence rather than
  a text or byte sequence.
- `Remove V from *s*.` — updates `*s*` by removing the element or elements
  identified by `V`, preserving the order of the remaining elements.
- `Give V.` — ends evaluation and produces `V` as the algorithm's value.

Value names do not shadow an already visible value name, and only
`Let`-bound value names can be updated by `Set`, `Append`, or `Remove`.
Values are pure: updating one value name never alters another value name's
value or an active `For each` sequence. Steps can refer to terms and invoke
other algorithms held by definitions that the enclosing definition cites (or
invoke the same algorithm recursively) using `<name>`, then ` of `, then
`<inputs>` with a value in place of each input value name; other words of
`<inputs>` can be omitted. Evaluation executes steps and substeps in order
and reaches a `Give` step in finitely many steps for every choice of values
of its input value names.

@example An algorithm that replaces each tab (U+0009) in a
[text](sinter:#text=v1) with a space (U+0020):

The spaced text of a text *t* is the text that these steps give.

1. Let *s* be the empty text.
2. For each *c* of *t*, in order:
   1. If *c* is U+0009, append U+0020 to *s*.
   2. Otherwise, append *c* to *s*.
3. Give *s*.

For `a`, U+0009, `b`, these steps give `a`, U+0020, `b`.

## Requirements

### Decoding UTF-8

@req decode-utf-8=v1
@cites {
    conformance#conforming-program=v1,
    #{byte-sequence=v1, text=v1, valid-utf-8=v1, utf-8-text=v1},
}

When decoding a byte sequence as UTF-8, a conforming program must return
`"valid"` and the UTF-8 text of that byte sequence when the byte sequence is
valid UTF-8, and must return `"invalid"` with no text otherwise.

### Encoding UTF-8

@req encode-utf-8=v1
@cites {
    conformance#conforming-program=v1,
    #{text=v1, byte-sequence=v1, utf-8-encoding=v1},
}

When encoding a text as UTF-8, a conforming program must return the UTF-8
encoding of that text.

### Giving lines

@req give-lines=v1
@cites {
    conformance#conforming-program=v1,
    #{text=v1, slice=v1, line=v1},
}

When splitting a text into lines, a conforming program must return the lines
of the text in 1-based line-number order—as slices, as line texts, or
both—with no missing or extra lines. When looking up a line of a text by
line number, a conforming program must return the slice or text of the line
with that line number, and no line for a line number that the text does not
have.

### Giving character positions

@req give-character-positions=v1
@cites {
    conformance#conforming-program=v1,
    #{character=v1, text=v1, body=v1, position=v1},
}

When returning the line number of the character at a 1-based character
index in the body of a text, a conforming program must return the 1-based
line number of that character's position. When returning the column of the
character at a 1-based character index in the body of a text, a conforming
program must return the 1-based column of that character's position.

### Giving span positions

@req give-span-positions=v1
@cites {
    conformance#conforming-program=v1,
    #{text=v1, span=v1, position=v1},
}

When returning the line number of the start of a span of a text, a
conforming program must return the 1-based line number of that start
position. When returning the column of the start of a span of a text, a
conforming program must return the 1-based column of that start position.
When returning the line number of the end of a span of a text, a
conforming program must return the 1-based line number of that end
position. When returning the column of the end of a span of a text, a
conforming program must return the 1-based column of that end position.

## Test vectors

Test vectors for this design live in
[`text.test-vectors.jsonl`](text.test-vectors.jsonl). Texts appear as JSON
strings holding their characters in order.

### Canonical vector lines

@schema canonical-vector-line=v1
@cites {
    rfc/8259,
    #{character=v1, text=v1, code-point-order=v1, hex-digit=v1},
}

A canonical vector line is a JSON text (RFC 8259) holding one JSON object
that satisfies all of these rules:

| aspect | rule |
|---|---|
| unique keys | No JSON object has two members with the same decoded name (after resolving JSON string escapes). |
| key order | The members of every JSON object stand in `code-point-order` of their decoded names. |
| values and numbers | No value is `null`, a number with a fraction or exponent, `-0`, or an integer outside `-9,007,199,254,740,991` to `9,007,199,254,740,991`. |
| whitespace | No space (U+0020), tab (U+0009), line feed (U+000A), or carriage return (U+000D) appears outside JSON strings. |
| string escapes | Inside JSON strings, `"` is `\"`, `\` is `\\`, and U+0008, U+0009, U+000A, U+000C, and U+000D are `\b`, `\t`, `\n`, `\f`, and `\r`. Every other control character in U+0000 to U+001F is `\u00` plus two `hex-digit` characters (high nibble first). Every other character stands literally as itself. |

### Vector lines

@schema vector-line=v1
@cites {
    rfc/8259,
    conformance#{conforming-program=v1, design=v1, input=v1},
    #{
        canonical-vector-line=v1, byte-sequence=v1, valid-utf-8=v1,
        utf-8-text=v1, character=v1, text=v1, body=v1, line=v1,
        decimal-numeral=v1,
    },
}

A test-vector file of this design is a `valid-utf-8` byte sequence holding
zero or more vector lines. Its `utf-8-text` has no leading byte order mark
(U+FEFF), no carriage return (U+000D), and no empty line, and ends with a
single line feed (U+000A) when non-empty. Characters U+0085, U+2028, and
U+2029 can appear inside JSON strings and do not end a line.

Each line of the file is a vector line: a `canonical-vector-line` JSON
object holding only these members, with at least one of `result` or
`values` present. All vector lines in the file with the same `group` name
the same `#<schema-name>` in `form` (their revision labels can differ).

| field | type | meaning |
|---|---|---|
| `form` | string | `"#<schema-name>=v<n>"`, naming a vector-group schema of this design and a positive `decimal-numeral` revision label |
| `group` | string | name of the vector group |
| `input` | JSON value | input handed to a conforming program |
| `note` | string (optional) | non-normative explanation; ignored by conforming programs |
| `result` | string (optional) | expected result, such as `"valid"`, when the group tests one |
| `values` | object (optional) | expected outputs defined by the group schema; `{}` when no output values apply |

### UTF-8 decoding vectors

@schema decode-vector=v1
@cites {
    #{
        vector-line=v1, decode-utf-8=v1, byte-sequence=v1, valid-utf-8=v1,
        utf-8-text=v1, text=v1, hex-digit=v1,
    },
}

Group `decode` tests `decode-utf-8`. Each line conforms to `vector-line`.

| field | type | meaning |
|---|---|---|
| `input` | string | `byte-sequence` encoded as two `hex-digit` characters per byte, high nibble first (`""` for empty) |
| `result` | string | `"valid"` when `input` is `valid-utf-8`, `"invalid"` otherwise |
| `values.text` | string (optional) | `utf-8-text` of `input` when `result` is `"valid"`; absent (`values` is `{}`) when `result` is `"invalid"` |

@example Sample lines testing [decode-utf-8](sinter:#decode-utf-8=v1) on
[valid-utf-8](sinter:#valid-utf-8=v1) and invalid
[byte-sequence](sinter:#byte-sequence=v1) inputs:

```json
{"form":"#decode-vector=v1","group":"decode","input":"6869","result":"valid","values":{"text":"hi"}}
{"form":"#decode-vector=v1","group":"decode","input":"ff","note":"the UTF-8 encoding of no character holds the byte 0xFF","result":"invalid","values":{}}
```

### UTF-8 encoding vectors

@schema encode-vector=v1
@cites {
    #{
        vector-line=v1, encode-utf-8=v1, text=v1, byte-sequence=v1,
        utf-8-encoding=v1, hex-digit=v1,
    },
}

Group `encode` tests `encode-utf-8`. Each line conforms to `vector-line`.

| field | type | meaning |
|---|---|---|
| `input` | string | `text` to encode |
| `values.encoding` | string | `utf-8-encoding` as two `hex-digit` characters per byte, high nibble first (`""` for empty) |

@example Sample line testing [encode-utf-8](sinter:#encode-utf-8=v1) with
[utf-8-encoding](sinter:#utf-8-encoding=v1):

```json
{"form":"#encode-vector=v1","group":"encode","input":"hi","values":{"encoding":"6869"}}
```

### Line splitting vectors

@schema line-vector=v1
@cites #{vector-line=v1, give-lines=v1, text=v1, slice=v1, line=v1}

Group `lines` tests `give-lines`. Each line conforms to `vector-line`.

| field | type | meaning |
|---|---|---|
| `input` | string | `text` to split into lines |
| `values.slices[].from` | integer (`>= 0`) | start boundary of each line `slice`, in 1-based line-number order |
| `values.slices[].to` | integer (`>= 0`) | end boundary of each line `slice`, in 1-based line-number order |
| `values.texts[]` | string | text of each `line`, in 1-based line-number order (both arrays are `[]` when the text has no lines) |

@example Sample line testing [give-lines](sinter:#give-lines=v1) with
[line](sinter:#line=v1) and [slice](sinter:#slice=v1):

```json
{"form":"#line-vector=v1","group":"lines","input":"a\nb","values":{"slices":[{"from":0,"to":1},{"from":2,"to":3}],"texts":["a","b"]}}
```

### Character position vectors

@schema character-position-vector=v1
@cites {
    #{
        vector-line=v1, give-character-positions=v1, text=v1, body=v1,
        position=v1,
    },
}

Group `character-positions` tests `give-character-positions`. Each line
conforms to `vector-line`.

| field | type | meaning |
|---|---|---|
| `input.text` | string | `text` containing the character |
| `input.index` | integer (`>= 1`) | 1-based character index of `input.text` that lies in its `body` |
| `values.position.line` | integer (`>= 1`) | 1-based line number of the character's `position` |
| `values.position.column` | integer (`>= 1`) | 1-based column of the character's `position` |

@example Sample line testing
[give-character-positions](sinter:#give-character-positions=v1) with
[position](sinter:#position=v1):

```json
{"form":"#character-position-vector=v1","group":"character-positions","input":{"index":3,"text":"a\nb"},"values":{"position":{"column":1,"line":2}}}
```

### Span position vectors

@schema span-vector=v1
@cites {
    #{
        vector-line=v1, give-span-positions=v1, text=v1, slice=v1,
        span=v1, position=v1,
    },
}

Group `spans` tests `give-span-positions`. Each line conforms to
`vector-line`.

| field | type | meaning |
|---|---|---|
| `input.text` | string | `text` containing the span |
| `input.slice.from` | integer (`>= 0`) | start boundary of the `span` `slice`, as a boundary of `input.text` |
| `input.slice.to` | integer (`>= 0`) | end boundary of the `span` `slice`, as a boundary of `input.text` |
| `values.start.line` | integer (`>= 1`) | 1-based line number of the span's start `position` |
| `values.start.column` | integer (`>= 1`) | 1-based column of the span's start `position` |
| `values.end.line` | integer (`>= 1`) | 1-based line number of the span's end `position` |
| `values.end.column` | integer (`>= 1`) | 1-based column of the span's end `position` |

@example Sample line testing
[give-span-positions](sinter:#give-span-positions=v1) with
[span](sinter:#span=v1) and [position](sinter:#position=v1):

```json
{"form":"#span-vector=v1","group":"spans","input":{"slice":{"from":1,"to":2},"text":"abc"},"values":{"end":{"column":3,"line":1},"start":{"column":2,"line":1}}}
```
