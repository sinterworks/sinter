<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Text and notation
@design text=v1
@cites rfc/3629
@cites rfc/5234
@cites rfc/7405
@cites rfc/8259
Specifies, as used in Sinter, whole numbers, numerals, and hex digits; code points, characters, code point order, texts, places, boundaries, and runs; bytes and UTF-8; byte order marks, bodies, line endings, lines, line numbers, positions, and spans; designs, requirements, and code spans; the notation of productions and rule names; conforming programs, inputs, and results; and requirements for conforming programs that test and decode UTF-8, give UTF-8 encodings, and give lines, line numbers, the positions of characters, and the starts and ends of spans.

A text is a finite sequence of characters, such as `docs/a.md`. A byte
sequence, such as 0x68, 0x69, is the UTF-8 encoding of a text when it is
valid UTF-8. A byte order mark is a U+FEFF that is the first character
of a text. The body of a text is the run of the text after its byte
order mark, or the whole text when it has none. The line endings of the
body divide it into lines. The character at each place of the body has a
position, such as line 3, column 7. A span, such as a word of the text,
has a start and an end, which are positions.

The productions in section 3 use ABNF, the notation of RFC 5234, with
the case-sensitive strings of RFC 7405. A production, such as
`hex-digit = DIGIT / %x61-66`, matches some texts: `hex-digit` matches
the text `c`, and it does not match the text `C`. In a production, `/`
separates two alternatives, and `( )` groups elements. The quoted
string `"0"` matches the character `0`. `*` repeats the element after
it any number of times, zero included. `1*` repeats the element after
it one or more times, and `4*6` repeats the element after it four,
five, or six times. `%x61` matches the character U+0061, and `%x31-39`
matches any one character from U+0031 to U+0039. `DIGIT` is a core
rule of RFC 5234, which matches any one of the characters `0` to `9`.
In RFC 5234, a quoted string such as `"a"` matches its letters in
either case. RFC 7405 adds the string `%s"…"`, which matches its
letters only in the same case.

From RFC 3629, the design takes UTF-8: how a byte sequence encodes a
text, the rule `UTF8-char`, which matches the bytes that encode one
character, and the rule `UTF8-octets`, which matches the byte
sequences that are valid UTF-8.

From RFC 8259, the design takes JSON texts: the file that holds the
conformance vectors of the design has one JSON text on each line of its
text.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| term | a definition that a design declares under a name, such as `whole-number`; every definition of a design is a term |
| [requirement](sinter:#requirement=v1) | an obligation that a design declares under a name, such as `give-lines`, and states with the word must |
| [design](sinter:#design=v1) | a document that declares, each under a name, obligations and definitions; a definition of a design is a definition that the design declares under a name |
| [conforming program](sinter:#conforming-program=v1) | a program, or a part of a program, that meets every requirement of a design |
| must | the word with which a [requirement](sinter:#requirement=v1) states an obligation of a [conforming program](sinter:#conforming-program=v1) |
| [input](sinter:#input=v1) | a thing that a conforming program takes, such as a byte sequence or a text |
| decode | a conforming program decodes a byte sequence as UTF-8 when it tests whether the byte sequence is valid UTF-8 and, when the byte sequence is valid UTF-8, gives the text of the byte sequence |
| [result](sinter:#result=v1) | a text that a requirement shows between two double quotes, such as "valid", as one of the cases of what a conforming program gives for an input; the double quotes are not part of the result; a conforming program gives a result when it gives something that stands for that result and for no other result |
| [whole number](sinter:#whole-number=v1) | a number with no fractional part, such as −7, 0, or 42 |
| [decimal numeral](sinter:#decimal-numeral=v1) | a text of the characters `0` to `9` that writes a whole number of 0 or more in base 10, and whose first character is not `0` unless the text is `0`, such as `42` |
| [0x numeral](sinter:#0x-numeral=v1) | `0x`, then one or more of `0` to `9` and `A` to `F`, which writes a whole number in base 16, such as 0x0A for 10 |
| [U+ numeral](sinter:#u-numeral=v1) | `U+`, then four to six of `0` to `9` and `A` to `F`, which writes a whole number in base 16, such as U+0041 for 65, and, when that number is the code point of a character, names that character; the U+ numeral of a code point has four characters after `U+` when the code point is less than 65,536, and otherwise has no `0` as its first character after `U+` |
| [hex digit](sinter:#hex-digit=v1) | one of the characters `0` to `9` and `a` to `f`, which write the whole numbers 0 to 15 |
| [code point](sinter:#code-point=v1) | a whole number from 0 to 1,114,111 |
| [character](sinter:#character=v1) | each character has one code point, which is a Unicode scalar value: a whole number from 0 to 55,295 (U+D7FF) or from 57,344 (U+E000) to 1,114,111 (U+10FFFF); each Unicode scalar value is the code point of exactly one character |
| [code point order](sinter:#code-point-order=v1) | one character comes before another in code point order when the code point of the one is less than the code point of the other |
| [space](sinter:#space=v1), [tab](sinter:#tab=v1), [line feed](sinter:#line-feed=v1), [carriage return](sinter:#carriage-return=v1) | the characters U+0020, U+0009, U+000A, and U+000D |
| [code span](sinter:#code-span=v1) | the characters between the two backticks of a pair, such as `%x61`, where the backticks on each line of a definition or a requirement pair in order, except on the lines of a block; a code span stands for those characters, and not for the backticks |
| [block](sinter:#code-span=v1) | the lines of a definition or a requirement from a line whose first characters, after any spaces, are three backticks to the next such line, such as the lines that hold the rule of a production; no backtick on these lines belongs to a pair |
| [text](sinter:#text=v1) | a finite sequence of characters |
| [empty text](sinter:#text=v1) | the text of no characters |
| [place](sinter:#place=v1) | a whole number, from 1 to the number of the characters of a text, at which a character is in the text |
| [boundary](sinter:#boundary=v1) | a whole number from 0 to the number of characters of a text: boundary 0 is before place 1, and each other boundary is right after the place with the same number |
| [run](sinter:#run=v1) | a sequence of the characters of a text that starts at a boundary, ends at the same boundary or a later boundary, and holds the characters between these two boundaries, each at its place, such as the run of `abcde` that starts at boundary 2, ends at boundary 4, and holds `cd`; a run can be empty |
| [boundary of a run](sinter:#run=v1) | a boundary of a text from the boundary where a run starts to the boundary where the run ends, such as a boundary of the body |
| Unicode normalization | a change of a text into a standard form of Unicode, such as the change of `e` and U+0301 into U+00E9 |
| [byte](sinter:#byte=v1) | a whole number from 0 to 255 |
| [byte sequence](sinter:#byte-sequence=v1) | a finite sequence of bytes |
| [place of a byte sequence](sinter:#byte-sequence=v1) | a whole number, from 1 to the number of the bytes of a byte sequence, at which a byte is in the byte sequence |
| [UTF-8 encoding](sinter:#utf-8-encoding=v1) | the byte sequence that holds, for each character of a text in order, the bytes that encode that character in UTF-8, and no other bytes |
| [valid UTF-8](sinter:#valid-utf-8=v1) | a byte sequence is valid UTF-8 when the rule `UTF8-octets` of RFC 3629 matches the whole byte sequence |
| [text of a byte sequence](sinter:#text-of-a-byte-sequence=v1) | for a byte sequence that is valid UTF-8, the text that holds, in order, the character that each `UTF8-char` of RFC 3629 in the byte sequence encodes, and no other character |
| overlong encoding | a byte sequence that has the form of RFC 3629 for two, three, or four bytes for the code point of a character whose UTF-8 encoding has fewer bytes, such as 0xC0, 0xAF, the two-byte form for 47, the code point of `/` |
| [byte order mark](sinter:#byte-order-mark=v1) | the character U+FEFF at place 1 of a text |
| [body](sinter:#body=v1) | the run of a text that starts at boundary 1 when the text has a byte order mark, and at boundary 0 when it has none, and that ends at the last boundary of the text |
| [line ending](sinter:#line-ending=v1) | a run of a text that holds a line feed of the body and, when a carriage return of the body is right before that line feed, that carriage return, and that holds no other character |
| [line](sinter:#line=v1) | one of the runs into which the line endings divide a body, except an empty run that ends at the boundary where the body ends |
| [line number of a line](sinter:#line-number=v1) | the number of a line: 1 for the first line of a text, and 1 more for each later line |
| [position](sinter:#position=v1) | a pair of whole numbers, the line number of the position and the column of the position, such as line 3, column 7 |
| [line number of a position](sinter:#position=v1) | the first of the two whole numbers of a position, such as 3 in line 3, column 7 |
| [column](sinter:#position=v1) | the second of the two whole numbers of a position, such as 7 in line 3, column 7 |
| [span](sinter:#span=v1) | a run of a text that starts and ends at boundaries of the body; its start and its end are positions |
| ABNF | the notation for grammars of RFC 5234, with the case-sensitive strings of RFC 7405 |
| [production](sinter:#production=v1) | a rule of ABNF, such as `hex-digit = DIGIT / %x61-66`, that a definition or a requirement of a design holds, and that, with each rule, other than a core rule, that it reaches through its rule names, holds no prose value and has no rule name that names no rule or more than one rule; a text matches a production when, for some choice at each `/`, at each range of terminal values, at each letter of a quoted string that matches either case, and at each repetition, the production gives terminal values that match the characters of the text, one each, in their order |
| [rule name](sinter:#rule-name=v1) | a name in a rule of ABNF that a definition or a requirement R holds, such as `digit` for the core rule `DIGIT`, which names each rule that has that rule name, without regard to case, and that is a core rule of RFC 5234, a rule that R holds, or a rule that a definition Q holds when R refers to Q as a definition whose meaning R uses; R holds a rule of ABNF when the rule is on the lines of one of the blocks of R |
| [terminal value](sinter:#production=v1) | one of the numbers into which a rule of ABNF resolves, such as 0x61 for `%x61`; in a production, a terminal value matches the character whose code point it is |

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
The U+ numeral of a code point has four characters after `U+` when the
code point is less than 65,536, and otherwise has no `0` as its first
character after `U+`. So the U+ numeral of 65 is U+0041, and the U+
numeral of 128,512 is U+1F600. U+00041 also writes 65, and it is not
the U+ numeral of 65.

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

The examples show a text as its parts, in order, with commas between
them. A part is characters between backticks, such as `ab`; one of the
four named characters, such as a line feed; a U+ numeral, which names
one character; or a part, then "written", a decimal numeral, and
"times", which is that part as many times in a row as the numeral
writes. So "`a`, a line feed, `b`" is the text of the three characters
`a`, U+000A, and `b`. The examples show the text of no characters as
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

The examples show a byte sequence as its bytes, in order, with commas
between them, and each byte as a 0x numeral, such as 0x68, 0x69. They
show the byte sequence of no bytes as "the empty byte sequence".

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

RFC 3629 gives a form of UTF-8 for each number of bytes from one to
four. Each form is a pattern of bits, and the bits of a number fill the
bits that the pattern marks with x. An overlong encoding is a byte
sequence that has the form for two, three, or four bytes for the code
point of a character whose UTF-8 encoding has fewer bytes. So 0xC0,
0xAF is an overlong encoding: it is the two-byte form for 47, the code
point of `/`, and the UTF-8 encoding of `/` is 0x2F. These byte
sequences are not valid UTF-8:

| byte sequence | why |
|---|---|
| 0xFF | the UTF-8 encoding of no character holds the byte 0xFF |
| 0xC0, 0xAF | an overlong encoding |
| 0xED, 0xA0, 0x80 | the three-byte form of RFC 3629 for the number 55,296, which is not the code point of a character |
| 0xC3 | the first byte of the UTF-8 encoding of a character, with no byte after it |

### 2.4 Lines and positions

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

A line ending is a run of the text that ends at the boundary right after
a line feed of the body. It starts at the boundary right before that
line feed, or, when the body holds a carriage return right before that
line feed, at the boundary right before that carriage return. So in the
text `ab`, a carriage return, a line feed, `c`, the line ending starts
at boundary 2 and ends at boundary 4. A line starts at the boundary
where the body starts, or at the boundary where a line ending ends. It
ends at the first boundary, at or after the boundary where it starts,
where a line ending starts. When no line ending starts at or after the
boundary where it starts, the line ends at the boundary where the body
ends. A run that ends at the boundary where the body ends is a line only
when it is not empty. So the line endings divide the body into runs, and
the lines are these runs, except the last run when it is empty. The
first line has the line number 1, and the line number of each other line
is 1 more than the line number of the line before it.

A line never holds a line feed. A body whose last character is a line
feed has no empty line after that line feed. The empty body has no line.
The text of two line feeds has two lines, and both are empty: the run
that starts and ends at boundary 0, and the run that starts and ends at
boundary 1. A carriage return that is not right before a line feed is at
a place of a line, not of a line ending. No character other than a line
feed and a carriage return is at a place of a line ending: U+000B,
U+000C, U+0085, U+2028, and U+2029 are at places of lines.

The examples show the lines of a text as the texts of the lines, in
order, with semicolons between them, or as "no line" when the text has
no line. When the character at a place has no position, they show
"none". They show a span as the boundary where it starts, "to", and the
boundary where it ends, such as "1 to 4".

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

A position is a pair of whole numbers: the line number of the position
and the column of the position, both counted from 1. The character at
each place of the body has a position. In a text that has a byte order
mark, place 1 is not a place of the body, so the character at place 1
has no position. The column of the character at a place of a line is 1
more than the number of the places of the line before that place. The
character at each place of a line ending has the line number of the line
that ends at the boundary where that line ending starts. The column of
that character is 1 more than the number of the places of that line. A
column counts characters, not bytes: U+00E9 is one character, which
UTF-8 encodes in two bytes. A tab is one character, so it counts as one
column.

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
empty, or its last character is a line feed, no line ends at the
boundary where the body ends. The line number of the position of that
boundary is 1 more than the number of the lines of the text, and no line
has that line number. The column of that position is 1: in the text
`a`, a line feed, the boundary where the body ends has the position
line 2, column 1.

A span of a text is a run that starts at a boundary of the body and ends
at a boundary of the body, such as a word, or an empty run at a boundary
of the body. A run that starts at boundary 0 of a text that has a byte
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

### 2.5 Designs, requirements, and conforming programs

A design is a document that declares, each under a name, obligations
and definitions. A definition of a design is a definition that the
design declares under a name, such as `whole-number`. A requirement is
an obligation that a design declares under a name, such as
`give-lines`, and states with the word must. A conforming program of a
design is a program, or a part of a program, that meets every
requirement of the design. So one program can hold conforming programs
of several designs. In a design, a conforming program is a conforming
program of that design, and each obligation that a requirement of that
design states with the word must is an obligation of each conforming
program of that design.

### 2.6 Code spans and blocks

A backtick is the character U+0060, whose code point is 96. In a
definition or a requirement, a line whose first characters, after any
spaces, are three backticks opens a block of lines or closes the block
that is open. The first such line opens a block, the next such line
closes that block, the line after that opens a new block, and so on.
The lines of a block are the lines from the line that opens the block
to the line that closes it, or to the last line of the definition or
the requirement when no line closes it. The rule of a production is on
the lines of a block, such as the rule of `hex-digit` in section 3.28.
No backtick on the lines of a block belongs to a pair.

On every other line of a definition or a requirement, the backticks
pair in order: the first backtick with the second, the third with the
fourth, and so on. A backtick that belongs to no pair, such as the last
backtick of a line that holds three backticks and is not a line of a
block, is a character like any other. The characters between the two
backticks of a pair, such as `%x61`, are a code span. A code span
stands for those characters, and the backticks are not part of them.

### 2.7 Productions

A production is a rule of ABNF, the notation of RFC 5234, with the
case-sensitive strings of RFC 7405. A definition or a requirement holds
a rule of ABNF when the rule is on the lines of one of its blocks.
RFC 5234 calls the numbers into which a rule resolves its terminal
values: `%x61` is the terminal value 0x61. A terminal value in a
production matches the character whose code point it is, so `%x61`
matches the character `a`, U+0061. A terminal value that is not the
code point of a character, such as 0xD800, matches no character.

A production can use the core rules of RFC 5234, such as `DIGIT` and
`HEXDIG`, and a core rule can use other core rules: `HEXDIG` uses
`DIGIT`. A terminal value in a core rule that a production uses,
directly or through other core rules, matches a character in the same
way. A quoted string matches its letters in either case, and the core
rule `HEXDIG` uses quoted strings for its letters. So `HEXDIG` matches
both `a` and `A`. The production `hex-digit` of section 3.28 uses
`%x61-66` for its letters, so it matches `a` and does not match `A`.

When a definition or a requirement R holds a rule of ABNF, a rule name
in that rule names each rule that has that rule name, without regard to
case, and that is a core rule of RFC 5234, a rule that R holds, or a
rule that a definition Q holds when R refers to Q as a definition whose
meaning R uses. So `digit` names the core rule `DIGIT`. A rule reaches
each rule that one of its rule names names, and each rule that such a
rule reaches in turn. A rule of ABNF is a production only when it holds
no prose value, which stands between `<` and `>` in RFC 5234, and each
of its rule names names exactly one rule. Each rule that a production
reaches, other than a core rule, meets the same two conditions.

A text matches a production when, for some choice of one alternative at
each `/` and of one number of repetitions at each repetition, the
production gives terminal values that match the characters of the text,
one each, in their order. A range of terminal values, such as
`%x31-39`, gives a choice of one of its terminal values, and a letter of
a quoted string that matches either case gives a choice of one of its
two cases. When a production uses a rule more than once, each use has
its own choices. The order of the alternatives has no effect, so a
production `p = "a" / "ab"` matches the text `ab`, although its first
alternative matches the first character of `ab`. A text matches a
production only as a whole. The text `42` matches the production
`decimal-numeral` of section 3.25, and the text `42a` does not, although
the first two characters of `42a` are `42`. A character matches a
production when the text of that one character matches it, so the
character `a` matches `hex-digit`.

### 2.8 Inputs and results

An input is a thing that a conforming program takes, such as a byte
sequence or a text. A conforming program decodes a byte sequence as
UTF-8 when it tests whether the byte sequence is valid UTF-8 and, when
the byte sequence is valid UTF-8, gives the text of the byte sequence. A
result of a requirement is a text that the requirement shows between
two double quotes, such as "valid", as one of the cases of what a
conforming program gives for an input. The double quotes are not part
of the result. A conforming program gives a result when it gives
something that stands for that result and for no other result. So a
program that gives the number 1 for "valid" and the number 0 for
"invalid" gives these two results.

For each of these inputs, the requirements state what a conforming
program gives:

| input | what a conforming program gives |
|---|---|
| a byte sequence that it tests for valid UTF-8 | exactly one result: "valid" when the byte sequence is valid UTF-8, and "invalid" when it is not |
| a byte sequence for which it gives a text as the text of the byte sequence | the text of the byte sequence, and no other text |
| a text for which it gives the UTF-8 encoding | the UTF-8 encoding of the text |
| a text for which it gives the lines | as many runs or texts as the text has lines: as the k-th of them, the line with the line number k, or the text of that line |
| a text for which it gives a run or a text, together with a line number, as a line of the text | as that run or text, the line of the text that has that line number, or the text of that line |
| the character at a place of the body of a text, for which it gives a line number or a column | the line number of the position of that character, the column of that position, or both |
| a span of a text, for whose start or end it gives a line number or a column | the line number of that start or that end, its column, or both |

A conforming program gives no text as the text of a byte sequence that
is not valid UTF-8. It gives, as a line of a text, only a line of that
text or the text of a line of that text. It gives no line number and no
column for the character at place 1 of a text that has a byte order
mark: that character has no position. It gives a line number or a
column as the start or the end of a run only when the run is a span. So
it gives no line number and no column as the start or the end of a run
that starts at boundary 0 of a text that has a byte order mark.

## 3. Definitions

### 3.1 Whole numbers

@term whole-number=v1

A whole number is a number with no fractional part: 0, 1, 2, and so on,
or −1, −2, and so on.

### 3.2 Code points

@term code-point=v1
@cites #{whole-number=v1}

A code point is a whole number from 0 to 1,114,111.

### 3.3 Characters

@term character=v1
@cites #{code-point=v1, whole-number=v1}

Each character has one code point, which is a Unicode scalar value: a
whole number from 0 to 55,295 or from 57,344 to 1,114,111. Each Unicode
scalar value is the code point of exactly one character.

### 3.4 Spaces

@term space=v1
@cites #{character=v1, code-point=v1}

A space is the character whose code point is 32.

### 3.5 Tabs

@term tab=v1
@cites #{character=v1, code-point=v1}

A tab is the character whose code point is 9.

### 3.6 Line feeds

@term line-feed=v1
@cites #{character=v1, code-point=v1}

A line feed is the character whose code point is 10.

### 3.7 Carriage returns

@term carriage-return=v1
@cites #{character=v1, code-point=v1}

A carriage return is the character whose code point is 13.

### 3.8 Designs

@term design=v1

A design is a document that declares, each under a name, obligations
and definitions. A definition of a design is a definition that the
design declares under a name.

### 3.9 Requirements

@term requirement=v1
@cites #{design=v1}

A requirement is an obligation that a design declares under a name and
states with the word must.

### 3.10 Code point order

@term code-point-order=v1
@cites #{character=v1, code-point=v1}

One character comes before another in code point order, and the other
comes after it, when, and only when, the code point of the one is less
than the code point of the other.

### 3.11 Texts

@term text=v1
@cites #{character=v1}

A text is a finite sequence of characters. The empty text is the text
of no characters. Two texts are the same text when, and only when, they
have the same number of characters and, in their order, the same first
character, the same second character, and so on to the last character.

### 3.12 Places

@term place=v1
@cites #{text=v1, character=v1, whole-number=v1}

The places of a text are the whole numbers from 1 to the number of the
characters of the text. For each place k of a text, the character at
place k is the k-th character of the text: the character at place 1 is
the first character of the text.

### 3.13 Boundaries

@term boundary=v1
@cites #{text=v1, place=v1, character=v1, whole-number=v1}

A boundary of a text is a whole number from 0 to the number of
characters of the text. Boundary 0 is before place 1, and each other
boundary k is right after place k.

### 3.14 Runs

@term run=v1
@cites #{text=v1, place=v1, boundary=v1, character=v1}

A run of a text starts at a boundary s of the text and ends at a
boundary e of the text that is s or greater. For each boundary s of a
text and each boundary e of the text that is s or greater, the text has
a run that starts at s and ends at e. The run holds the characters at
the places from s + 1 to e, in order, each at its place, and these
places are the places of the run. The run is empty when s = e, and then
it holds no character. Two runs of a text are the same run when, and
only when, they start at the same boundary and end at the same boundary.
The text of a run is the text of the characters of the run, in their
order. A boundary of a run is a boundary of the text from the boundary
where the run starts to the boundary where the run ends.

### 3.15 Byte order marks

@term byte-order-mark=v1
@cites #{text=v1, place=v1, character=v1, code-point=v1}

A text has a byte order mark when, and only when, the character at place
1 of the text is the character whose code point is 65,279. The byte
order mark of such a text is that character, at place 1.

### 3.16 Bodies

@term body=v1
@cites #{text=v1, run=v1, boundary=v1, byte-order-mark=v1}

The body of a text that has a byte order mark is the run of the text
that starts at boundary 1 and ends at the last boundary of the text.
The body of every other text is the run of the text that starts at
boundary 0 and ends at the last boundary of the text.

### 3.17 Line endings

@term line-ending=v1
@cites #{
    text=v1, run=v1, boundary=v1, place=v1, body=v1, line-feed=v1,
    carriage-return=v1, character=v1,
}

A line ending of a text is a run of the text that meets each of these
conditions, where p is the boundary where the run ends:

- Place p is a place of the body, and the character at place p is a
  line feed.
- When place p − 1 is a place of the body and the character at place
  p − 1 is a carriage return, the run starts at boundary p − 2.
  Otherwise, the run starts at boundary p − 1.

### 3.18 Lines

@term line=v1
@cites #{text=v1, run=v1, boundary=v1, body=v1, line-ending=v1}

A line of a text is a run of the text that meets each of these
conditions:

- It starts at the boundary where the body starts, or at the boundary
  where a line ending ends.
- It ends at the first boundary, at or after the boundary where it
  starts, where a line ending starts. When no line ending starts at or
  after the boundary where it starts, it ends at the boundary where the
  body ends.
- It is not empty when it ends at the boundary where the body ends.

### 3.19 Line numbers

@term line-number=v1
@cites #{
    text=v1, line=v1, line-ending=v1, boundary=v1, body=v1,
    whole-number=v1,
}

Each line of a text has a line number, which is a whole number. The
line that starts at the boundary where the body starts has the line
number 1. Each other line starts at the boundary where a line ending
ends, and its line number is 1 more than the line number of the line
that ends at the boundary where that line ending starts. The lines of a
text are in the order of their line numbers.

### 3.20 Positions

@term position=v1
@cites #{
    line=v1, line-number=v1, line-ending=v1, body=v1, run=v1,
    boundary=v1, place=v1, text=v1, character=v1, byte-order-mark=v1,
    whole-number=v1,
}

A position is a pair of whole numbers: the line number of the position
and the column of the position. The position of a boundary b of the
body of a text is this:

- When a line starts at b or before b, and ends at b or after b: the
  line number of the position is the line number of that line, and the
  column of the position is 1 more than b − s, where s is the boundary
  where that line starts.
- Otherwise, when a line ending starts before b and ends after b: the
  line number of the position is the line number of the line that ends
  at the boundary where that line ending starts, and the column of the
  position is 1 more than e − s, where s and e are the boundaries where
  that line starts and ends.
- Otherwise: the line number of the position is 1 more than the number
  of the lines of the text, and no line has that line number. The
  column of the position is 1.

The position of a place p of the body of a text is the position of the
boundary p − 1, and the character at place p has that position. The
character at place 1 of a text that has a byte order mark has no
position.

### 3.21 Spans

@term span=v1
@cites #{
    text=v1, run=v1, boundary=v1, place=v1, body=v1, line=v1,
    position=v1,
}

A span of a text is a run of the text that starts at a boundary of the
body and ends at a boundary of the body. The start of a span is the
position of the boundary where the span starts. When one or more places
of the span are places of a line, the end of the span is the position of
boundary k, where k is the last of those places. Otherwise, the end of
the span is the start of the span.

### 3.22 Code spans

@term code-span=v1
@cites #{
    character=v1, code-point=v1, design=v1, requirement=v1, text=v1,
    line=v1, space=v1,
}

A backtick is the character whose code point is 96. In the text of a
definition or a requirement of a design, a line whose first characters,
after any spaces, are three backticks opens a block of lines or closes
the block that is open: the first such line opens a block, the next
such line closes that block, and so on. The lines of a block are the
lines from the line that opens the block to the line that closes it,
or to the last line of the definition or the requirement when no line
closes it. No backtick on the lines of a block belongs to a pair. On
each other line of a definition or a requirement, the backticks pair in
order: the first backtick with the second, the third with the fourth,
and so on. A backtick that belongs to no pair is a character like any
other. A code span is the characters between the two backticks of a
pair. A code span stands for those characters, and the backticks are
not part of them.

### 3.23 Rule names

@term rule-name=v1
@cites {rfc/5234, #{design=v1, requirement=v1, code-span=v1, line=v1}}

A definition or a requirement R of a design holds a rule of ABNF when,
and only when, the rule is on the lines of one of the blocks of R. A
rule name in a rule of ABNF that R holds names each rule that has that
rule name, without regard to case, and that is one of these: a core
rule of RFC 5234, Appendix B.1; a rule of ABNF that R holds; or a rule
of ABNF that a definition Q holds, when R refers to Q as a definition
whose meaning R uses.

### 3.24 Productions

@term production=v1
@cites {
    rfc/5234, rfc/7405,
    #{
        design=v1, requirement=v1, rule-name=v1, code-span=v1,
        character=v1, code-point=v1, text=v1,
    },
}

A production is a rule of ABNF, the notation of RFC 5234, with the
case-sensitive strings of RFC 7405, that meets these conditions:

- A definition or a requirement of a design holds it.
- It holds no prose value, which stands between `<` and `>` in RFC 5234.
- Each of its rule names names exactly one rule.
- Each rule that it reaches through its rule names, directly or through
  other rules, is a core rule of RFC 5234, or that rule holds no prose
  value and each rule name of that rule names exactly one rule.

A terminal value in a production, or in a core rule that a production
uses, directly or through other core rules, matches the character whose
code point it is, so `%x41` matches the character whose code point is
65. A terminal value that is not the code point of a character matches
no character. A text matches a production when, and only when, for some
choice of one alternative at each `/`, of one terminal value at each
range of terminal values, such as `%x30-39`, of one case at each letter
of a quoted string that matches either case, and of one number of
repetitions at each repetition, the production gives terminal values
that match the characters of the text, one each, in their order. An
optional sequence in `[ ]` is a repetition of zero times or one time.
Each use of a rule through a rule name has its own choices. The order of
the alternatives has no effect. A character matches a production when,
and only when, the text of that one character matches the production.

### 3.25 Decimal numerals

@term decimal-numeral=v1
@cites #{
    production=v1, rule-name=v1, code-span=v1, whole-number=v1, text=v1,
    character=v1,
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

### 3.26 0x numerals

@term 0x-numeral=v1
@cites #{
    production=v1, rule-name=v1, code-span=v1, whole-number=v1, text=v1,
    character=v1,
}

A 0x numeral is a text that matches the production `x-numeral`:

```
x-numeral  = %s"0x" 1*( DIGIT / %x41-46 )
```

A 0x numeral writes the whole number that its characters after `0x`
write in base 16, with `0` for 0, `1` for 1, `2` for 2, `3` for 3, `4`
for 4, `5` for 5, `6` for 6, `7` for 7, `8` for 8, `9` for 9, `A` for
10, `B` for 11, `C` for 12, `D` for 13, `E` for 14, and `F` for 15, such
as 0x0A for 10.

### 3.27 U+ numerals

@term u-numeral=v1
@cites #{
    production=v1, rule-name=v1, code-span=v1, whole-number=v1, text=v1,
    character=v1, code-point=v1,
}

A U+ numeral is a text that matches the production `u-numeral`:

```
u-numeral  = %s"U+" 4*6( DIGIT / %x41-46 )
```

A U+ numeral writes the whole number that its characters after `U+`
write in base 16, with `0` for 0, `1` for 1, `2` for 2, `3` for 3, `4`
for 4, `5` for 5, `6` for 6, `7` for 7, `8` for 8, `9` for 9, `A` for
10, `B` for 11, `C` for 12, `D` for 13, `E` for 14, and `F` for 15, such
as U+0041 for 65. A U+ numeral that writes the code point of a
character also names that character. The U+ numeral of a code point is
the U+ numeral that writes that code point and that has four characters
after `U+` when the code point is less than 65,536, or no `0` as its
first character after `U+` when the code point is 65,536 or more.

### 3.28 Hex digits

@term hex-digit=v1
@cites #{
    production=v1, rule-name=v1, code-span=v1, whole-number=v1,
    character=v1,
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

### 3.29 Bytes

@term byte=v1
@cites #{whole-number=v1, character=v1}

A byte is a whole number from 0 to 255. A byte is not a character.

### 3.30 Byte sequences

@term byte-sequence=v1
@cites #{byte=v1, text=v1, whole-number=v1}

A byte sequence is a finite sequence of bytes. The empty byte sequence
is the byte sequence of no bytes. The places of a byte sequence are the
whole numbers from 1 to the number of the bytes of the byte sequence.
For each place k of a byte sequence, the byte at place k is the k-th
byte of the byte sequence. Two byte sequences are the same byte
sequence when, and only when, they have the same number of bytes and,
in their order, the same first byte, the same second byte, and so on to
the last byte. A byte sequence is not a text.

### 3.31 Valid UTF-8

@term valid-utf-8=v1
@cites {rfc/3629, rfc/5234, #{byte-sequence=v1, byte=v1, code-span=v1}}

A byte sequence is valid UTF-8 when, and only when, the rule
`UTF8-octets` of RFC 3629 matches the whole byte sequence, with each
terminal value of that rule as one byte.

### 3.32 The text of a byte sequence

@term text-of-a-byte-sequence=v1
@cites {
    rfc/3629, rfc/5234,
    #{
        valid-utf-8=v1, byte-sequence=v1, byte=v1, text=v1,
        character=v1, u-numeral=v1, code-span=v1,
    },
}

The text of a byte sequence that is valid UTF-8 is the text that holds,
for each `UTF8-char` that the rule `UTF8-octets` of RFC 3629 matches in
the byte sequence, in their order, the character that the bytes of that
`UTF8-char` encode, as RFC 3629 defines UTF-8, and no other character.
The text holds a U+FEFF that the first `UTF8-char` encodes, in the same
way as each other character.

### 3.33 UTF-8 encodings

@term utf-8-encoding=v1
@cites {rfc/3629, #{text=v1, character=v1, byte-sequence=v1, byte=v1}}

The UTF-8 encoding of a text is the byte sequence that holds, for each
character of the text in its order, the bytes that encode that
character, as RFC 3629 defines UTF-8, and no other bytes.

### 3.34 Conforming programs

@term conforming-program=v1
@cites #{design=v1, requirement=v1}

A conforming program of a design is a program, or a part of a program,
that meets every requirement of the design. In a design, a conforming
program is a conforming program of that design, and each obligation
that a requirement of that design states with the word must is an
obligation of each conforming program of that design.

### 3.35 Inputs

@term input=v1
@cites #{conforming-program=v1, byte-sequence=v1, text=v1}

An input is a thing that a conforming program takes, such as a byte
sequence or a text.

### 3.36 Results

@term result=v1
@cites #{
    conforming-program=v1, input=v1, text=v1, requirement=v1,
    character=v1, code-point=v1,
}

A result of a requirement is a text that the requirement shows between
two double quotes, each the character whose code point is 34, as one of
the cases of what a conforming program gives for an input. The double
quotes are not part of the result. A conforming program gives a result
when it gives something that stands for that result and for no other
result.

## 4. Requirements

### 4.1 The test of whether a byte sequence is valid UTF-8

@req test-utf-8=v1
@cites #{
    conforming-program=v1, result=v1, byte-sequence=v1, valid-utf-8=v1,
}

When a conforming program gives a result for a byte sequence as a test
of whether the byte sequence is valid UTF-8, it must give exactly one
result: "valid" when the byte sequence is valid UTF-8, and "invalid"
when the byte sequence is not valid UTF-8.

### 4.2 The texts of byte sequences

@req give-texts-of-byte-sequences=v1
@cites #{
    conforming-program=v1, byte-sequence=v1, text=v1,
    text-of-a-byte-sequence=v1,
}

When a conforming program gives a text as the text of a byte sequence,
it must give the text of that byte sequence, and no other text, as the
text of that byte sequence.

### 4.3 No text for a byte sequence that is not valid UTF-8

@req omit-texts-of-invalid-byte-sequences=v1
@cites #{
    conforming-program=v1, byte-sequence=v1, text=v1, valid-utf-8=v1,
    text-of-a-byte-sequence=v1,
}

A conforming program must give no text as the text of a byte sequence
that is not valid UTF-8.

### 4.4 The UTF-8 encodings that a program gives

@req give-utf-8-encodings=v1
@cites #{
    conforming-program=v1, byte-sequence=v1, text=v1, utf-8-encoding=v1,
}

When a conforming program gives a byte sequence as the UTF-8 encoding of
a text, it must give the UTF-8 encoding of that text, and no other byte
sequence, as the UTF-8 encoding of that text.

### 4.5 The lines that a program gives

@req give-lines=v1
@cites #{
    conforming-program=v1, text=v1, run=v1, line=v1, line-number=v1,
}

When a conforming program gives the lines of a text, it must give as
many runs or texts as the text has lines, and, for each line of the
text, it must give that line, or the text of that line, as the k-th of
these runs or texts, where k is the line number of that line.

### 4.6 Lines with line numbers

@req give-numbered-lines=v1
@cites #{
    conforming-program=v1, text=v1, run=v1, line=v1, line-number=v1,
}

When a conforming program gives a run or a text, together with a line
number, as a line of a text, it must give, as that run or text, the
line of the text that has that line number, or the text of that line.

### 4.7 No other run or text as a line

@req give-only-lines=v1
@cites #{conforming-program=v1, text=v1, run=v1, line=v1}

A conforming program must give, as a line of a text, only a line of
that text or the text of a line of that text.

### 4.8 The line numbers and columns of characters

@req give-character-positions=v1
@cites #{
    conforming-program=v1, text=v1, character=v1, place=v1, run=v1,
    body=v1, position=v1,
}

When a conforming program gives a line number for the character at a
place of the body of a text, it must give the line number of the
position of the character at that place, and no other line number, for
the character at that place. When it gives a column for the character at
a place of the body of a text, it must give the column of the position
of the character at that place, and no other column, for the character
at that place.

### 4.9 No position for a byte order mark

@req omit-byte-order-mark-positions=v1
@cites #{
    conforming-program=v1, text=v1, character=v1, place=v1,
    byte-order-mark=v1, position=v1,
}

A conforming program must give no line number and no column for the
character at place 1 of a text that has a byte order mark.

### 4.10 The starts of spans

@req give-span-starts=v1
@cites #{conforming-program=v1, text=v1, span=v1, position=v1}

When a conforming program gives a line number for the start of a span of
a text, it must give the line number of the start of that span, and no
other line number, for the start of that span. When it gives a column
for the start of a span of a text, it must give the column of the start
of that span, and no other column, for the start of that span.

### 4.11 The ends of spans

@req give-span-ends=v1
@cites #{conforming-program=v1, text=v1, span=v1, position=v1}

When a conforming program gives a line number for the end of a span of a
text, it must give the line number of the end of that span, and no other
line number, for the end of that span. When it gives a column for the
end of a span of a text, it must give the column of the end of that
span, and no other column, for the end of that span.

### 4.12 No start and no end for a run that is not a span

@req give-positions-only-for-spans=v1
@cites #{conforming-program=v1, text=v1, run=v1, span=v1, position=v1}

A conforming program must give a line number or a column as the start
or the end of a run of a text only when that run is a span of that
text.

## 5. Conformance

A program, or a part of a program, conforms to this design when it
meets every requirement of the section Requirements.

The conformance vectors of this design are in the file
[`text.test-vectors.jsonl`](text.test-vectors.jsonl), in the same
directory as this design. A vector is an input and what a conforming
program gives for it. Each vector follows from the requirements and adds
nothing to them. The vectors are in groups. A group is a set of vectors
whose inputs have one form. Each group has a name, such as `decode`, and
a subsection below, which names the requirements that the vectors of the
group test and describes their inputs, results, and values. Each vector
of a group tests one or more of these requirements.

Several requirements apply only when a program gives the thing that they
name, such as a line number. So a vector tests a program only on what
the program gives for the input: a program that gives a line number for
a character, and no column, is tested only on the line number. The
subsection of each group says what a conforming program gives in each
case.

The file is valid UTF-8. Its text has no byte order mark and no carriage
return, and it ends with a line feed. Each line of the text of the file
is a JSON text, as RFC 8259 defines it, that holds one object. So only a
line feed ends a line of the file. U+0085, U+2028, and U+2029 stand in
some strings of the file, and they do not end a line. The file has three
kinds of line, in this order:

1. The first line is the set line. Its object has one member, `rev`:
   the revision of the whole set of vectors.
2. Then each group has a group line, in this order: `character-positions`,
   `decode`, `encode`, `lines`, `spans`. Its object has two members:
   `group`, the name of the group, as a string, and `rev`, the revision
   of the group.
3. Then each vector has a vector line, in increasing order of the
   numbers of the vectors.

The object of a vector line has these members:

- `n`: the number of the vector, a JSON number written as the decimal
  numeral of a whole number of 1 or more. No other vector of the file
  has this number.
- `rev`: the revision of the vector.
- `group`: the name of the group of the vector, as a string.
- `input`: the input.
- `result`: the result that a conforming program gives for the input.
  Only a vector of the group `decode` has this member.
- `values`: what a conforming program gives for the input, other than
  the result. A vector of the group `decode` with the result "invalid"
  does not have this member. Each other vector has it.
- `note`: an explanation of the vector, as a string, which a conforming
  program does not give. A vector has this member only when it has an
  explanation.

A revision is a string of `v`, then the decimal numeral of a whole
number of 1 or more, such as `"v1"`. The revision of a vector rises when
its group, its input, its result, or its values change. The revision of
a group, and the revision of the whole set, rise when one of their
vectors changes, joins them, or leaves them. A change of a note alone
changes no revision. A program does not need the revisions to run the
vectors.

Inside the members `input`, `result`, and `values`, each value that the
subsection of a group names as a text, a byte sequence, a whole number,
a run, a position, or a sequence has this form:

- A text, such as a result, is a JSON string whose characters are the
  characters of the text, in order. So the text `a`, a line feed, `b` is
  `"a\nb"`, and the empty text is `""`.
- A byte sequence is a JSON string of hex digits: for each byte, in
  order, the hex digit of the whole-number quotient of the byte divided
  by 16, then the hex digit of the remainder. So the byte sequence
  0xC3, 0xA9 is `"c3a9"`, and the empty byte sequence is `""`.
- A whole number, such as a place, a boundary, a line number, or a
  column, is a JSON number written as its decimal numeral, such as `12`.
- A run is an object with two members: `from`, the boundary where the
  run starts, and `to`, the boundary where the run ends. So the run that
  starts at boundary 1 and ends at boundary 4 is `{"from":1,"to":4}`.
- A position is an object with two members: `line`, the line number of
  the position, and `column`, the column of the position. So the
  position line 3, column 7 is `{"column":7,"line":3}`.
- A sequence, such as the lines of a text, is an array of its elements,
  in order.

### 5.1 Byte sequences that a program decodes

The group `decode` holds the vectors of the requirements `test-utf-8`,
`give-texts-of-byte-sequences`, and
`omit-texts-of-invalid-byte-sequences`. Each vector gives a byte
sequence and what a conforming program gives when it decodes the byte
sequence as UTF-8.

- `input`: the byte sequence.
- `result`: "valid" when the byte sequence is valid UTF-8, and "invalid"
  when it is not.
- `values`: only with the result "valid", an object with one member,
  `text`: the text of the byte sequence. With the result "invalid", the
  vector has no `values`.

When a conforming program gives a result for the byte sequence, as a
test of whether the byte sequence is valid UTF-8, it gives the result of
`result`. When it gives a text as the text of the byte sequence, it
gives the text of `text`. For a vector with the result "invalid", it
gives no text as the text of the byte sequence.

```
{"group":"decode","input":"6869","n":1,"result":"valid","rev":"v1","values":{"text":"hi"}}
{"group":"decode","input":"ff","n":17,"note":"the UTF-8 encoding of no character holds the byte 0xFF","result":"invalid","rev":"v1"}
```

### 5.2 The UTF-8 encodings that a program gives

The group `encode` holds the vectors of the requirement
`give-utf-8-encodings`. Each vector gives a text and its UTF-8 encoding.

- `input`: the text.
- `result`: no vector of the group has this member.
- `values`: an object with one member, `encoding`: the UTF-8 encoding of
  the text.

When a conforming program gives a byte sequence as the UTF-8 encoding of
the text, it gives the byte sequence of `encoding`.

```
{"group":"encode","input":"hi","n":30,"rev":"v1","values":{"encoding":"6869"}}
```

### 5.3 The lines that a program gives

The group `lines` holds the vectors of the requirements `give-lines`,
`give-numbered-lines`, and `give-only-lines`. Each vector gives a text
and the lines of the text.

- `input`: the text.
- `result`: no vector of the group has this member.
- `values`: an object with two members. `runs` is an array of the lines
  of the text, as runs, in the order of their line numbers. `texts` is
  an array of the texts of these lines, in the same order. So the k-th
  element of each array is the line with the line number k, or its
  text. When the text has no line, both arrays are empty.

When a conforming program gives the lines of the text, it gives as many
runs or texts as `runs` has elements, and the k-th of them is the k-th
element of `runs` or the k-th element of `texts`. When it gives a run or
a text, together with a line number k, as a line of the text, the run is
the k-th element of `runs`, or the text is the k-th element of `texts`.
It gives, as a line of the text, only an element of `runs` or an element
of `texts`.

```
{"group":"lines","input":"a\nb","n":48,"rev":"v1","values":{"runs":[{"from":0,"to":1},{"from":2,"to":3}],"texts":["a","b"]}}
```

### 5.4 The positions of characters that a program gives

The group `character-positions` holds the vectors of the requirements
`give-character-positions` and `omit-byte-order-mark-positions`. Each
vector gives a text, a place of the text, and the position of the
character at that place, when that character has a position.

- `input`: an object with two members: `text`, the text, and `place`,
  the place.
- `result`: no vector of the group has this member.
- `values`: when the character at the place has a position, an object
  with one member, `position`: that position. When the character has no
  position, the empty object, `{}`.

When a conforming program gives a line number for the character at the
place, it gives the line number of `position`. When it gives a column for
that character, it gives the column of `position`. When `values` is
`{}`, it gives no line number and no column for that character.

```
{"group":"character-positions","input":{"place":3,"text":"a\nb"},"n":75,"rev":"v1","values":{"position":{"column":1,"line":2}}}
```

### 5.5 The starts and ends of spans that a program gives

The group `spans` holds the vectors of the requirements
`give-span-starts`, `give-span-ends`, and
`give-positions-only-for-spans`. Each vector gives a text, a run of the
text, and, when the run is a span, the start and the end of the span.

- `input`: an object with two members: `text`, the text, and `run`, the
  run.
- `result`: no vector of the group has this member.
- `values`: when the run is a span, an object with two members: `start`,
  the start of the span, and `end`, the end of the span. When the run is
  not a span, the empty object, `{}`.

When a conforming program gives a line number for the start of the
span, it gives the line number of `start`. When it gives a column for
the start of the span, it gives the column of `start`. In the same way,
it gives the line number and the column of `end` for the end of the
span. When `values` is `{}`, it gives no line number and no column as
the start or the end of the run.

```
{"group":"spans","input":{"run":{"from":1,"to":2},"text":"abc"},"n":100,"rev":"v1","values":{"end":{"column":3,"line":1},"start":{"column":2,"line":1}}}
```
