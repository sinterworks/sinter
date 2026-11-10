<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Text and notation
@design text=v1
@cites rfc/3629
@cites rfc/5234
@cites rfc/7405
Specifies, as used in Sinter, whole numbers, numerals, and hex digits; characters, code point order, texts, places, boundaries, and runs; bytes and UTF-8; byte order marks, bodies, line endings, lines, positions, and spans; the notation of productions; conforming programs, inputs, and results; and requirements for conforming programs that test and decode UTF-8, give UTF-8 encodings, and give lines, line numbers, and the positions of characters and of the starts and ends of spans.

A text is a finite sequence of characters, such as `docs/a.md`. A byte
sequence, such as 0x68, 0x69, is the UTF-8 encoding of a text when it is
valid UTF-8. A byte order mark is a U+FEFF that is the first character
of a text. The body of a text is the part of the text without its byte
order mark. The line endings of the body divide it into lines. The
character at each place of the body has a position, such as line 3,
column 7. A span, such as a word of the text, has a start and an end,
which are positions.

The productions in section 3 are written in ABNF, the notation of
RFC 5234, with the case-sensitive strings of RFC 7405. A production,
such as `hex-digit = DIGIT / %x61-66`, gives the texts that its name
matches. In a production, `/` separates two alternatives, and `( )`
groups elements. The quoted string `"0"` is the character `0`. `*`
repeats the element after it any number of times, zero included. `1*`
repeats the element after it one or more times, and `4*6` repeats the
element after it four, five, or six times. `%x61` is the character
U+0061, and `%x31-39` is any one character from U+0031 to U+0039.
`DIGIT` is a core rule of RFC 5234: any one of the characters `0` to
`9`. In RFC 5234, a quoted string such as `"a"` matches its letters in
either case. RFC 7405 adds the string `%s"…"`, which matches its letters
only in the same case.

From RFC 3629, the design takes UTF-8: how a byte sequence encodes a
text, the rule `UTF8-char`, which gives the bytes that encode one
character, and the rule `UTF8-octets`, which gives the byte sequences
that are valid UTF-8.

## 1. Terms

| term | meaning |
|---|---|
| design | a document that holds requirements |
| requirement | a definition, or an obligation of a conforming program, that a design holds under a name |
| cite | a requirement cites another requirement when it names that requirement as one whose definitions it uses |
| conforming program | a program, or a part of a program, that meets every requirement of a design |
| must | states an obligation of a conforming program |
| input | a thing that a conforming program takes, such as a byte sequence or a text |
| decode | a conforming program decodes a byte sequence as UTF-8 when it tests whether the byte sequence is valid UTF-8 and, when the byte sequence is valid UTF-8, gives the text of the byte sequence |
| result | a text that a requirement names, between double quotes, as what a conforming program gives for an input, such as "valid" |
| whole number | a number with no fractional part, such as −7, 0, or 42 |
| decimal numeral | a text of the characters `0` to `9` that writes a whole number of 0 or more in base 10, and whose first character is not `0` unless the text is `0`, such as `42` |
| 0x numeral | a text that matches the production `x-numeral`: `0x`, then one or more of `0` to `9` and `A` to `F`; it writes a whole number in base 16, such as 0x0A for 10 |
| U+ numeral | a text that matches the production `u-numeral`: `U+`, then four to six of `0` to `9` and `A` to `F`; it writes a whole number in base 16, such as U+0041 for 65, and, when that number is the code point of a character, names that character |
| hex digit | one of the characters `0` to `9` and `a` to `f`, which write the whole numbers 0 to 15 |
| code point | a whole number from 0 to 1,114,111, written as U+0000 to U+10FFFF |
| character | a unit of text that has one code point, a Unicode scalar value: from U+0000 to U+D7FF, or from U+E000 to U+10FFFF |
| code point order | the order of characters by their code points |
| space, tab, line feed, carriage return | the characters U+0020, U+0009, U+000A, and U+000D |
| text | a finite sequence of characters |
| empty text | the text of no characters |
| place | the whole number, counted from 1, at which a character is in a text, or a byte is in a byte sequence |
| boundary | a whole number from 0 to the number of characters of a text: boundary 0 is before place 1, and each other boundary is right after the place with the same number |
| run | a part of a text that starts at a boundary, ends at the same boundary or a later boundary, and holds the characters between these two boundaries, each at its place, such as the run of `abcde` that starts at boundary 2, ends at boundary 4, and holds `cd`; a run can be empty |
| Unicode normalization | a change of a text into a standard form of Unicode, such as the change of `e` and U+0301 into U+00E9 |
| byte | a whole number from 0 to 255 |
| byte sequence | a finite sequence of bytes |
| UTF-8 encoding | the byte sequence that encodes a text in UTF-8 |
| valid UTF-8 | a byte sequence is valid UTF-8 when it is the UTF-8 encoding of a text |
| text of a byte sequence | the text whose UTF-8 encoding a byte sequence is |
| overlong encoding | a byte sequence that would encode a character in more bytes than the UTF-8 encoding of that character has |
| byte order mark | the character U+FEFF at place 1 of a text |
| body | the run of a text that starts at boundary 1 when the text has a byte order mark, and at boundary 0 when it has none, and that ends at the last boundary of the text |
| boundary of the body | a boundary of a text from the boundary where the body starts to the boundary where the body ends |
| line ending | the run of a body that holds a line feed and, when the body holds a carriage return right before that line feed, that carriage return |
| line | one of the runs into which the line endings divide a body, except an empty run that ends at the boundary where the body ends |
| line number | the first of the two whole numbers of a position: 1 for the first line of a text, and 1 more for each later line |
| column | the second of the two whole numbers of a position |
| position | a line number and a column, such as line 3, column 7 |
| span | a run of a text that starts and ends at boundaries of the body; its start and its end are positions |
| ABNF | the notation for grammars of RFC 5234, with the case-sensitive strings of RFC 7405 |
| production | a rule of ABNF that a requirement holds, such as `hex-digit = DIGIT / %x61-66`, which gives the texts that its name matches |
| terminal value | a number into which a rule of ABNF resolves, such as 0x61 for `%x61` |

## 2. Numbers, texts, bytes, lines, and notation

### 2.1 Whole numbers, numerals, and hex digits

A whole number is a number with no fractional part: 0, 1, 2, and so on,
or −1, −2, and so on. A decimal numeral writes a whole number of 0 or
more in base 10, with the characters `0` to `9`, such as `42` for 42.
The first character of a decimal numeral is not `0` unless the numeral
is `0`: `0` is the decimal numeral of 0, and `042` is not a decimal
numeral.

Two kinds of numeral write whole numbers in base 16, with `0` to `9` for
0 to 9 and the upper-case letters `A` to `F` for 10 to 15. A 0x numeral
is `0x`, then one or more of these, such as 0x0A for 10 and 0xFF for
255. A U+ numeral is `U+`, then four, five, or six of these, such as
U+0041 for 65 and U+10FFFF for 1,114,111.

A hex digit is one of the sixteen characters `0` to `9` and `a` to `f`.
The hex digits `0` to `9` write the whole numbers 0 to 9, and the hex
digits `a` to `f` write 10 to 15. The hex digit of a whole number from 0
to 15 is the hex digit that writes it, so the hex digit of 12 is `c`. An
upper-case letter is not a hex digit: `3f2a` is a text of four hex
digits, and `3F2A` is not. So the letters `A` to `F` of a 0x numeral or
a U+ numeral are not hex digits.

### 2.2 Characters and texts

A code point is a whole number from 0 to 1,114,111. Each character has
one code point, which is a Unicode scalar value: a code point from
U+0000 to U+D7FF, or from U+E000 to U+10FFFF. Each Unicode scalar value
is the code point of exactly one character. So U+D800 is a code point,
and no character has it. A U+ numeral that writes the code point of a
character also names that character: U+0041 names the character `A`.

In a requirement, characters between two backticks, such as `%x61`, are
those characters, and the backticks are not part of them.

These four characters have names:

| name | character |
|---|---|
| space | U+0020 |
| tab | U+0009 |
| line feed | U+000A |
| carriage return | U+000D |

One character comes before another in code point order when the code
point of the one is less than the code point of the other. So `A`,
U+0041, comes before `a`, U+0061.

A text is a finite sequence of characters. The empty text is the text
of no characters. The places of a text number its characters from 1, in
order: in the text `abc`, `a` is at place 1, and `c` is at place 3.

The examples write a text as its parts, in order, with commas between
them. A part is characters between backticks, such as `ab`; one of the
four named characters, such as a line feed; a U+ numeral, which names
one character; or a part, then "written", a decimal numeral, and
"times", which is that part as many times in a row as the numeral
writes. So "`a`, a line feed, `b`" is the text of the three characters
`a`, U+000A, and `b`. The examples write the text of no characters as
"the empty text".

Two texts are the same text when they have the same number of
characters and the same character at each place. Case matters, so `a`
and `A` are two different texts. Unicode normalization changes a text
into a standard form of Unicode, such as the change of `e`, U+0301 into
U+00E9. Two texts that differ only by Unicode normalization are two
different texts: the text U+00E9 and the text `e`, U+0301 both show as
é, and they are not the same text.

A boundary of a text is a whole number from 0 to the number of
characters of the text. Boundary 0 is before place 1, and each other
boundary is right after the place with the same number. So the text
`abc` has the four boundaries 0, 1, 2, and 3. A run of a text starts at
a boundary, and it ends at the same boundary or at a later boundary. It
holds the characters at the places between the boundary where it starts
and the boundary where it ends, in order, and each character keeps its
place. So the run of `abcde` that starts at boundary 2 and ends at
boundary 4 holds `cd`, at places 3 and 4. A run that starts and ends at
the same boundary is empty. The text of a run is its characters in
order.

Two runs are the same run only when they start at the same boundary and
end at the same boundary. So the text `aba` has two different runs that
each hold one `a`: the run that starts at boundary 0 and ends at
boundary 1, and the run that starts at boundary 2 and ends at boundary
3. The text of each of these two runs is `a`. In the same way, the empty
run that starts and ends at boundary 1 and the empty run that starts and
ends at boundary 2 are two different runs.

### 2.3 Bytes and UTF-8

A byte is a whole number from 0 to 255, such as 0x41. A byte sequence
is a finite sequence of bytes. The empty byte sequence is the byte
sequence of no bytes. The places of a byte sequence number its bytes
from 1, in order. Two byte sequences are the same byte sequence when
they have the same number of bytes and the same byte at each place. A
byte is not a character, and a byte sequence is not a text: the byte
0x41 is 65, and the code point of the character `A` is 65 too, but the
byte is not the character.

The examples write a byte sequence as its bytes, in order, with commas
between them, and each byte as a 0x numeral, such as 0x68, 0x69. They
write the byte sequence of no bytes as "the empty byte sequence".

UTF-8, as RFC 3629 defines it, encodes each character in one to four
bytes. The UTF-8 encoding of a text holds the bytes that encode each of
its characters, in order, and no other bytes:

| text | UTF-8 encoding |
|---|---|
| `A` | 0x41 |
| U+00E9 | 0xC3, 0xA9 |
| `e`, U+0301 | 0x65, 0xCC, 0x81 |
| U+FEFF | 0xEF, 0xBB, 0xBF |
| U+1F600 | 0xF0, 0x9F, 0x98, 0x80 |
| the empty text | the empty byte sequence |

In RFC 3629, the rule `UTF8-char` matches the bytes that encode one
character, and the rule `UTF8-octets` matches any number of `UTF8-char`
in a row. A byte sequence is valid UTF-8 when `UTF8-octets` matches the
whole byte sequence. Then the byte sequence is the UTF-8 encoding of one
text, the text of the byte sequence. That text holds the character that
each `UTF8-char` encodes, in order, and no other character. So the text
keeps a U+FEFF at place 1, keeps each carriage return, and keeps each
character as the bytes encode it, with no Unicode normalization.

An overlong encoding is a byte sequence that would encode a character in
more bytes than the UTF-8 encoding of that character has. So 0xC0, 0xAF
is an overlong encoding: it would encode `/` in two bytes, and the UTF-8
encoding of `/` is 0x2F. These byte sequences are not valid UTF-8:

| byte sequence | why |
|---|---|
| 0xFF | the UTF-8 encoding of no character holds the byte 0xFF |
| 0xC0, 0xAF | an overlong encoding |
| 0xED, 0xA0, 0x80 | the bytes that would encode U+D800, which is not a character |
| 0xC3 | the first byte of the UTF-8 encoding of a character, with no byte after it |

### 2.4 Lines and positions

The examples write the lines of a text as the texts of the lines, in
order, with semicolons between them, or as "no line" when the text has
no line. When the character at a place has no position, they write
"none". They write a span as the boundary where it starts, "to", and the
boundary where it ends, such as "1 to 4".

A text has a byte order mark when the character at place 1 of the text
is U+FEFF. The byte order mark is that character, at place 1. A U+FEFF
at any other place is a character like any other. The body of a text
that has a byte order mark is the run that starts at boundary 1 and ends
at the last boundary of the text. The body of every other text is the
run that starts at boundary 0 and ends at the last boundary of the text.
So the places of the body are all the places of the text, except place 1
of a text that has a byte order mark. A boundary of the body is a
boundary from the boundary where the body starts to the boundary where
the body ends.

A line ending is a run of the body that ends at the boundary right after
a line feed. It starts at the boundary right before that line feed, or,
when the body holds a carriage return right before that line feed, at
the boundary right before that carriage return. So in the text `ab`, a
carriage return, a line feed, `c`, the line ending starts at boundary 2
and ends at boundary 4. A line starts at the boundary where the body
starts, or at the boundary where a line ending ends. It ends at the
first boundary, at or after the boundary where it starts, where a line
ending starts. When no line ending starts at or after the boundary where
it starts, the line ends at the boundary where the body ends. A run that
ends at the boundary where the body ends is a line only when it is not
empty. So the line endings divide the body into runs, and the lines are
these runs, except the last run when it is empty. The first line has the
line number 1, and the line number of each other line is 1 more than the
line number of the line before it.

A line never holds a line feed. A body whose last character is a line
feed has no empty line after that line feed. The empty body has no line.
The text of two line feeds has two lines, and both are empty: the run
that starts and ends at boundary 0, and the run that starts and ends at
boundary 1. A carriage return that is not right before a line feed is at
a place of a line, not of a line ending. No character other than a line
feed and a carriage return is at a place of a line ending: U+000B,
U+000C, U+0085, U+2028, and U+2029 are at places of lines.

| text | lines |
|---|---|
| `a`, a line feed, `b` | `a`; `b` |
| `a`, a line feed | `a` |
| a line feed | the empty text |
| the empty text | no line |
| `ab`, a carriage return, a line feed, `c` | `ab`; `c` |
| `a`, a carriage return | `a`, a carriage return |
| U+FEFF, `x` | `x` |
| `a`, U+2028, `b` | `a`, U+2028, `b` |

A position is a line number and a column, both counted from 1. The
character at each place of the body has a position. In a text that has a
byte order mark, place 1 is on no line, so the character at place 1 has
no position. The column of the character at a place of a line is 1 more
than the number of the places of the line before that place. A line
ending is not part of a line, so its places add nothing to the columns
of the line before it. The character at each place of a line ending has
the line number of the line that ends at the boundary where that line
ending starts. The column of that character is 1 more than the number of
the places of that line. A column counts characters, not bytes: U+00E9
is one character, which UTF-8 encodes in two bytes. A tab is one
character, so it counts as one column.

| text | place | position |
|---|---|---|
| `ab`, a line feed, `c` | 4 | line 2, column 1 |
| `ab`, a carriage return, a line feed, `c` | 3 | line 1, column 3 |
| `ab`, a carriage return, a line feed, `c` | 4 | line 1, column 3 |
| U+00E9, `x` | 2 | line 1, column 2 |
| `e`, U+0301, `x` | 3 | line 1, column 3 |
| U+FEFF, `x` | 2 | line 1, column 1 |
| U+FEFF, `x` | 1 | none |

A boundary of the body also has a position. A boundary from the boundary
where a line starts to the boundary where that line ends has the line
number of that line. Its column is 1 more than the number of the places
of the line before the boundary. So the position of the character at a
place is the position of the boundary right before that place. The
boundary between the carriage return and the line feed of a line ending
has the position of the place of that carriage return. When the body is
empty, or its last character is a line feed, the boundary where the body
ends is on no line. Its line number is 1 more than the number of the
lines of the text, which is the line number of no line, and its column
is 1: in the text `a`, a line feed, the boundary where the body ends has
the position line 2, column 1.

A span of a text is a run that starts at a boundary of the body and ends
at a boundary of the body, such as a word, or an empty run at a
boundary. A run that starts at boundary 0 of a text that has a byte
order mark is not a span. The start of a span is the position of the
boundary where the span starts. When one or more places of the span are
places of a line, the end of the span is the position of the boundary
right after the last of those places. So when a span ends at the
boundary where a line ending ends, that line ending does not move the
end of the span. When no place of the span is a place of a line, the end
of the span is the start of the span. An empty span is such a span: in
the text `a =`, the empty span at boundary 3, after the last character,
has the start line 1, column 4, and the end line 1, column 4.

| text | span | start | end |
|---|---|---|---|
| `abc` | 1 to 2 | line 1, column 2 | line 1, column 3 |
| `ab`, a carriage return, a line feed, `cd` | 1 to 5 | line 1, column 2 | line 2, column 2 |
| `ab`, a carriage return, a line feed, `cd` | 0 to 4 | line 1, column 1 | line 1, column 3 |
| `a =` | 3 to 3 | line 1, column 4 | line 1, column 4 |
| `a`, a line feed | 2 to 2 | line 2, column 1 | line 2, column 1 |
| the empty text | 0 to 0 | line 1, column 1 | line 1, column 1 |

### 2.5 Productions

A production is a rule of ABNF, the notation of RFC 5234, with the
case-sensitive strings of RFC 7405. RFC 5234 calls the numbers into
which a rule resolves its terminal values: `%x61` is the terminal value
0x61. A terminal value in a production matches the character whose code
point it is, so `%x61` matches the character `a`, U+0061. A terminal
value that is not the code point of a character, such as 0xD800,
matches no character.

A production can use the core rules of RFC 5234, such as `DIGIT` and
`HEXDIG`. A quoted string matches its letters in either case, and the
core rule `HEXDIG` uses quoted strings for its letters. So `HEXDIG`
matches both `a` and `A`. The production `hex-digit` of section 3.11
uses `%x61-66` for its letters, so it matches `a` and does not match
`A`.

A requirement cites another requirement when it names that requirement
as one whose definitions it uses. A rule name in a rule of ABNF that a
requirement holds names a core rule, a rule of that requirement, or a
rule of a requirement that it cites, without regard to case. So `digit`
names the core rule `DIGIT`. A rule of ABNF is a production only when
each of its rule names names exactly one rule. A production holds no
prose value, which RFC 5234 writes between `<` and `>`.

A text matches a production only as a whole. The text `42` matches the
production `decimal-numeral` of section 3.9, and the text `42a` does
not, although the first two characters of `42a` are `42`. A character
matches a production when the text of that one character matches it,
so the character `a` matches `hex-digit`.

### 2.6 Conforming programs, inputs, and results

A design is a document that holds requirements. A requirement is a
definition, or an obligation of a conforming program, that a design
holds under a name, such as `whole-numbers`. A conforming program of a
design is a program, or a part of a program, that meets every
requirement of the design. So one program can hold conforming programs
of several designs. In a design, a conforming program is a conforming
program of that design, and each obligation that a requirement of that
design states with the word must is an obligation of each conforming
program of that design.

An input is a thing that a conforming program takes, such as a byte
sequence or a text. A conforming program decodes a byte sequence as
UTF-8 when it tests whether the byte sequence is valid UTF-8 and, when
the byte sequence is valid UTF-8, gives the text of the byte sequence. A
result is a text that a requirement names, between double quotes, as
what a conforming program gives for an input, such as "valid". The
double quotes are not part of the result.

These are the inputs that a conforming program can take, and what it
gives for each:

| input | what a conforming program gives |
|---|---|
| a byte sequence that it decodes as UTF-8 | the result "valid", with the text of the byte sequence, or the result "invalid", with no text |
| a text for which it gives the UTF-8 encoding | the UTF-8 encoding of the text |
| a text for which it gives the lines | each line of the text exactly once, in the order of the lines, and no other run or text |
| a line of a text, for which it gives a line number | the line number of that line |
| the character at a place of the body of a text, for which it gives a line number or a column | the line number of the position of that character, the column of that position, or both |
| a span of a text, for whose start or end it gives a line number or a column | the line number of that start or that end, its column, or both |

A conforming program gives no line number and no column for the
character at place 1 of a text that has a byte order mark: that
character has no position. It also gives no line number and no column as
the start or the end of a run that is not a span, such as a run that
starts at boundary 0 of a text that has a byte order mark.

## 3. Requirements

### 3.1 Whole numbers

@req whole-numbers=v1

A whole number is a number with no fractional part: 0, 1, 2, and so on,
or −1, −2, and so on.

### 3.2 Characters

@req characters=v1
@cites #{whole-numbers=v1}

A code point is a whole number from 0 to 1,114,111. Each character has
one code point, which is a Unicode scalar value: a whole number from 0
to 55,295 or from 57,344 to 1,114,111. Each Unicode scalar value is the
code point of exactly one character. A space is the character whose
code point is 32, a tab is the character whose code point is 9, a line
feed is the character whose code point is 10, and a carriage return is
the character whose code point is 13.

### 3.3 Backticks

@req backticks=v1
@cites #{characters=v1, conforming-programs=v1}

In a requirement, characters between two backticks are those
characters, and the backticks are not part of them.

### 3.4 Code point order

@req code-point-order=v1
@cites #{characters=v1}

One character comes before another in code point order, and the other
comes after it, when, and only when, the code point of the one is less
than the code point of the other.

### 3.5 Texts

@req texts=v1
@cites #{characters=v1, whole-numbers=v1}

A text is a finite sequence of characters. The empty text is the text
of no characters. The places of a text are numbered from 1, one place
for each character of the text, in the order of the text: the character
at place 1 is the first character of the text. Two texts are the same
text when, and only when, they have the same number of characters and
the same character at each place.

### 3.6 Runs

@req runs=v1
@cites #{texts=v1, characters=v1, whole-numbers=v1}

A boundary of a text is a whole number from 0 to the number of
characters of the text. Boundary 0 is before place 1, and each other
boundary k is right after place k. A run of a text has two boundaries
of the text: s, where it starts, and e, which is s or greater, where it
ends. For each boundary s of a text and each boundary e of the text
that is s or greater, the text has a run that starts at s and ends at
e. The run holds the characters at the places from s + 1 to e, in
order, each at its place, and these places are the places of the run.
The run is empty when s = e, and then it holds no character. Two runs
of a text are the same run when, and only when, they start at the same
boundary and end at the same boundary. The text of a run is the text of
the characters of the run, in their order.

### 3.7 Notation

@req notation=v1
@cites {
    rfc/5234, rfc/7405,
    #{
        characters=v1, texts=v1, backticks=v1, rule-names=v1,
        conforming-programs=v1,
    },
}

A production is a rule of ABNF, the notation of RFC 5234, with the
case-sensitive strings of RFC 7405, that meets these conditions:

- A requirement holds it.
- It holds no prose value, which RFC 5234 writes between `<` and `>`.
- Each of its rule names names exactly one rule.

A terminal value in a production, or in a core rule that a production
uses, matches the character whose code point it is, so `%x41` matches
the character whose code point is 65. A terminal value that is not the
code point of a character matches no character. A text matches a
production when, and only when, the production matches the whole of the
text. A character matches a production when, and only when, the text of
that one character matches the production.

### 3.8 Rule names

@req rule-names=v1
@cites {rfc/5234, #{conforming-programs=v1}}

A rule name in a rule of ABNF that a requirement R holds names each rule
that has that rule name, without regard to case, and that is one of
these: a core rule of RFC 5234, Appendix B.1; a rule of ABNF that R
holds; or, for each requirement Q that R cites, a rule of ABNF that Q
holds.

### 3.9 Decimal numerals

@req decimal-numerals=v1
@cites #{
    notation=v1, rule-names=v1, backticks=v1, whole-numbers=v1, texts=v1,
    characters=v1,
}

A decimal numeral is a text that matches the production
`decimal-numeral`:

```
decimal-numeral  = "0" / ( %x31-39 *DIGIT )
```

The whole number that a decimal numeral writes is the whole number that
its characters write in base 10, with `0` for 0, `1` for 1, `2` for 2,
`3` for 3, `4` for 4, `5` for 5, `6` for 6, `7` for 7, `8` for 8, and
`9` for 9. The decimal numeral of a whole number of 0 or more is the
decimal numeral that writes that whole number.

### 3.10 Numerals in base 16

@req base-16-numerals=v1
@cites #{
    notation=v1, rule-names=v1, backticks=v1, whole-numbers=v1, texts=v1,
    characters=v1,
}

A 0x numeral is a text that matches the production `x-numeral`. A U+
numeral is a text that matches the production `u-numeral`:

```
x-numeral  = %s"0x" 1*( DIGIT / %x41-46 )
u-numeral  = %s"U+" 4*6( DIGIT / %x41-46 )
```

A 0x numeral or a U+ numeral writes the whole number that its
characters after `0x` or `U+` write in base 16, with `0` for 0, `1` for
1, `2` for 2, `3` for 3, `4` for 4, `5` for 5, `6` for 6, `7` for 7, `8`
for 8, `9` for 9, `A` for 10, `B` for 11, `C` for 12, `D` for 13, `E`
for 14, and `F` for 15, such as 0x0A for 10 and U+0041 for 65. A U+
numeral that writes the code point of a character also names that
character.

### 3.11 Hex digits

@req hex-digits=v1
@cites #{
    notation=v1, rule-names=v1, backticks=v1, whole-numbers=v1,
    characters=v1,
}

A hex digit is a character that matches the production `hex-digit`:

```
hex-digit  = DIGIT / %x61-66
```

A hex digit writes a whole number, with `0` for 0, `1` for 1, `2` for 2,
`3` for 3, `4` for 4, `5` for 5, `6` for 6, `7` for 7, `8` for 8, `9`
for 9, `a` for 10, `b` for 11, `c` for 12, `d` for 13, `e` for 14, and
`f` for 15. The hex digit of a whole number from 0 to 15 is the hex
digit that writes it.

### 3.12 Bytes

@req bytes=v1
@cites #{whole-numbers=v1, characters=v1, texts=v1}

A byte is a whole number from 0 to 255. A byte sequence is a finite
sequence of bytes. The empty byte sequence is the byte sequence of no
bytes. The places of a byte sequence are numbered from 1, one place for
each byte of the byte sequence, in its order. Two byte sequences are
the same byte sequence when, and only when, they have the same number
of bytes and the same byte at each place. A byte is not a character,
and a byte sequence is not a text.

### 3.13 UTF-8

@req utf-8=v1
@cites {
    rfc/3629,
    #{
        characters=v1, texts=v1, bytes=v1, base-16-numerals=v1, notation=v1,
        backticks=v1,
    },
}

A byte sequence is valid UTF-8 when, and only when, the rule
`UTF8-octets` of RFC 3629 matches the whole byte sequence, with each
terminal value of that rule as one byte. The text of a byte sequence
that is valid UTF-8 is the text that holds, for each `UTF8-char` that
the rule `UTF8-octets` matches in the byte sequence, in their order, the
character that the bytes of that `UTF8-char` encode, as RFC 3629 defines
UTF-8, and no other character. The text holds a U+FEFF that the first
`UTF8-char` encodes, as it holds each other character. The UTF-8
encoding of a text is the byte sequence that holds, for each character
of the text in its order, the bytes that encode that character, as
RFC 3629 defines UTF-8, and no other bytes.

### 3.14 Byte order marks

@req byte-order-marks=v1
@cites #{characters=v1, texts=v1, base-16-numerals=v1}

A text has a byte order mark when, and only when, the character at place
1 of the text is U+FEFF. The byte order mark of such a text is the
character U+FEFF at place 1.

### 3.15 Bodies

@req bodies=v1
@cites #{texts=v1, runs=v1, byte-order-marks=v1}

The body of a text that has a byte order mark is the run of the text
that starts at boundary 1 and ends at the last boundary of the text.
The body of every other text is the run of the text that starts at
boundary 0 and ends at the last boundary of the text. A boundary of the
body is a boundary of the text from the boundary where the body starts
to the boundary where the body ends.

### 3.16 Lines

@req lines=v1
@cites #{characters=v1, texts=v1, runs=v1, bodies=v1, whole-numbers=v1}

A line ending of a text is a run of the text that meets each of these
conditions, where p is the boundary where the run ends:

- p is a place of the body, and the character at place p is a line feed.
- When p − 1 is a place of the body and the character at place p − 1 is
  a carriage return, the run starts at boundary p − 2. Otherwise, the
  run starts at boundary p − 1.

A line of a text is a run of the text that meets each of these
conditions:

- It starts at the boundary where the body starts, or at the boundary
  where a line ending ends.
- It ends at the first boundary, at or after the boundary where it
  starts, where a line ending starts. When no line ending starts at or
  after the boundary where it starts, it ends at the boundary where the
  body ends.
- It is not empty when it ends at the boundary where the body ends.

The line that starts at the boundary where the body starts has the line
number 1. Each other line starts at the boundary where a line ending
ends, and its line number is 1 more than the line number of the line
that ends at the boundary where that line ending starts. The lines of a
text are in the order of their line numbers. A place of a line is a
place of the run that is that line, and a place of a line ending is a
place of the run that is that line ending.

### 3.17 Positions

@req positions=v1
@cites #{
    lines=v1, bodies=v1, texts=v1, runs=v1, characters=v1,
    byte-order-marks=v1, whole-numbers=v1,
}

A position is a pair of whole numbers: a line number and a column. The
position of a boundary b of the body of a text is this:

- When a line starts at b or before b, and ends at b or after b: the
  line number of that line, and, as the column, 1 more than b − s,
  where s is the boundary where that line starts.
- Otherwise, when a line ending starts before b and ends after b: the
  line number of the line that ends at the boundary where that line
  ending starts, and, as the column, 1 more than e − s, where s and e
  are the boundaries where that line starts and ends.
- Otherwise: 1 more than the number of the lines of the text, as the
  line number, and 1, as the column.

The position of a place p of the body of a text is the position of the
boundary p − 1, and the character at place p has that position. The
character at place 1 of a text that has a byte order mark has no
position.

### 3.18 Spans

@req spans=v1
@cites #{texts=v1, runs=v1, bodies=v1, lines=v1, positions=v1}

A span of a text is a run of the text that starts at a boundary of the
body and ends at a boundary of the body. The start of a span is the
position of the boundary where the span starts. When one or more places
of the span are places of a line, the end of the span is the position of
boundary k, where k is the last of those places. Otherwise, the end of
the span is the start of the span.

### 3.19 Conforming programs

@req conforming-programs=v1

A design is a document that holds requirements. A requirement is a
definition, or an obligation of a conforming program, that a design
holds under a name. A requirement cites another requirement when it
names that requirement as one whose definitions it uses. A conforming
program of a design is a program, or a part of a program, that meets
every requirement of the design. In a design, a conforming program is a
conforming program of that design, and each obligation that a
requirement of that design states with the word must is an obligation of
each conforming program of that design.

### 3.20 Inputs

@req inputs=v1
@cites #{conforming-programs=v1, bytes=v1, texts=v1}

An input is a thing that a conforming program takes, such as a byte
sequence or a text.

### 3.21 Results

@req results=v1
@cites #{conforming-programs=v1, inputs=v1, texts=v1}

A result is a text that a requirement names, between double quotes, as
what a conforming program gives for an input. The double quotes are not
part of the result.

### 3.22 Byte sequences that a program decodes

@req test-utf-8=v1
@cites #{conforming-programs=v1, results=v1, bytes=v1, utf-8=v1}

When a conforming program gives a result for a byte sequence as a test
of whether the byte sequence is valid UTF-8, it must give exactly one
result: "valid" when the byte sequence is valid UTF-8, and "invalid"
when the byte sequence is not valid UTF-8.

### 3.23 The text of a byte sequence that a program decodes

@req give-decoded-texts=v1
@cites #{conforming-programs=v1, results=v1, bytes=v1, texts=v1, utf-8=v1}

When a conforming program gives the result "valid" for a byte sequence
as a test of whether the byte sequence is valid UTF-8, it must give with
that result the text of the byte sequence, and no other text.

### 3.24 No text with the result "invalid"

@req omit-texts-of-invalid-byte-sequences=v1
@cites #{conforming-programs=v1, results=v1, bytes=v1, texts=v1, utf-8=v1}

When a conforming program gives the result "invalid" for a byte sequence
as a test of whether the byte sequence is valid UTF-8, it must give no
text with that result.

### 3.25 The UTF-8 encodings that a program gives

@req give-utf-8-encodings=v1
@cites #{conforming-programs=v1, bytes=v1, texts=v1, utf-8=v1}

When a conforming program gives a byte sequence as the UTF-8 encoding of
a text, it must give the UTF-8 encoding of that text, and no other byte
sequence, as the UTF-8 encoding of that text.

### 3.26 The lines that a program gives

@req give-lines=v1
@cites #{conforming-programs=v1, texts=v1, runs=v1, lines=v1}

When a conforming program gives the lines of a text, it must give, for
each line of the text in the order of the lines, exactly one run or
text: that line, or the text of that line. It must give no other run or
text as a line of that text.

### 3.27 The line numbers of lines

@req give-line-numbers=v1
@cites #{conforming-programs=v1, texts=v1, lines=v1}

When a conforming program gives a line number for a line of a text, it
must give the line number of that line, and no other line number, for
that line.

### 3.28 The line numbers and columns of characters

@req give-character-positions=v1
@cites #{
    conforming-programs=v1, texts=v1, characters=v1, runs=v1, bodies=v1,
    lines=v1, positions=v1,
}

When a conforming program gives a line number for the character at a
place of the body of a text, it must give the line number of the
position of the character at that place, and no other line number, for
the character at that place. When it gives a column for the character at
a place of the body of a text, it must give the column of the position
of the character at that place, and no other column, for the character
at that place.

### 3.29 No position for a byte order mark

@req omit-byte-order-mark-positions=v1
@cites #{
    conforming-programs=v1, texts=v1, characters=v1, byte-order-marks=v1,
    lines=v1, positions=v1,
}

A conforming program must give no line number and no column for the
character at place 1 of a text that has a byte order mark.

### 3.30 The starts of spans

@req give-span-starts=v1
@cites #{conforming-programs=v1, texts=v1, spans=v1, positions=v1, lines=v1}

When a conforming program gives a line number for the start of a span of
a text, it must give the line number of the start of that span, and no
other line number, for the start of that span. When it gives a column
for the start of a span of a text, it must give the column of the start
of that span, and no other column, for the start of that span.

### 3.31 The ends of spans

@req give-span-ends=v1
@cites #{conforming-programs=v1, texts=v1, spans=v1, positions=v1, lines=v1}

When a conforming program gives a line number for the end of a span of a
text, it must give the line number of the end of that span, and no other
line number, for the end of that span. When it gives a column for the
end of a span of a text, it must give the column of the end of that
span, and no other column, for the end of that span.

### 3.32 No start and no end for a run that is not a span

@req omit-non-span-positions=v1
@cites #{
    conforming-programs=v1, texts=v1, runs=v1, spans=v1, lines=v1,
    positions=v1,
}

A conforming program must give no line number and no column as the start
or the end of a run of a text that is not a span of that text.

## 4. Conformance

A program, or a part of a program, conforms to this design when it
meets every requirement of the section Requirements.

Each vector below gives an input and what a conforming program gives
for it. The cells follow these conventions:

- A cell writes a text as its parts, in order, with commas between
  them. A part is characters between backticks; a space, a tab, a line
  feed, or a carriage return; a U+ numeral, for the character that it
  names; or a part, then "written", a decimal numeral, and "times", for
  that part as many times in a row as the numeral writes. "The empty
  text" is the text of no characters.
- A cell writes a byte sequence as its parts, in order, with commas
  between them. A part is a 0x numeral, for the byte that it writes, or
  characters between backticks, for the UTF-8 encoding of those
  characters. "The empty byte sequence" is the byte sequence of no
  bytes.
- A cell writes the lines of a text as the texts of the lines, in order,
  with semicolons between them, or as "no line" when the text has no
  line.
- A cell writes a place as its decimal numeral, and a position as
  "line", the line number, a comma, "column", and the column, as in
  "line 3, column 7".
- A cell writes a run, such as a span, as the decimal numeral of the
  boundary where it starts, "to", and the decimal numeral of the
  boundary where it ends, as in "1 to 4".
- A cell that holds "valid, with the text" and a text, or "valid, with
  the empty text", gives the result "valid" and that text, which a
  conforming program gives with that result.
- A cell that holds "invalid" gives the result "invalid" and no text.
- The text after a colon that is not between backticks explains the
  row. A conforming program does not give it.

### 4.1 Byte sequences that a program decodes

| byte sequence | what a conforming program gives |
|---|---|
| `hi` | valid, with the text `hi` |
| the empty byte sequence | valid, with the empty text |
| 0x00 | valid, with the text U+0000 |
| 0x7F | valid, with the text U+007F |
| 0xC2, 0x80 | valid, with the text U+0080 |
| 0xC3, 0xA9 | valid, with the text U+00E9 |
| 0x65, 0xCC, 0x81 | valid, with the text `e`, U+0301: the bytes encode two characters |
| 0xE0, 0xA0, 0x80 | valid, with the text U+0800 |
| 0xED, 0x9F, 0xBF | valid, with the text U+D7FF |
| 0xEE, 0x80, 0x80 | valid, with the text U+E000 |
| 0xEF, 0xBF, 0xBF | valid, with the text U+FFFF |
| 0xF0, 0x9F, 0x98, 0x80 | valid, with the text U+1F600 |
| 0xF4, 0x8F, 0xBF, 0xBF | valid, with the text U+10FFFF |
| 0xEF, 0xBB, 0xBF, `x` | valid, with the text U+FEFF, `x`: the text keeps its byte order mark |
| 0xEF, 0xBB, 0xBF, 0xEF, 0xBB, 0xBF | valid, with the text U+FEFF, U+FEFF |
| `a`, 0x0D, 0x0A, `b` | valid, with the text `a`, a carriage return, a line feed, `b` |
| 0xFF | invalid: the UTF-8 encoding of no character holds the byte 0xFF |
| 0xFF, 0xFE | invalid: the UTF-8 encoding of no character holds the byte 0xFF |
| 0x80 | invalid: the UTF-8 encoding of no character has 0x80 as its first byte |
| 0xC3 | invalid: the first byte of the UTF-8 encoding of a character, with no byte after it |
| `a`, 0xC3 | invalid: the first byte of the UTF-8 encoding of a character, with no byte after it |
| 0xC0, 0xAF | invalid: an overlong encoding |
| 0xC1, 0xBF | invalid: an overlong encoding |
| 0xE0, 0x80, 0xAF | invalid: an overlong encoding |
| 0xF0, 0x80, 0x80, 0xAF | invalid: an overlong encoding |
| 0xED, 0xA0, 0x80 | invalid: the bytes that would encode U+D800, which is not a character |
| 0xED, 0xBF, 0xBF | invalid: the bytes that would encode U+DFFF, which is not a character |
| 0xF4, 0x90, 0x80, 0x80 | invalid: the bytes that would encode the whole number 1,114,112, which is not a code point |
| 0xF8, 0x88, 0x80, 0x80, 0x80 | invalid: the UTF-8 encoding of no character has five bytes |

### 4.2 The UTF-8 encodings that a program gives

| text | UTF-8 encoding |
|---|---|
| `hi` | 0x68, 0x69 |
| the empty text | the empty byte sequence |
| U+0000 | 0x00 |
| U+007F | 0x7F |
| U+0080 | 0xC2, 0x80 |
| U+00E9 | 0xC3, 0xA9 |
| `e`, U+0301 | 0x65, 0xCC, 0x81 |
| U+07FF | 0xDF, 0xBF |
| U+0800 | 0xE0, 0xA0, 0x80 |
| U+D7FF | 0xED, 0x9F, 0xBF |
| U+E000 | 0xEE, 0x80, 0x80 |
| U+FEFF, `x` | 0xEF, 0xBB, 0xBF, 0x78 |
| U+FFFF | 0xEF, 0xBF, 0xBF |
| U+10000 | 0xF0, 0x90, 0x80, 0x80 |
| U+1F600 | 0xF0, 0x9F, 0x98, 0x80 |
| U+10FFFF | 0xF4, 0x8F, 0xBF, 0xBF |
| `a`, a carriage return, a line feed | 0x61, 0x0D, 0x0A |

### 4.3 The lines that a program gives

Each row gives a text and the lines that a conforming program gives for
that text, in the order of the lines. The line number that a conforming
program gives for each of these lines is 1 for the first line of the
cell, and 1 more for each later line.

| text | lines |
|---|---|
| `a` | `a` |
| `a`, a line feed, `b` | `a`; `b` |
| `a`, a line feed | `a` |
| `a`, a line feed, a line feed | `a`; the empty text |
| a line feed | the empty text |
| a line feed written 2 times | the empty text; the empty text |
| the empty text | no line |
| U+FEFF | no line |
| U+FEFF, a line feed | the empty text |
| U+FEFF, `x` | `x` |
| `x`, U+FEFF | `x`, U+FEFF |
| U+FEFF, U+FEFF, `x` | U+FEFF, `x` |
| `ab`, a carriage return, a line feed, `c` | `ab`; `c` |
| `ab`, a carriage return, a line feed | `ab` |
| a carriage return, a line feed | the empty text |
| `a`, a carriage return | `a`, a carriage return |
| `a`, a carriage return, `b` | `a`, a carriage return, `b` |
| `a`, a carriage return, a carriage return, a line feed | `a`, a carriage return |
| `a`, a line feed, a carriage return | `a`; a carriage return |
| a tab, `x`, a space | a tab, `x`, a space |
| `a`, U+000B, `b` | `a`, U+000B, `b` |
| `a`, U+000C, `b` | `a`, U+000C, `b` |
| `a`, U+0085, `b` | `a`, U+0085, `b` |
| `a`, U+2028, `b` | `a`, U+2028, `b` |
| `a`, U+2029, `b` | `a`, U+2029, `b` |

### 4.4 The positions that a program gives

Each row gives a text, a place of that text, and the position, or none,
that a conforming program gives for the character at that place. "None"
means that a conforming program gives no line number and no column for
that character.

| text | place | position |
|---|---|---|
| `abc` | 1 | line 1, column 1 |
| `abc` | 3 | line 1, column 3 |
| `a`, a line feed, `b` | 2 | line 1, column 2 |
| `a`, a line feed, `b` | 3 | line 2, column 1 |
| a line feed | 1 | line 1, column 1 |
| a line feed written 2 times | 2 | line 2, column 1 |
| `ab`, a carriage return, a line feed, `c` | 3 | line 1, column 3 |
| `ab`, a carriage return, a line feed, `c` | 4 | line 1, column 3 |
| `ab`, a carriage return, a line feed, `c` | 5 | line 2, column 1 |
| `aa`, a carriage return, a line feed, `b` | 4 | line 1, column 3 |
| `a`, a carriage return | 2 | line 1, column 2 |
| `a`, a carriage return, a carriage return, a line feed | 2 | line 1, column 2 |
| `a`, a carriage return, a carriage return, a line feed | 3 | line 1, column 3 |
| `a`, a carriage return, a carriage return, a line feed | 4 | line 1, column 3 |
| `a`, a carriage return, `b` | 3 | line 1, column 3 |
| U+FEFF | 1 | none: the byte order mark is at place 1 |
| U+FEFF, `x` | 1 | none: the byte order mark is at place 1 |
| U+FEFF, `x` | 2 | line 1, column 1 |
| U+FEFF, a line feed | 2 | line 1, column 1 |
| `x`, U+FEFF | 2 | line 1, column 2 |
| U+FEFF, U+FEFF, `x` | 2 | line 1, column 1 |
| U+FEFF, U+FEFF, `x` | 3 | line 1, column 2 |
| U+00E9, `x` | 2 | line 1, column 2 |
| `e`, U+0301, `x` | 3 | line 1, column 3 |
| U+1F600, `x` | 2 | line 1, column 2 |
| a tab, `x` | 2 | line 1, column 2 |
| `a`, U+2028, `b` | 3 | line 1, column 3 |
| `ab`, a line feed, `c`, a line feed, `de` | 7 | line 3, column 2 |

### 4.5 The starts and ends of spans that a program gives

Each row gives a text, a run of that text, and, when the run is a span,
the start and the end of that span that a conforming program gives.
When the run is not a span, the row gives "none" for both: a conforming
program gives no line number and no column as the start or the end of
that run.

| text | run | start | end |
|---|---|---|---|
| `abc` | 1 to 2 | line 1, column 2 | line 1, column 3 |
| `abc` | 0 to 3 | line 1, column 1 | line 1, column 4 |
| `ab`, a line feed, `cd` | 1 to 4 | line 1, column 2 | line 2, column 2 |
| `ab`, a carriage return, a line feed, `cd` | 1 to 5 | line 1, column 2 | line 2, column 2 |
| `ab`, a carriage return, a line feed, `cd` | 0 to 4 | line 1, column 1 | line 1, column 3: the line ending does not move the end |
| `ab`, a carriage return, a line feed, `cd`, a line feed | 0 to 7 | line 1, column 1 | line 2, column 3 |
| a line feed, `x` | 0 to 2 | line 1, column 1 | line 2, column 2 |
| `a`, a line feed, a line feed, `b` | 0 to 3 | line 1, column 1 | line 1, column 2 |
| U+FEFF, `ab` | 1 to 3 | line 1, column 1 | line 1, column 3 |
| U+00E9, `x` | 1 to 2 | line 1, column 2 | line 1, column 3 |
| `a =` | 3 to 3 | line 1, column 4 | line 1, column 4: an empty span after the last character |
| `a =` | 0 to 0 | line 1, column 1 | line 1, column 1 |
| `a`, a line feed | 1 to 1 | line 1, column 2 | line 1, column 2 |
| `a`, a line feed | 1 to 2 | line 1, column 2 | line 1, column 2: no place of the span is a place of a line |
| `a`, a line feed | 2 to 2 | line 2, column 1 | line 2, column 1: the boundary where the body ends, after a line ending |
| a line feed written 2 times | 1 to 1 | line 2, column 1 | line 2, column 1 |
| a line feed written 2 times | 2 to 2 | line 3, column 1 | line 3, column 1 |
| `ab`, a carriage return, a line feed, `cd` | 3 to 3 | line 1, column 3 | line 1, column 3: the boundary between the carriage return and the line feed |
| `ab`, a carriage return, a line feed, `cd` | 4 to 4 | line 2, column 1 | line 2, column 1 |
| the empty text | 0 to 0 | line 1, column 1 | line 1, column 1 |
| U+FEFF | 1 to 1 | line 1, column 1 | line 1, column 1 |
| U+FEFF, `ab` | 0 to 2 | none | none: the run holds the byte order mark, so it is not a span |
| U+FEFF | 0 to 0 | none | none: boundary 0 is not a boundary of the body, so the run is not a span |
