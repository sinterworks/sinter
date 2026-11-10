<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Text and notation
@design text=v1
@cites rfc/3629
@cites rfc/5234
@cites rfc/7405
Specifies whole numbers and their numerals, hex digits, characters and texts, bytes and UTF-8, lines, positions, and spans, the notation of productions, and conforming programs with their inputs and results, as used in Sinter, and requirements for conforming programs that decode and encode UTF-8 and give lines, positions, and spans.

A text is a finite sequence of characters, such as `docs/a.md`. A byte
sequence, such as 0x68, 0x69, holds a text when it is valid UTF-8. The
line endings of a text divide it into lines. Each character of a line
has a position, such as line 3, column 7, and a span, such as a word of
the text, has a position where it starts and a position where it ends.

The productions in section 3 are written in ABNF, the notation of
RFC 5234, with the case-sensitive strings of RFC 7405. A production,
such as `hex-digit = DIGIT / %x61-66`, gives the texts that its name
matches. In a production, `/` separates two alternatives, and `( )`
groups elements. The quoted string `"0"` is the character `0`. `*`
repeats the element after it any number of times, zero included. `%x61`
is the character U+0061, and `%x31-39` is any one character from U+0031
to U+0039. `DIGIT` is a core rule of RFC 5234: any one of the characters
`0` to `9`. In RFC 5234, a quoted string such as `"a"` matches its
letters in either case. RFC 7405 adds the string `%s"…"`, which matches
its letters only in the same case.

From RFC 3629, the design takes UTF-8: how a byte sequence encodes a
text, the rule `UTF8-char`, which gives the bytes that encode one
character, and the rule `UTF8-octets`, which gives the byte sequences
that are valid UTF-8.

## 1. Terms

| term | meaning |
|---|---|
| design | a document that holds requirements |
| requirement | a definition, or an obligation of a conforming program, that a design holds under a name |
| conforming program | a program, or a part of a program, that meets every requirement of a design |
| must | states an obligation of a conforming program |
| input | a thing that a conforming program takes, such as a byte sequence that it decodes |
| result | a text, such as "valid", that a conforming program gives for an input, and that a requirement names as a result |
| whole number | a number with no fractional part, such as −7, 0, or 42 |
| decimal numeral | a text of the characters `0` to `9` that writes a whole number of 0 or more in base 10, and that does not start with `0` unless it is `0`, such as `42` |
| 0x numeral | `0x`, then one or more of `0` to `9` and `A` to `F`, which writes a whole number in base 16, such as 0x0A for 10 |
| U+ numeral | `U+`, then four to six of `0` to `9` and `A` to `F`, which writes a whole number in base 16, such as U+0041 for 65 |
| hex digit | one of the characters `0` to `9` and `a` to `f`, which write the whole numbers 0 to 15 |
| code point | a whole number from 0 to 1,114,111, written as U+0000 to U+10FFFF |
| character | a Unicode scalar value, which has one code point: from U+0000 to U+D7FF, or from U+E000 to U+10FFFF |
| code point order | the order of characters by their code points |
| space, tab, line feed, carriage return | the characters U+0020, U+0009, U+000A, and U+000D |
| text | a finite sequence of characters |
| empty text | the text of no characters |
| place | the whole number, counted from 1, at which a character is in a text, or a byte is in a byte sequence |
| boundary | a whole number from 0 to the number of characters of a text: boundary 0 is before place 1, and each other boundary is right after the place with the same number |
| run | the characters of a text from a boundary to the same boundary or a later boundary, each at its place, such as `cd` from boundary 2 to boundary 4 of `abcde`; a run can be empty |
| Unicode normalization | a change of a text into a standard form of Unicode, such as the change of `e` and U+0301 into U+00E9 |
| byte | a whole number from 0 to 255 |
| byte sequence | a finite sequence of bytes |
| UTF-8 encoding | the byte sequence that encodes a text in UTF-8 |
| valid UTF-8 | a byte sequence is valid UTF-8 when it is the UTF-8 encoding of a text |
| text of a byte sequence | the text whose UTF-8 encoding a byte sequence is |
| overlong encoding | a byte sequence that would encode a character in more bytes than the UTF-8 encoding of that character has |
| byte order mark | the character U+FEFF when it is at place 1 of a text |
| body | the run of a text without its byte order mark |
| line ending | a line feed of a body, with the carriage return right before it when there is one |
| line | one of the runs into which the line endings divide a body, except an empty run at the end |
| line number | the first of the two whole numbers of a position: 1 for the first line of a text, and 1 more for each later line |
| column | the second of the two whole numbers of a position |
| position | a line number and a column, such as line 3, column 7 |
| span | a run of the body of a text, with a start and an end, which are positions |
| ABNF | the notation for grammars of RFC 5234, with the case-sensitive strings of RFC 7405 |
| production | a rule of ABNF, such as `hex-digit = DIGIT / %x61-66`, which gives the texts that its name matches |
| terminal value | a number into which a rule of ABNF resolves, such as 0x61 for `%x61` |

## 2. Texts, bytes, and lines

### 2.1 Whole numbers, numerals, and hex digits

A whole number is a number with no fractional part: 0, 1, 2, and so on,
or −1, −2, and so on. A decimal numeral writes a whole number of 0 or
more in base 10, with the characters `0` to `9`, such as `42` for 42. A
decimal numeral does not start with `0` unless it is `0`: `0` is the
decimal numeral of 0, and `042` is not a decimal numeral.

Two kinds of numeral write whole numbers in base 16, with `0` to `9` for
0 to 9 and the upper-case letters `A` to `F` for 10 to 15. A 0x numeral
is `0x`, then one or more of these, such as 0x0A for 10 and 0xFF for
255. A U+ numeral is `U+`, then four, five, or six of these, such as
U+0041 for 65 and U+10FFFF for 1,114,111. A U+ numeral that writes the
code point of a character also names that character (section 2.2).

A hex digit is one of the sixteen characters `0` to `9` and `a` to `f`.
The hex digits `0` to `9` write the whole numbers 0 to 9, and the hex
digits `a` to `f` write 10 to 15. An upper-case letter is not a hex
digit: `3f2a` is a text of four hex digits, and `3F2A` is not. So the
letters `A` to `F` of a 0x numeral or a U+ numeral are not hex digits.

### 2.2 Characters and texts

A code point is a whole number from 0 to 1,114,111. A character is a
Unicode scalar value. Each character has one code point, and no two
characters have the same code point. The code points of the characters
are the code points from U+0000 to U+D7FF and from U+E000 to U+10FFFF.
So U+D800 is a code point, and no character has it. A U+ numeral that
writes the code point of a character also names that character: U+0041
names the character `A`.

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
"the empty text". They write a byte sequence as its parts, in order,
with commas between them: a 0x numeral stands for the byte that it
writes, and characters between backticks stand for the UTF-8 encoding
of those characters. They write the lines of a text as the texts of the
lines, in order, with semicolons between them, or as "no line" when
the text has no line. For a character that has no position, they write
"none". They write a span as the boundary where it starts, "to", and the
boundary where it ends, such as "1 to 4" (section 2.4).

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
holds the characters at the places between its start and its end, in
order, and each character keeps its place. So the run from boundary 2
to boundary 4 of `abcde` holds `cd`, at places 3 and 4. A run that
starts and ends at the same boundary is empty. The text of a run is its
characters in order.

Two runs are the same run only when they start at the same boundary and
end at the same boundary. So the text `aba` has two different runs that
each hold one `a`: the run from boundary 0 to boundary 1, and the run
from boundary 2 to boundary 3. The text of each of these two runs is
`a`. In the same way, the empty run from boundary 1 to boundary 1 and
the empty run from boundary 2 to boundary 2 are two different runs.

### 2.3 Bytes and UTF-8

A byte is a whole number from 0 to 255, such as 0x41. A byte sequence
is a finite sequence of bytes. The empty byte sequence is the byte
sequence of no bytes. The places of a byte sequence number its bytes
from 1, in order. Two byte sequences are the same byte sequence when
they have the same number of bytes and the same byte at each place. A
byte is not a character, and a byte sequence is not a text: the byte
0x41 is 65, and the code point of the character `A` is 65 too, but the
byte is not the character.

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

A position is a line number and a column, both counted from 1. Each
character of a text, except its byte order mark, has a position.

The byte order mark of a text is the character at place 1 when that
character is U+FEFF. The body of a text is the run of the text that
holds every character except the byte order mark. The byte order mark
is on no line, so it has no position. A U+FEFF at any other place is a
character like any other.

A line ending is a line feed of the body, together with the carriage
return right before that line feed when the body holds one there. The
line endings divide the body into runs: the run from the start of the
body to the first line ending, the run from each line ending to the next
line ending, and the run from the last line ending to the end of the
body. A body with no line ending is one run. The lines of the text are
these runs, except the last run when it is empty. The first line has
the line number 1, and the line number of each other line is 1 more
than the line number of the line before it.

A line never holds a line feed. A body that ends with a line feed has no
empty line after that line feed. The empty body has no line. The text
of two line feeds has two lines, and both are empty: the run from
boundary 0 to boundary 0, and the run from boundary 1 to boundary 1. A
carriage return that is not right before a line feed is a character of
its line. Only a line feed ends a line: U+000B, U+000C, U+0085, U+2028,
and U+2029 are characters of their line.

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

The column of the character at a place of a line is 1 more than the
number of characters of the line at places before that place. A line
ending is not part of its line, so its characters add nothing to the
columns of the line. Each character of a line ending has the line
number of the line that ends at that line ending. Its column is 1 more
than the number of characters of that line. A column counts characters,
not bytes: U+00E9 is one character, which UTF-8 encodes in two bytes. A
tab is one character, so it counts as one column.

| text | place | position |
|---|---|---|
| `ab`, a line feed, `c` | 4 | line 2, column 1 |
| `ab`, a carriage return, a line feed, `c` | 3 | line 1, column 3 |
| `ab`, a carriage return, a line feed, `c` | 4 | line 1, column 3 |
| U+00E9, `x` | 2 | line 1, column 2 |
| `e`, U+0301, `x` | 3 | line 1, column 3 |
| U+FEFF, `x` | 2 | line 1, column 1 |
| U+FEFF, `x` | 1 | none |

A boundary of the body also has a position. A boundary inside a line, or
at the start or the end of a line, has the line number of that line, and
its column is 1 more than the number of the characters of the line
before the boundary. So the position of a character is the position of
the boundary right before it. The boundary between the carriage return
and the line feed of a line ending has the position of that carriage
return. The end of a body that is empty, or that ends with a line
ending, is on no line. Its line number is 1 more than the number of the
lines of the text, and its column is 1: in the text `a`, a line feed,
the end of the body is at line 2, column 1.

A span of a text is a run of the body of the text, such as a word, or
the empty run where an error starts. The start of a span is the
position of the boundary where the span starts. The end of a span is
one column past the last character of a line that the span holds, on
the line of that character. So a line ending at the end of a span does
not move the end of the span. A span that holds no character of a line
ends where it starts. An empty span is such a span: in the text `a =`,
the empty span at boundary 3, after the last character, starts and ends
at line 1, column 4.

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
0x61. Each terminal value of a production is the code point of one
character, so `%x61` matches the character `a`, U+0061.

A production can use the core rules of RFC 5234, such as `DIGIT` and
`HEXDIG`. A quoted string matches its letters in either case, and the
core rule `HEXDIG` uses quoted strings for its letters. So `HEXDIG`
matches both `a` and `A`. The production `hex-digit` of section 3.9 uses
`%x61-66` for its letters, so it matches `a` and does not match `A`.

A rule name in a production names a core rule or a production, without
regard to case, so `digit` names the core rule `DIGIT`. A production can
name a production of its own requirement, or of a requirement that its
own requirement cites. A production holds no prose value, which RFC 5234
writes between `<` and `>`.

A text matches a production only as a whole. The text `42` matches the
production `decimal-numeral` of section 3.8, and the text `42a` does
not, although `42a` starts with `42`. A character matches a production
when the text of that one character matches it, so the character `a`
matches `hex-digit`.

### 2.6 Conforming programs, inputs, and results

A design is a document that holds requirements. A requirement is a
definition, or an obligation of a conforming program, that a design
holds under a name, such as `whole-numbers`. A conforming program of a
design is a program, or a part of a program, that meets every
requirement of the design. So one program can hold conforming programs
of several designs. In a requirement, "must" states an obligation of a
conforming program of the design that holds the requirement.

An input is a thing that a conforming program takes, such as a byte
sequence that it decodes. A result is a text, such as "valid", that a
conforming program gives for an input, and that a requirement names as
a result. A requirement writes a result between double quotes, and the
double quotes are not part of the result.

These are the inputs that a conforming program can take, and what it
gives for each:

| input | what a conforming program gives |
|---|---|
| a byte sequence that it decodes as UTF-8 | the result "valid", with the text of the byte sequence, or the result "invalid" |
| a text that it encodes as UTF-8 | the UTF-8 encoding of the text |
| a text for which it gives the lines | each line of the text, in the order of the lines, and no other run |
| the character at a place of the body of a text, for which it gives a line number or a column | the line number of the position of that character, the column of that position, or both |
| the start or the end of a span of a text, for which it gives a line number or a column | the line number of that start or that end, its column, or both |

A conforming program gives no line number and no column for the byte
order mark of a text: a byte order mark has no position.

## 3. Requirements

### 3.1 Whole numbers

@req whole-numbers=v1

A whole number is a number with no fractional part: 0, 1, 2, and so on,
or −1, −2, and so on.

### 3.2 Characters

@req characters=v1
@cites #{whole-numbers=v1, conforming-programs=v1}

A code point is a whole number from 0 to 1,114,111. A character is a
Unicode scalar value. Each character has one code point, and no two
characters have the same code point. The code points of the characters
are the whole numbers from 0 to 55,295 and from 57,344 to 1,114,111. A
space is the character whose code point is 32, a tab is the character
whose code point is 9, a line feed is the character whose code point is
10, and a carriage return is the character whose code point is 13. In a
requirement, characters between two backticks are those characters, and
the backticks are not part of them.

### 3.3 Numerals in base 16

@req base-16-numerals=v1
@cites #{whole-numbers=v1, characters=v1}

A 0x numeral is `0x`, then one or more of `0` to `9` and `A` to `F`. A
U+ numeral is `U+`, then four, five, or six of `0` to `9` and `A` to
`F`. A 0x numeral or a U+ numeral writes the whole number that the part
after `0x` or `U+` writes in base 16, with `0` to `9` for 0 to 9 and `A`
to `F` for 10 to 15, such as 0x0A for 10 and U+0041 for 65. A U+ numeral
that writes the code point of a character also names that character.

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
boundary k is right after place k. A run of a text is given by a
boundary s of the text and a boundary e of the text that is s or
greater. The run starts at s and ends at e. It holds the characters at
the places from s + 1 to e, in order, each at its place, and these
places are the places of the run. The run is empty when s = e, and then
it holds no character. Two runs of a text are the same run when, and
only when, they start at the same boundary and end at the same
boundary. The text of a run is the text of the characters of the run,
in their order.

### 3.7 Notation

@req notation=v1
@cites {
    rfc/5234, rfc/7405,
    #{characters=v1, texts=v1, base-16-numerals=v1, conforming-programs=v1},
}

A production is a rule of ABNF, the notation of RFC 5234, with the
case-sensitive strings of RFC 7405, that a requirement holds. A
production can use the core rules of RFC 5234, Appendix B.1. A
production holds no prose value, which RFC 5234 writes between `<` and
`>`. A rule name in a production that a requirement R holds names the
one core rule, or the one production of R or of a requirement that R
cites, that has that rule name, without regard to case. Each terminal
value of a production, and of each core rule that it uses, is the code
point of one character, so `%x41` matches the character U+0041. A text
matches a production when, and only when, the production matches the
whole of the text. A character matches a production when, and only
when, the text of that one character matches the production.

### 3.8 Decimal numerals

@req decimal-numerals=v1
@cites #{notation=v1, whole-numbers=v1, texts=v1, characters=v1}

A decimal numeral is a text that matches the production
`decimal-numeral`:

```
decimal-numeral  = "0" / ( %x31-39 *DIGIT )
```

The whole number that a decimal numeral writes is the whole number that
its characters write in base 10, with the characters `0` to `9` for 0
to 9. The decimal numeral of a whole number of 0 or more is the decimal
numeral that writes that whole number.

### 3.9 Hex digits

@req hex-digits=v1
@cites #{notation=v1, whole-numbers=v1, characters=v1}

A hex digit is a character that matches the production `hex-digit`:

```
hex-digit  = DIGIT / %x61-66
```

A hex digit writes a whole number: the characters `0` to `9` write 0 to
9, in that order, and the characters `a` to `f` write 10 to 15, in that
order.

### 3.10 Bytes

@req bytes=v1
@cites #{whole-numbers=v1, characters=v1, texts=v1}

A byte is a whole number from 0 to 255. A byte sequence is a finite
sequence of bytes. The empty byte sequence is the byte sequence of no
bytes. The places of a byte sequence are numbered from 1, one place for
each byte of the byte sequence, in its order. Two byte sequences are
the same byte sequence when, and only when, they have the same number
of bytes and the same byte at each place. A byte is not a character,
and a byte sequence is not a text.

### 3.11 UTF-8

@req utf-8=v1
@cites {
    rfc/3629,
    #{characters=v1, texts=v1, bytes=v1, base-16-numerals=v1, notation=v1},
}

A byte sequence is valid UTF-8 when, and only when, the rule
`UTF8-octets` of RFC 3629 matches the whole byte sequence, with each
terminal value of that rule as one byte. The text of a byte sequence
that is valid UTF-8 holds one character for each `UTF8-char` that the
rule `UTF8-octets` matches in the byte sequence, in their order: the
character that the bytes of that `UTF8-char` encode, as RFC 3629
defines UTF-8. The text holds a U+FEFF that the first `UTF8-char`
encodes, as it holds each other character. The UTF-8 encoding of a text
is the byte sequence that holds, for each character of the text in its
order, the bytes that encode that character, as RFC 3629 defines UTF-8,
and no other bytes.

### 3.12 Byte order marks

@req byte-order-marks=v1
@cites #{characters=v1, texts=v1, base-16-numerals=v1}

The byte order mark of a text is the character at place 1 of the text
when that character is U+FEFF. A text has no other byte order mark.

### 3.13 Lines

@req lines=v1
@cites #{
    characters=v1, texts=v1, runs=v1, byte-order-marks=v1, whole-numbers=v1,
}

The body of a text is the run of the text that holds every character of
the text except its byte order mark. A line ending is the run of the
text that holds a line feed of the body and, when the character at the
place right before the place of that line feed is a carriage return of
the body, that carriage return, and no other character. A line of the
text is a run of the text that starts at the start of the body or at
the end of a line ending, and that ends at the start of the first line
ending that starts at the start of the run or later, or at the end of
the body when no line ending starts at the start of the run or later. A
run that ends at the end of the body is a line only when it is not
empty. The line that starts at the start of the body has the line
number 1. Each other line starts at the end of a line ending, and its
line number is 1 more than the line number of the line that ends at the
start of that line ending. The lines of a text are in the order of their
line numbers. A character of a line is a character that the line holds,
and a character of a line ending is a character that the line ending
holds.

### 3.14 Positions

@req positions=v1
@cites #{
    lines=v1, texts=v1, runs=v1, characters=v1, byte-order-marks=v1,
    whole-numbers=v1,
}

A position is a pair of whole numbers: a line number and a column. A
boundary of the body of a text is a boundary of the text from the start
of the body to the end of the body. The position of a boundary b of the
body is this:

- When a line starts at b or before b, and ends at b or after b: the
  line number of that line, and, as the column, 1 more than the number
  of the characters of that line at places before b.
- Otherwise, when a line ending starts before b and ends after b: the
  line number of the line that ends at the start of that line ending,
  and, as the column, 1 more than the number of the characters of that
  line.
- Otherwise: 1 more than the number of the lines of the text, as the
  line number, and 1, as the column.

The position of the character at a place p of the body is the position
of the boundary p − 1. A byte order mark has no position.

### 3.15 Spans

@req spans=v1
@cites #{
    texts=v1, runs=v1, lines=v1, positions=v1, characters=v1,
    byte-order-marks=v1,
}

A span of a text is a run of the body of the text. The start of a span
is the position of the boundary at which the span starts. When the span
holds a character of a line, the end of the span is the position of the
boundary right after the last character of a line that the span holds.
When the span holds no character of a line, the end of the span is the
start of the span.

### 3.16 Conforming programs

@req conforming-programs=v1

A design is a document that holds requirements. A requirement is a
definition, or an obligation of a conforming program, that a design
holds under a name. A conforming program of a design is a program, or a
part of a program, that meets every requirement of the design. In a
requirement of a design, a conforming program is a conforming program
of that design, and "must" states an obligation of each conforming
program of that design.

### 3.17 Inputs

@req inputs=v1
@cites #{conforming-programs=v1, bytes=v1}

An input is a thing that a conforming program takes, such as a byte
sequence that it decodes.

### 3.18 Results

@req results=v1
@cites #{conforming-programs=v1, inputs=v1, texts=v1}

A result is a text, such as "valid", that a conforming program gives
for an input, and that a requirement names as a result. A requirement
writes a result between double quotes, as in "valid", and the double
quotes are not part of the result.

### 3.19 Byte sequences that a program decodes

@req decode-utf-8=v1
@cites #{conforming-programs=v1, results=v1, bytes=v1, utf-8=v1}

For each byte sequence that it decodes as UTF-8, a conforming program
must give exactly one result: "valid" when the byte sequence is valid
UTF-8, and "invalid" when it is not.

### 3.20 The text of a byte sequence that a program decodes

@req give-decoded-texts=v1
@cites #{conforming-programs=v1, results=v1, bytes=v1, texts=v1, utf-8=v1}

When it gives the result "valid" for a byte sequence that it decodes as
UTF-8, a conforming program must give with that result the text of the
byte sequence.

### 3.21 The UTF-8 encodings that a program gives

@req give-utf-8-encodings=v1
@cites #{conforming-programs=v1, bytes=v1, texts=v1, utf-8=v1}

When a conforming program gives a byte sequence as the UTF-8 encoding of
a text, it must give the UTF-8 encoding of that text.

### 3.22 The lines that a program gives

@req give-lines=v1
@cites #{conforming-programs=v1, texts=v1, runs=v1, lines=v1}

When a conforming program gives runs of a text as the lines of that
text, it must give each line of the text, in the order of the lines, and
no other run.

### 3.23 The line numbers and columns of characters

@req give-positions=v1
@cites #{
    conforming-programs=v1, texts=v1, characters=v1, runs=v1, lines=v1,
    positions=v1,
}

When a conforming program gives a line number or a column for the
character at a place of the body of a text, it must give the line number
of the position of that character as that line number, and the column
of that position as that column.

### 3.24 No position for a byte order mark

@req omit-byte-order-mark-positions=v1
@cites #{
    conforming-programs=v1, texts=v1, byte-order-marks=v1, lines=v1,
    positions=v1,
}

A conforming program must give no line number and no column for the
byte order mark of a text.

### 3.25 The starts of spans

@req give-span-starts=v1
@cites #{conforming-programs=v1, texts=v1, spans=v1, positions=v1, lines=v1}

When a conforming program gives a line number or a column for the start
of a span of a text, it must give the line number of the start of that
span as that line number, and the column of the start of that span as
that column.

### 3.26 The ends of spans

@req give-span-ends=v1
@cites #{conforming-programs=v1, texts=v1, spans=v1, positions=v1, lines=v1}

When a conforming program gives a line number or a column for the end
of a span of a text, it must give the line number of the end of that
span as that line number, and the column of the end of that span as
that column.

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
- A cell writes a span as the decimal numeral of the boundary where it
  starts, "to", and the decimal numeral of the boundary where it ends,
  as in "1 to 4".
- A cell that holds "valid, with the text" and a text, or "valid, with
  the empty text", gives the result "valid" and that text, which a
  conforming program gives with that result.
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
| 0x80 | invalid: the UTF-8 encoding of no character starts with the byte 0x80 |
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

### 4.2 Texts that a program encodes

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
| `a`, a carriage return | 2 | line 1, column 2 |
| `a`, a carriage return, a carriage return, a line feed | 2 | line 1, column 2 |
| `a`, a carriage return, a carriage return, a line feed | 3 | line 1, column 3 |
| `a`, a carriage return, a carriage return, a line feed | 4 | line 1, column 3 |
| `a`, a carriage return, `b` | 3 | line 1, column 3 |
| U+FEFF | 1 | none: a byte order mark has no position |
| U+FEFF, `x` | 1 | none: a byte order mark has no position |
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

### 4.5 The spans that a program gives

Each row gives a text, a span of that text, and the start and the end
of that span.

| text | span | start | end |
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
| `a`, a line feed | 1 to 2 | line 1, column 2 | line 1, column 2: the span holds no character of a line |
| `a`, a line feed | 2 to 2 | line 2, column 1 | line 2, column 1: the end of a body that ends with a line ending |
| a line feed written 2 times | 1 to 1 | line 2, column 1 | line 2, column 1 |
| a line feed written 2 times | 2 to 2 | line 3, column 1 | line 3, column 1 |
| `ab`, a carriage return, a line feed, `cd` | 3 to 3 | line 1, column 3 | line 1, column 3: the boundary between the carriage return and the line feed |
| `ab`, a carriage return, a line feed, `cd` | 4 to 4 | line 2, column 1 | line 2, column 1 |
| the empty text | 0 to 0 | line 1, column 1 | line 1, column 1 |
| U+FEFF | 1 to 1 | line 1, column 1 | line 1, column 1 |
