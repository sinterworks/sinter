<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Text and notation
@design text=v1
@cites conformance=v1
@cites rfc/3629
@cites rfc/5234
@cites rfc/7405
@cites rfc/8259
Specifies, as used in Sinter, whole numbers, numerals, and hex digits; code points, characters, code point order, texts, places, boundaries, and runs; bytes and UTF-8; byte order marks, bodies, line endings, lines, line numbers, positions, and spans; code spans and blocks; the notation of productions and rule names; sequences and the notation of algorithms; results; canonical vector lines and the layout of the vector file; and requirements for conforming programs that validate and decode UTF-8, give UTF-8 encodings, and give lines, line numbers, the positions of characters, and the starts and ends of spans.

A text is a finite sequence of characters, such as `docs/a.md`. A byte
sequence, such as 0x68, 0x69, is the UTF-8 encoding of a text when the
byte sequence is valid UTF-8. A byte order mark is a U+FEFF that is the
first character of a text. The body of a text is the run of the text
after its byte order mark, or the whole text when the text has no byte
order mark. The line endings of the body divide it into lines. The
character at each place of the body has a position, such as line 3,
column 7. A span, such as a word of the text, has a start and an end,
which are positions.

The productions use ABNF (RFC 5234), with the case-sensitive strings of
RFC 7405.

Some definitions define a value, such as a text, by an algorithm. An
algorithm is a header sentence, then numbered steps, such as
`1. Let *s* be the empty text.`, and each step is in one of a fixed set
of forms.

From Conformance (`conformance`), the design takes what a design, a
definition, a schema, a requirement, a conforming program, and an input
are.

From RFC 3629, the design takes UTF-8: how a byte sequence encodes a
text, the rule `UTF8-char`, and the rule `UTF8-octets`. The rule
`UTF8-char` matches the bytes that encode one character. The rule
`UTF8-octets` matches the byte sequences that are valid UTF-8.

From RFC 8259, the design takes JSON texts, with their objects, members,
arrays, strings, and numbers. The file that holds the vectors of the
design has one JSON text on each line of the text of that file.

## 1. Glossary

| word or phrase | meaning |
|---|---|
| [design](sinter:conformance#design=v1) | a document of Sinter that declares items under names, each with a kind and a revision |
| [definition](sinter:conformance#design=v1) | a term, a schema, or an atom that a design declares under a name |
| [schema](sinter:conformance#design=v1) | a definition that a design declares under a name that gives the form of a concrete thing that crosses the edge of a program, or the form of a file of test cases for a design: its layout and every constraint that is a property of the thing itself |
| [requirement](sinter:conformance#requirement=v1) | a declared item of the kind requirement that a design declares under a name, such as `report-stops-at-limits`, and that states one or more obligations of a program with the word must |
| [conforming program](sinter:conformance#conforming-program=v1) | a program, or a part of a program, that meets every requirement of a design (or every requirement that a specification of a design declares), together with `report-stops-at-limits`, `end-runs-at-limits`, `reject-invalid-inputs`, `report-missing-parts`, `give-results-over-canonical-objects`, and `read-defined-encodings`; the term says under which inputs and limits each obligation binds |
| [input](sinter:conformance#input=v1) | a thing that a program takes for a requirement, such as a file or an argument of a command; an input is not valid when its owner design says that such a thing is not valid or when it supplies code that never ends; an input can also have parts, such as the commits of a history or the files of a folder tree |
| decode | a conforming program decodes a byte sequence as UTF-8 when the conforming program gives a result for whether the byte sequence is valid UTF-8 and, when the byte sequence is valid UTF-8, gives the text of the byte sequence |
| [result](sinter:#result=v1) | a text that a requirement shows between two double quotes, such as "valid", as one of the cases of what a conforming program gives for an input. The double quotes are not part of the result. A conforming program gives a result when the conforming program gives something that stands for that result and for no other result. |
| [whole number](sinter:#whole-number=v1) | a number with no fractional part, such as −7, 0, or 42 |
| [decimal numeral](sinter:#decimal-numeral=v1) | a text of the characters `0` to `9` that writes a whole number of 0 or more in base 10, and whose first character is not `0` unless the text is `0`, such as `42` |
| [0x numeral](sinter:#0x-numeral=v1) | `0x`, then one or more of `0` to `9` and `A` to `F`, which writes a whole number in base 16, such as 0x0A for 10 |
| [U+ numeral](sinter:#u-numeral=v1) | `U+`, then four to six of `0` to `9` and `A` to `F`, which writes a whole number in base 16, such as U+0041 for 65. When the whole number that a U+ numeral writes is the code point of a character, that U+ numeral names that character. The U+ numeral of a code point has four characters after `U+` when the code point is less than 65,536, and otherwise has no `0` as its first character after `U+`. |
| [hex digit](sinter:#hex-digit=v1) | one of the characters `0` to `9` and `a` to `f`, which write the whole numbers 0 to 15 |
| [code point](sinter:#code-point=v1) | a whole number from 0 to 1,114,111 |
| [character](sinter:#character=v1) | each character has one code point, which is a Unicode scalar value: a whole number from 0 to 55,295 (U+D7FF) or from 57,344 (U+E000) to 1,114,111 (U+10FFFF); each Unicode scalar value is the code point of exactly one character |
| [space](sinter:#space=v1), [tab](sinter:#tab=v1), [line feed](sinter:#line-feed=v1), [carriage return](sinter:#carriage-return=v1) | the characters U+0020, U+0009, U+000A, and U+000D |
| [code span](sinter:#code-span=v1) | the characters between the two backticks of a pair, such as `%x61`. On each line of a definition or a requirement, except on the lines of a block, the backticks pair in order. A code span stands for the characters between the two backticks of the pair, and not for the backticks. |
| [block](sinter:#code-span=v1) | the lines of a definition or a requirement from a line whose first characters, after any spaces, are three backticks to the next such line, such as the lines that hold the rule of a production. No backtick on the lines of a block belongs to a pair. |
| [text](sinter:#text=v1) | a finite sequence of characters |
| [empty text](sinter:#text=v1) | the text of no characters |
| [place](sinter:#place=v1) | a whole number, from 1 to the number of the characters of a text, at which a character is in the text |
| [code point order](sinter:#code-point-order=v1) | One character comes before another in code point order when the code point of the one is less than the code point of the other. One text comes before another in code point order when, at the first place of both texts where their characters differ, the character of the one comes before the character of the other. One text also comes before another in code point order when the one has fewer characters and the other has the same character at each place of the one. |
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
| [byte order mark](sinter:#byte-order-mark=v1) | the character U+FEFF at place 1 of a text |
| [body](sinter:#body=v1) | the run of a text that starts at boundary 1 when the text has a byte order mark, and at boundary 0 when the text has no byte order mark, and that ends at the last boundary of the text |
| [line ending](sinter:#line-ending=v1) | a run of a text that holds a line feed of the body and, when a carriage return of the body is right before that line feed, that carriage return, and that holds no other character |
| [line](sinter:#line=v1) | one of the runs into which the line endings divide a body, except an empty run that ends at the boundary where the body ends |
| [line number of a line](sinter:#line-number=v1) | the number of a line: 1 for the first line of a text, and 1 more for each later line |
| [position](sinter:#position=v1) | a pair of whole numbers, the line number of the position and the column of the position, such as line 3, column 7 |
| [line number of a position](sinter:#position=v1) | the first of the two whole numbers of a position, such as 3 in line 3, column 7 |
| [column](sinter:#position=v1) | the second of the two whole numbers of a position, such as 7 in line 3, column 7 |
| [span](sinter:#span=v1) | a run of a text that starts and ends at boundaries of the body. The start and the end of a span are positions. |
| ABNF | the notation for grammars of RFC 5234, with the case-sensitive strings of RFC 7405 |
| [production](sinter:#production=v1) | a rule of ABNF, such as `hex-digit = DIGIT / %x61-66`, that a definition or a requirement of a design holds, and that, with each rule, other than a core rule, that it reaches through its rule names, holds no prose value and has no rule name that names no rule or more than one rule; a text matches a production when, for some choice at each `/`, at each range of terminal values, at each letter of a quoted string that matches either case, and at each repetition, the production gives terminal values that match the characters of the text, one each, in their order |
| [rule name](sinter:#rule-name=v1) | a name in a rule of ABNF that a definition or a requirement R holds, such as `digit` for the core rule `DIGIT`. The rule name names each rule that has that rule name, without regard to case, and that is a core rule of RFC 5234, a rule that R holds, or a rule that a definition Q holds when R refers to Q as a definition whose meaning R uses. R holds a rule of ABNF when the rule is on the lines of one of the blocks of R. |
| [terminal value](sinter:#production=v1) | one of the numbers into which a rule of ABNF resolves, such as 0x61 for `%x61`. In a production, a terminal value matches the character whose code point is that terminal value. |
| [sequence](sinter:#sequence=v1) | what has a number of elements, a whole number n that is 0 or more, and, for each whole number k from 1 to n, one thing as its k-th element, such as the lines of a text in the order of their line numbers |
| [element](sinter:#sequence=v1) | The k-th element of a sequence is the thing of the sequence at number k, from 1. One thing can be the element of a sequence at more than one number. The empty sequence has no element. |
| [append](sinter:#sequence=v1) | appending a thing to a sequence gives the sequence of the elements of that sequence, in their order, and then that thing as the last element |
| [remove](sinter:#sequence=v1) | removing the k-th elements of a sequence for some numbers k gives the sequence of the elements of that sequence at the other numbers, in their order |
| [algorithm](sinter:#algorithm=v1) | a header sentence and numbered steps on lines of a definition, which define the value that the header names, such as the spaced text of a text in section 2.8; a program can get that value in any way |
| [step](sinter:#algorithm=v1) | a numbered line of an algorithm, with the lines after that numbered line up to the next numbered line, in one of a fixed set of forms, such as `Give *s*.`; a step that ends with `:` has substeps |
| [value name](sinter:#algorithm=v1) | in an algorithm, a word of the letters `a` to `z`, or words joined by `-`, written between two `*`, such as `*s*`; a value name stands for one value at a time |
| [give](sinter:#algorithm=v1) | for each choice of a value for each header value name of an algorithm, the algorithm gives the value V of the step `Give V.` at which the steps of the algorithm end for these values |
| [canonical vector line](sinter:#canonical-vector-line=v1) | a JSON text, as RFC 8259 defines it, that holds one JSON object and writes that object and each JSON value inside it in the single form that `canonical-vector-line` fixes |
| [vector](sinter:#vector-line=v1) | an input and what a conforming program gives for it |
| [group](sinter:#vector-line=v1) | a named set of vectors, such as `decode` |
| [vector line](sinter:#vector-line=v1) | the text of one line of the vector file: a canonical vector line whose JSON object holds one vector |

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
is `0x`, then one or more of the characters `0` to `9` and `A` to `F`,
such as 0x0A for 10 and 0xFF for 255. A U+ numeral is `U+`, then four,
five, or six of the characters `0` to `9` and `A` to `F`, such as U+0041
for 65 and U+10FFFF for 1,114,111.

A hex digit is one of the sixteen characters `0` to `9` and `a` to `f`.
The hex digits `0` to `9` write the whole numbers 0 to 9, and the hex
digits `a` to `f` write 10 to 15. The hex digit of a whole number from 0
to 15 is the hex digit that writes that whole number, so the hex digit
of 12 is `c`. An upper-case letter is not a hex digit: `3f2a` is a text
of four hex digits, and `3F2A` is not. So the letters `A` to `F` of a 0x
numeral or a U+ numeral are not hex digits.

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

The examples show a text as its parts, in order, with commas between the
parts. A part is characters between backticks, such as `ab`; one of the
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

Code point order also orders texts. One text comes before another text
when, at the first place of both texts at which their characters
differ, the character of the one comes before the character of the
other. When two different texts have no such place, the text with fewer
characters comes before the other. So `B` comes before `a`, `ab` comes
before `b`, `ab` comes before `abc`, and the empty text comes before
every other text. The text `e`, U+0301 comes before the text U+00E9,
because 101 is less than 233. A U+FEFF at place 1 is a character like
any other in this order, so `a` comes before U+FEFF, `a`. Of two
different texts, exactly one comes before the other.

A boundary of a text is a whole number from 0 to the number of
characters of the text. Boundary 0 is before place 1, and each other
boundary is right after the place with the same number. So the text
`abc` has the four boundaries 0, 1, 2, and 3. A run of a text starts at
a boundary, and it ends at the same boundary or at a later boundary. The
run holds the characters at the places between the boundary where the
run starts and the boundary where the run ends, in order, and each
character keeps its place. So the run of `abcde` that starts at boundary
2 and ends at boundary 4 holds `cd`, at places 3 and 4. A run that
starts and ends at the same boundary is empty. The text of a run is its
characters in order.

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
between the bytes, and show each byte as a 0x numeral, such as 0x68,
0x69. The examples show the byte sequence of no bytes as "the empty byte
sequence".

In RFC 3629, the rule `UTF8-char` matches the bytes that encode one
character, and the rule `UTF8-octets` matches any number of `UTF8-char`
in a row. A byte sequence is valid UTF-8 when `UTF8-octets` matches the
whole byte sequence. Then the byte sequence is the UTF-8 encoding of one
text, the text of the byte sequence. That text holds the character that
each `UTF8-char` encodes, in order, and no other character. So the text
keeps a U+FEFF at place 1, keeps each carriage return, and keeps each
character as the bytes encode it, with no Unicode normalization.

For example, the byte sequence 0xFF is not valid UTF-8, because the
UTF-8 encoding of no character holds the byte 0xFF.

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
a line feed of the body. When the body holds a carriage return right
before that line feed, the line ending starts at the boundary right
before that carriage return. Otherwise, the line ending starts at the
boundary right before that line feed. So in the text `ab`, a carriage
return, a line feed, `c`, the line ending starts at boundary 2 and ends
at boundary 4. A line starts at the boundary where the body starts, or
at the boundary where a line ending ends. The line ends at the first
boundary, at or after the boundary where the line starts, where a line
ending starts. When no line ending starts at or after the boundary where
the line starts, the line ends at the boundary where the body ends. A
run that ends at the boundary where the body ends is a line only when
the run is not empty. So the line endings divide the body into runs, and
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
order, with semicolons between those texts, or as "no line" when the
text has no line. The examples show a span as the boundary where the
span starts, "to", and the boundary where the span ends, such as "1 to
4".

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
each place of the body has a position. The column of the character at a
place of a line is 1 more than the number of the places of the line
before that place. The character at each place of a line ending has the
line number of the line that ends at the boundary where that line ending
starts. The column of that character is 1 more than the number of the
places of that line. A column counts characters, not bytes: U+00E9 is
one character, which UTF-8 encodes in two bytes. A tab is one character,
so it counts as one column.

| text | place | position |
|---|---|---|
| `ab`, a line feed, `c` | 4 | line 2, column 1 |
| `ab`, a carriage return, a line feed, `c` | 3 | line 1, column 3 |
| `ab`, a carriage return, a line feed, `c` | 4 | line 1, column 3 |
| U+00E9, `x` | 2 | line 1, column 2 |
| `e`, U+0301, `x` | 3 | line 1, column 3 |
| U+FEFF, `x` | 2 | line 1, column 1 |

A boundary of the body also has a position. A boundary from the boundary
where a line starts to the boundary where that line ends has the line
number of that line. The column of that boundary is 1 more than the
number of the places of the line before the boundary. So the position of
the character at a place is the position of the boundary right before
that place. The boundary between the carriage return and the line feed
of a line ending has the position of the place of that carriage return.
When the body is empty, or its last character is a line feed, no line
ends at the boundary where the body ends. The line number of the
position of that boundary is 1 more than the number of the lines of the
text, and no line has that line number. The column of that position is
1: in the text `a`, a line feed, the boundary where the body ends has
the position line 2, column 1.

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

### 2.5 Code spans and blocks

A backtick is the character U+0060, whose code point is 96. In a
definition or a requirement, a line whose first characters, after any
spaces, are three backticks opens a block of lines or closes the block
that is open. The first such line opens a block, the next such line
closes that block, the line after that opens a new block, and so on.
The lines of a block are the lines from the line that opens the block
to the line that closes it, or to the last line of the definition or
the requirement when no line closes it. The rule of a production is on
the lines of a block, such as the rule of `hex-digit` in section 3.26.
No backtick on the lines of a block belongs to a pair.

On every other line of a definition or a requirement, the backticks
pair in order: the first backtick with the second, the third with the
fourth, and so on. A backtick that belongs to no pair, such as the last
backtick of a line that holds three backticks and is not a line of a
block, is a character like any other. The characters between the two
backticks of a pair, such as `%x61`, are a code span. A code span
stands for those characters, and the backticks are not part of them.

### 2.6 Productions

A production is a rule of ABNF, the notation of RFC 5234, with the
case-sensitive strings of RFC 7405. A definition or a requirement holds
a rule of ABNF when the rule is on the lines of one of the blocks of
that definition or requirement. The numbers into which a rule resolves
are what RFC 5234 calls the terminal values of the rule: `%x61` is the
terminal value 0x61. A terminal value in a production matches the
character whose code point is that terminal value, so `%x61` matches the
character `a`, U+0061. A terminal value that is not the code point of a
character, such as 0xD800, matches no character.

A production can use the core rules of RFC 5234, such as `DIGIT` and
`HEXDIG`. A core rule can use other core rules: `HEXDIG` uses `DIGIT`. A
terminal value in a core rule that a production uses, directly or
through other core rules, matches a character in the same way. A quoted
string matches its letters in either case. The core rule `HEXDIG` uses
quoted strings for its letters. So `HEXDIG` matches both `a` and `A`.
The production `hex-digit` of section 3.26 uses `%x61-66` for its
letters, so `hex-digit` matches `a` and does not match `A`.

When a definition or a requirement R holds a rule of ABNF, a rule name
in that rule names each rule that has that rule name, without regard to
case, and that is a core rule of RFC 5234, a rule that R holds, or a
rule that a definition Q holds when R refers to Q as a definition whose
meaning R uses. So `digit` names the core rule `DIGIT`. A rule X reaches
each rule Y that one of the rule names of X names, and reaches each rule
that Y reaches in turn. In RFC 5234, a prose value stands between `<`
and `>`. A rule of ABNF is a production only when the rule holds no
prose value and each rule name of the rule names exactly one rule. Each
rule that a production reaches, other than a core rule, meets the same
two conditions.

A text matches a production when, for some choice of one alternative at
each `/` and of one number of repetitions at each repetition, the
production gives terminal values that match the characters of the text,
one each, in their order. A range of terminal values, such as `%x31-39`,
gives a choice of one of its terminal values. A letter of a quoted
string that matches either case gives a choice of one of its two cases.
The order of the alternatives has no effect, so a production
`p = "a" / "ab"` matches the text `ab`, although the first alternative
of the production matches the first character of `ab`. A text matches a
production only as a whole. The text `42` matches the production
`decimal-numeral` of section 3.23, and the text `42a` does not, although
the first two characters of `42a` are `42`. A character matches a
production when the text of that one character matches the production,
so the character `a` matches `hex-digit`.

### 2.7 Decoding and results

A conforming program decodes a byte sequence as UTF-8 when the
conforming program gives a result for whether the byte sequence is valid
UTF-8 and, when the byte sequence is valid UTF-8, gives the text of the
byte sequence. A result of a requirement is a text that the requirement
shows between two double quotes, such as "valid", as one of the cases of
what a conforming program gives for an input. The double quotes are not
part of the result. A conforming program gives a result when it gives
something that stands for that result and for no other result. So a
program that gives the number 1 for "valid" and the number 0 for
"invalid" gives these two results.

### 2.8 Sequences and algorithms

A sequence has a number of elements, 0 or more, each a thing at its own
number from 1, such as the lines of a text in the order of their line
numbers. A text is a sequence of characters, and a byte sequence is a
sequence of bytes. So the 3rd element of the text `abc` is its 3rd
character, `c`.

A definition can define a value by an algorithm. An algorithm is a
header sentence, then numbered steps, and each step is in one of the
forms that the term `algorithm` of section 3.34 lists. That term also
says what the steps define. For example, a definition could define the
spaced text of a text by this algorithm:

The spaced text of a text *t* is the text that these steps give.

1. Let *s* be the empty text.
2. For each *c* of *t*, in order:
   1. If *c* is a tab, append a space to *s*.
   2. Otherwise, append *c* to *s*.
3. Give *s*.

For the text `a`, a tab, `b`, these steps give the text `a`, a space,
`b`. The words *t*, *s*, and *c* are value names, and each stands for
one value. A step can use the value that an algorithm gives, the same
algorithm included, by the words of the header of that algorithm, such
as "the spaced text of *s*".

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

A Unicode scalar value is a whole number from 0 to 55,295 or from 57,344
to 1,114,111. Each character has one code point. That code point is a
Unicode scalar value. Each Unicode scalar value is the code point of
exactly one character.

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

### 3.8 Texts

@term text=v1
@cites #{character=v1}

A text is a finite sequence of characters. The empty text is the text of
no characters. Two texts are the same text when, and only when, the two
texts have the same number of characters and, in the order of the
characters of each text, the same first character, the same second
character, and so on to the last character.

### 3.9 Places

@term place=v1
@cites #{text=v1, character=v1, whole-number=v1}

The places of a text are the whole numbers from 1 to the number of the
characters of the text. For each place k of a text, the character at
place k is the k-th character of the text. The character at place 1 is
the first character of the text.

### 3.10 Code point order

@term code-point-order=v1
@cites #{character=v1, code-point=v1, text=v1, place=v1}

A character A comes before a character B in code point order when, and
only when, the code point of A is less than the code point of B. A
character B comes after a character A in code point order when, and only
when, the code point of A is less than the code point of B. A text A
comes before a text B in code point order, and B comes after A in code
point order, when, and only when, A and B meet one of these conditions:

- Both A and B have a place at which the character of A and the
  character of B differ. At the first such place, the character of A
  comes before the character of B in code point order.
- A has fewer characters than B. At each place of A, B has the same
  character as A.

### 3.11 Boundaries

@term boundary=v1
@cites #{text=v1, place=v1, character=v1, whole-number=v1}

A boundary of a text is a whole number from 0 to the number of
characters of the text. Boundary 0 is before place 1. Each other
boundary k is right after place k.

### 3.12 Runs

@term run=v1
@cites #{text=v1, place=v1, boundary=v1, character=v1}

A run of a text starts at a boundary s of the text and ends at a
boundary e of the text that is s or greater. For each boundary s of a
text and each boundary e of the text that is s or greater, the text has
a run that starts at s and ends at e. The run holds the characters at
the places from s + 1 to e, in order, each character at its place. The
places from s + 1 to e are the places of the run. The run is empty when
s = e. When s = e, the run holds no character. Two runs of a text are
the same run when, and only when, they start at the same boundary and
end at the same boundary. The text of a run is the text of the
characters of the run, in their order. A boundary of a run is a boundary
of the text from the boundary where the run starts to the boundary where
the run ends.

### 3.13 Byte order marks

@term byte-order-mark=v1
@cites #{text=v1, place=v1, character=v1, code-point=v1}

A text has a byte order mark when, and only when, the character at place
1 of the text is the character whose code point is 65,279. The byte
order mark of such a text is that character, at place 1.

### 3.14 Bodies

@term body=v1
@cites #{text=v1, run=v1, boundary=v1, byte-order-mark=v1}

The body of a text that has a byte order mark is the run of the text
that starts at boundary 1 and ends at the last boundary of the text.
The body of every other text is the run of the text that starts at
boundary 0 and ends at the last boundary of the text.

### 3.15 Line endings

@term line-ending=v1
@cites #{
    text=v1, run=v1, boundary=v1, place=v1, body=v1, line-feed=v1,
    carriage-return=v1, character=v1,
}

A line ending of a text is a run of the text that meets each of these
conditions, where p is the boundary where the run ends:

- Place p is a place of the body. The character at place p is a line
  feed.
- When place p − 1 is a place of the body and the character at place p −
  1 is a carriage return, the run starts at boundary p − 2. Otherwise,
  the run starts at boundary p − 1.

### 3.16 Lines

@term line=v1
@cites #{text=v1, run=v1, boundary=v1, body=v1, line-ending=v1}

A line of a text is a run of the text that meets each of these
conditions:

- The run starts at the boundary where the body starts, or at the
  boundary where a line ending ends.
- The run ends at the first boundary, at or after the boundary where the
  run starts, where a line ending starts. When no line ending starts at
  or after the boundary where the run starts, the run ends at the
  boundary where the body ends.
- When the run ends at the boundary where the body ends, the run is not
  empty.

### 3.17 Line numbers

@term line-number=v1
@cites #{
    text=v1, line=v1, line-ending=v1, boundary=v1, body=v1,
    whole-number=v1,
}

Each line of a text has a line number, which is a whole number. The line
that starts at the boundary where the body starts has the line number 1.
Each other line starts at the boundary where a line ending ends. The
line number of that line is 1 more than the line number of the line that
ends at the boundary where that line ending starts. The lines of a text
are in the order of their line numbers.

### 3.18 Positions

@term position=v1
@cites #{
    line=v1, line-number=v1, line-ending=v1, body=v1, run=v1,
    boundary=v1, place=v1, text=v1, character=v1, whole-number=v1,
}

A position is a pair of whole numbers: the line number of the position
and the column of the position. The position of a boundary b of the
body of a text is this:

- When a line starts at b or before b, and ends at b or after b: the
  line number of the position is the line number of that line. The
  column of the position is 1 more than b − s, where s is the boundary
  where that line starts.
- Otherwise, when a line ending starts before b and ends after b: the
  line number of the position is the line number of the line that ends
  at the boundary where that line ending starts. The column of the
  position is 1 more than e − s, where s is the boundary where that line
  starts and e is the boundary where that line ends.
- Otherwise: the line number of the position is 1 more than the number
  of the lines of the text. No line has that line number. The column of
  the position is 1.

The position of a place p of the body of a text is the position of the
boundary p − 1. The character at place p has that position.

### 3.19 Spans

@term span=v1
@cites #{
    text=v1, run=v1, boundary=v1, place=v1, body=v1, line=v1,
    position=v1,
}

A span of a text is a run of the text that starts at a boundary of the
body and ends at a boundary of the body. The start of a span is the
position of the boundary where the span starts. When one or more places
of the span are places of a line, the end of the span is the position of
boundary k, where k is the last place of the span that is a place of a
line. Otherwise, the end of the span is the start of the span.

### 3.20 Code spans

@term code-span=v1
@cites {
    conformance#{design=v1, requirement=v1},
    #{character=v1, code-point=v1, text=v1, line=v1, space=v1},
}

A backtick is the character whose code point is 96. In the text of a
definition or a requirement of a design, a line whose first characters,
after any spaces, are three backticks opens a block of lines or closes
the block that is open. The first such line opens a block, the next such
line closes that block, and so on. The lines of a block are the lines
from the line that opens the block to the line that closes it, or to the
last line of the definition or the requirement when no line closes it.
No backtick on the lines of a block belongs to a pair. On each other
line of a definition or a requirement, the backticks pair in order: the
first backtick with the second, the third with the fourth, and so on. A
backtick that belongs to no pair is a character like any other. A code
span is the characters between the two backticks of a pair. A code span
stands for those characters, and the backticks are not part of them.

### 3.21 Rule names

@term rule-name=v1
@cites {
    rfc/5234, conformance#{design=v1, requirement=v1},
    #{code-span=v1, line=v1},
}

A definition or a requirement R of a design holds a rule of ABNF when,
and only when, the rule is on the lines of one of the blocks of R. A
rule name in a rule of ABNF that R holds names each rule that has that
rule name, without regard to case, and that is one of these:

- A core rule of RFC 5234, Appendix B.1.
- A rule of ABNF that R holds.
- A rule of ABNF that a definition Q holds, when R refers to Q as a
  definition whose meaning R uses.

### 3.22 Productions

@term production=v1
@cites {
    rfc/5234, rfc/7405, conformance#{design=v1, requirement=v1},
    #{rule-name=v1, code-span=v1, character=v1, code-point=v1, text=v1},
}

ABNF is the notation of RFC 5234, with the case-sensitive strings of RFC
7405. A production is a rule of ABNF that meets these conditions:

- A definition or a requirement of a design holds the rule.
- The rule holds no prose value. In RFC 5234, a prose value stands
  between `<` and `>`.
- Each rule name of the rule names exactly one rule.
- Each rule that it reaches through its rule names, directly or through
  other rules, is a core rule of RFC 5234, or that rule holds no prose
  value and each rule name of that rule names exactly one rule.

A terminal value in a production, or in a core rule that a production
uses, directly or through other core rules, matches the character whose
code point is that terminal value. So `%x41` matches the character whose
code point is 65. A terminal value that is not the code point of a
character matches no character. A text matches a production when, and
only when, the production gives terminal values that match the
characters of the text, one each, in their order, for some choice of:
one alternative at each `/`; one terminal value at each range of
terminal values, such as `%x30-39`; one case at each letter of a quoted
string that matches either case; and one number of repetitions at each
repetition. The order of the alternatives has no effect. A character
matches a production when, and only when, the text of that one character
matches the production.

### 3.23 Decimal numerals

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

### 3.24 0x numerals

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
10, `B` for 11, `C` for 12, `D` for 13, `E` for 14, and `F` for 15. For
example, 0x0A writes 10.

### 3.25 U+ numerals

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
10, `B` for 11, `C` for 12, `D` for 13, `E` for 14, and `F` for 15. For
example, U+0041 writes 65. A U+ numeral that writes the code point of a
character also names that character. When a code point is less than
65,536, the U+ numeral of that code point is the U+ numeral that writes
that code point and has four characters after `U+`. When a code point is
65,536 or more, the U+ numeral of that code point is the U+ numeral that
writes that code point and has no `0` as its first character after `U+`.

### 3.26 Hex digits

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
digit that writes that whole number.

### 3.27 Bytes

@term byte=v1
@cites #{whole-number=v1, character=v1}

A byte is a whole number from 0 to 255. A byte is not a character.

### 3.28 Byte sequences

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

### 3.29 Valid UTF-8

@term valid-utf-8=v1
@cites {rfc/3629, rfc/5234, #{byte-sequence=v1, byte=v1, code-span=v1}}

A byte sequence is valid UTF-8 when, and only when, the rule
`UTF8-octets` of RFC 3629 matches the whole byte sequence, with each
terminal value of that rule as one byte.

### 3.30 The text of a byte sequence

@term text-of-a-byte-sequence=v1
@cites {
    rfc/3629, rfc/5234,
    #{
        valid-utf-8=v1, byte-sequence=v1, byte=v1, text=v1,
        character=v1, u-numeral=v1, code-span=v1,
    },
}

When a byte sequence is valid UTF-8, the text of that byte sequence is
the text that holds one character for each `UTF8-char` that the rule
`UTF8-octets` of RFC 3629 matches in the byte sequence, in the order of
the byte sequence, and no other character. For each such `UTF8-char`,
that character is the character that the bytes of that `UTF8-char`
encode, as RFC 3629 defines UTF-8. The text holds a U+FEFF that the
first `UTF8-char` encodes, in the same way as each other character.

### 3.31 UTF-8 encodings

@term utf-8-encoding=v1
@cites {rfc/3629, #{text=v1, character=v1, byte-sequence=v1, byte=v1}}

The UTF-8 encoding of a text is the byte sequence that holds, for each
character of the text in the order of the text, the bytes that encode
that character, as RFC 3629 defines UTF-8, and no other bytes.

### 3.32 Results

@term result=v1
@cites {
    conformance#{conforming-program=v1, input=v1, requirement=v1},
    #{text=v1, character=v1, code-point=v1},
}

A result of a requirement is a text that the requirement shows between
two double quotes, each the character whose code point is 34, as one of
the cases of what a conforming program gives for an input. The double
quotes are not part of the result. A conforming program gives a result
when it gives something that stands for that result and for no other
result.

### 3.33 Sequences

@term sequence=v1
@cites #{whole-number=v1}

A sequence has a number of elements, which is a whole number n that is 0
or more. For each whole number k from 1 to n, the sequence has one thing
as the k-th element of the sequence. The first element of a sequence is
the 1st element of the sequence. The last element of a sequence is the
k-th element of the sequence, where k is the number of elements of the
sequence. One thing can be the k-th element of a sequence for more than
one k. The empty sequence has no element. Two sequences are the same
sequence when, and only when, they have the same number of elements and,
for each k, the same k-th element. Appending a thing to a sequence S
gives the sequence whose elements are the elements of S, in their order,
and then that thing as the last element. Removing the k-th elements of a
sequence S for some numbers k gives the sequence of the elements of S at
the other numbers, in their order.

### 3.34 Algorithms

@term algorithm=v1
@cites {
    conformance#design=v1,
    #{
        text=v1, character=v1, place=v1, code-point=v1, line=v1,
        space=v1, code-span=v1, decimal-numeral=v1, whole-number=v1,
        sequence=v1, byte-sequence=v1, byte=v1,
    },
}

An algorithm is a header and steps, on lines of the text of a definition
of a design, that meet the conditions of this definition. The header
names a value. The algorithm defines that value. That value is the value
that the algorithm gives. The steps define only that value. The steps
put no obligation on a program. A program can get that value in any way.

In an algorithm, a text is a sequence of characters, as the definition
of a text says. In an algorithm, the k-th element of a text is the
character at place k. In an algorithm, a byte sequence is a sequence of
bytes, as the definition of a byte sequence says. In an algorithm, the
k-th element of a byte sequence is the byte at place k.

The lines of an algorithm:

- A step line is a line whose first characters, after zero or more
  spaces, are a decimal numeral, `.`, and a space. The numeral of the
  step line is that decimal numeral.
- The steps of an algorithm are on the lines from its first step line up
  to the line before the first later line that holds no character other
  than spaces, or up to the last line of the definition. Each step line
  of these lines starts a step.
- The line right before the first step line holds no character other
  than spaces. The header is on the lines before that line, from the
  line after the nearest earlier line that holds no character other than
  spaces.
- No line of the header or of the steps is a line of a block.
- The text of the header is the text of the lines of the header, each
  line without the spaces at the start of that line, with one space
  between two lines. The text of a step is the text of the step line of
  the step after the numeral of that step line, the `.`, and the space,
  then, for each later line of the steps up to the next step line, one
  space and the text of that later line without the spaces at the start
  of that later line.

The header and the value names:

- The text of the header is one sentence of the form `The `, W, ` of `,
  I, ` is the `, K, ` that these steps give.`, where W holds no ` of `.
  W names the value that the algorithm gives. I names the values for
  which the algorithm gives a value. K says what kind of thing that
  value is, such as `text`.
- A value name is a text of one or more words, with one `-` between two
  words. Each word in a value name is one or more of the characters
  whose code points are 97 to 122, the letters `a` to `z`. A value name
  stands for one value at a time.
- In the text of the header and of each step, the `*` outside code spans
  pair in order: the first with the second, the third with the fourth,
  and so on. The characters between the two `*` of each pair are a value
  name. So `*t*` writes the value name `t`.
- The value names in I are the header value names. I holds each header
  value name once. W and K hold no value name. The algorithm gives a
  value for each choice of one value for each header value name.

The steps:

- The steps at the top of the algorithm are the step lines that have as
  many spaces before their numerals as the first step line of the
  algorithm. Each other step line has more spaces before its numeral
  than the first step line of the algorithm.
- The step lines between the step line of a step S and the next step
  line that has as many spaces before its numeral as the step line of S,
  or fewer, have more spaces before their numerals than the step line of
  S. Among the step lines between the step line of S and that next step
  line, the substeps of S are the step lines that have as many spaces
  before their numerals as the first of those step lines. Each step line
  between the step line of S and that next step line that is not a
  substep of S has more spaces before its numeral than the step line of
  a substep of S. By the same rule, each such step line is a substep of
  one of the substeps of S.
- The steps at the top, and the substeps of each step, are numbered in
  order: the numeral of the k-th of them is the decimal numeral of k.
- Each step has exactly one of these forms, where *n*, *m*, and *s* are
  value names, V names a value, C is a condition, and S names a
  sequence:
  - `Let *n* be V.`: from this step on, *n* stands for V.
  - `Set *n* to V.`: from this step on, *n* stands for V.
  - `If C, then:`, with substeps: when C holds, the substeps are taken.
  - `If C, `, then a step of the form Set, Append, Remove, or Give, with
    its first letter in lower case: when C holds, that step is taken.
  - `Otherwise:`, with substeps, or `Otherwise, `, then a step of the
    form Set, Append, Remove, or Give, with its first letter in lower
    case. An Otherwise step comes right after an If step, among the
    steps at the top or among the substeps of one step. The substeps, or
    the step, of the Otherwise step are taken only when the condition of
    that If step does not hold.
  - `For each *m* of S, in order:`, with substeps: for each element of
    S, from the first element to the last element, *m* stands for that
    element, and the substeps are taken. S is the sequence that S names
    when this step starts.
  - `While C:`, with substeps: when C holds, the substeps are taken, and
    then this step is taken again.
  - `Append V to *s*.`: when *s* stands for a text and V is a text, or
    when *s* stands for a byte sequence and V is a byte sequence, *s*
    then stands for the sequence that appending each element of V to *s*
    in the order of V gives. Otherwise, *s* then stands for the sequence
    that appending V to *s* gives. When, of the Let, Set, Append, and
    Remove steps for *s*, the step that was taken last is a Let step or
    a Set step, and the V of that step is the words
    `the empty sequence`, *s* stands for no text and no byte sequence in
    this rule.
  - `Remove V from *s*.`, where V names some elements of the sequence
    for which *s* stands, each by its number, such as "the last
    character of *t*": *s* then stands for the sequence that removing
    the elements at these numbers gives.
  - `Give V.`: the algorithm gives V, and no other step is taken.
- A step of a form that ends with `:` has one or more substeps. No other
  step has a substep.

The value names that a step can use:

- The header value names are given to each step.
- A Let step gives its value name to each later step among the steps at
  the top, or among the substeps of one step, where the Let step is.
- A For each step gives its value name to its substeps.
- A value name that is given to a step is also given to the substeps of
  that step.
- A step uses only value names that are given to it, other than the
  value name that it gives.
- No step gives a value name that is given to that step.
- A Set, Append, or Remove step changes only a value name that a Let
  step gives.
- A step that changes the value for which one value name stands does not
  change the value for which another value name stands. A step that
  changes the value for which one value name stands does not change the
  sequence of a For each step that already started.

Values and conditions:

- A value name stands for its value. A code span stands for the text of
  its characters.
- The words of a definition Q name the value that Q defines, such as
  "the empty text" or "a line feed", only when the definition R that
  holds the algorithm refers to Q as a definition whose meaning R uses.
- The words W of the header of an algorithm, then ` of `, then I with a
  value in place of each header value name, name the value that this
  algorithm gives for these values, such as "the spaced text of *s*".
  Each word of I other than a header value name can stay or be left out,
  so the values stand in the order of the header value names in I. The
  algorithm can be the algorithm of the step itself. When the algorithm
  is another algorithm, the definition R that holds the step refers to
  the definition that holds that other algorithm as a definition whose
  meaning R uses.
- A condition holds or does not hold for the values for which the value
  names stand when the step is taken.

How the steps are taken:

- For a choice of values, each header value name stands for its value.
  For that choice of values, the steps at the top are taken in the order
  of those steps, from the first.
- The substeps of a step are taken in their order, from the first. A
  step with substeps ends after its substeps end. After a step with
  substeps ends, the step after that step is taken.
- For each choice of values, taking the steps reaches a Give step after
  a finite number of steps. For each algorithm that those steps use,
  that number includes the steps of that algorithm. The value that the
  algorithm gives for these values is the value V of that Give step.

## 4. Requirements

### 4.1 The validation of UTF-8

@req validate-utf-8=v1
@cites {
    conformance#conforming-program=v1,
    #{result=v1, byte-sequence=v1, valid-utf-8=v1},
}

When a conforming program gives a result for whether a byte sequence is
valid UTF-8, the conforming program must give exactly one result. When a
byte sequence is valid UTF-8 and a conforming program gives a result for
whether that byte sequence is valid UTF-8, the conforming program must
give "valid" as that result. When a byte sequence is not valid UTF-8 and
a conforming program gives a result for whether that byte sequence is
valid UTF-8, the conforming program must give "invalid" as that result.

### 4.2 The texts of byte sequences

@req give-texts-of-byte-sequences=v1
@cites {
    conformance#conforming-program=v1,
    #{byte-sequence=v1, text=v1, text-of-a-byte-sequence=v1},
}

When a conforming program gives a text as the text of a byte sequence,
it must give the text of that byte sequence, and no other text, as the
text of that byte sequence.

### 4.3 No text for a byte sequence that is not valid UTF-8

@req omit-texts-of-invalid-byte-sequences=v1
@cites {
    conformance#conforming-program=v1,
    #{
        byte-sequence=v1, text=v1, valid-utf-8=v1,
        text-of-a-byte-sequence=v1,
    },
}

A conforming program must give no text as the text of a byte sequence
that is not valid UTF-8.

### 4.4 The UTF-8 encodings that a program gives

@req give-utf-8-encodings=v1
@cites {
    conformance#conforming-program=v1,
    #{byte-sequence=v1, text=v1, utf-8-encoding=v1},
}

When a conforming program gives a byte sequence as the UTF-8 encoding of
a text, it must give the UTF-8 encoding of that text, and no other byte
sequence, as the UTF-8 encoding of that text.

### 4.5 The lines that a program gives

@req give-lines=v1
@cites {
    conformance#conforming-program=v1,
    #{text=v1, run=v1, line=v1, line-number=v1},
}

When a conforming program gives the lines of a text, it must give as
many runs or texts as the text has lines, and, for each line of the
text, it must give that line, or the text of that line, as the k-th of
these runs or texts, where k is the line number of that line.

### 4.6 Lines with line numbers

@req give-numbered-lines=v1
@cites {
    conformance#conforming-program=v1,
    #{text=v1, run=v1, line=v1, line-number=v1},
}

When a conforming program gives a run or a text, together with a line
number, as a line of a text, it must give, as that run or text, the
line of the text that has that line number, or the text of that line.

### 4.7 No other run or text as a line

@req give-only-lines=v1
@cites {conformance#conforming-program=v1, #{text=v1, run=v1, line=v1}}

A conforming program must give, as a line of a text, only a line of
that text or the text of a line of that text.

### 4.8 The line numbers and columns of characters

@req give-character-positions=v1
@cites {
    conformance#conforming-program=v1,
    #{text=v1, character=v1, place=v1, run=v1, body=v1, position=v1},
}

When a conforming program gives a line number for the character at a
place of the body of a text, it must give the line number of the
position of the character at that place, and no other line number, for
the character at that place. When a conforming program gives a column
for the character at a place of the body of a text, it must give the
column of the position of the character at that place, and no other
column, for the character at that place.

### 4.9 The starts of spans

@req give-span-starts=v1
@cites {
    conformance#conforming-program=v1,
    #{text=v1, span=v1, position=v1},
}

When a conforming program gives a line number for the start of a span of
a text, it must give the line number of the start of that span, and no
other line number, for the start of that span. When a conforming program
gives a column for the start of a span of a text, it must give the
column of the start of that span, and no other column, for the start of
that span.

### 4.10 The ends of spans

@req give-span-ends=v1
@cites {
    conformance#conforming-program=v1,
    #{text=v1, span=v1, position=v1},
}

When a conforming program gives a line number for the end of a span of a
text, it must give the line number of the end of that span, and no other
line number, for the end of that span. When a conforming program gives a
column for the end of a span of a text, it must give the column of the
end of that span, and no other column, for the end of that span.

## 5. Conformance

A program, or a part of a program, conforms to this design when it is a
[conforming program](sinter:conformance#conforming-program=v1) of this
design.

The vectors of this design are in the file
[`text.test-vectors.jsonl`](text.test-vectors.jsonl), in the same
directory as this design. Each vector follows from the requirements and
adds nothing to them.

Several requirements apply only when a program gives the thing that they
name, such as a line number. So a vector holds a program only to what
the program gives for the input. When a program gives a line number for
a character and no column, a vector holds that program only to the line
number. The schema of each group says what a conforming program gives in
each case.

### 5.1 Canonical vector lines

@schema canonical-vector-line=v1
@cites {
    rfc/8259,
    #{
        text=v1, character=v1, code-point=v1, code-point-order=v1,
        space=v1, tab=v1, line-feed=v1, carriage-return=v1,
        whole-number=v1, hex-digit=v1, u-numeral=v1, code-span=v1,
    },
}

A canonical vector line is a JSON text, as RFC 8259 defines a JSON text,
that holds one JSON object and meets all of these rules:

- No JSON object has two members with the same name.
- No JSON value is `null`, a number with a fraction or an exponent, or a
  whole number outside the range from −9,007,199,254,740,991 to
  9,007,199,254,740,991. A JSON number that writes 0 has no leading `-`.
- There is no space, tab, line feed, or carriage return outside JSON
  strings.
- The members of each JSON object stand in code point order of the texts
  of their names, where each escape sequence stands for the character
  that it writes.
- In each JSON string, `"` is written `\"`. In each JSON string, `\` is
  written `\\`. In each JSON string, the characters U+0008, U+0009,
  U+000A, U+000C, and U+000D are written `\b`, `\t`, `\n`, `\f`, and
  `\r`. In each JSON string, each other character from U+0000 to U+001F
  is written `\u00`, then the hex digit of the whole-number quotient of
  the code point of that character divided by 16, and then the hex digit
  of the remainder. In each JSON string, every character other than `"`,
  `\`, and the characters from U+0000 to U+001F stands as itself.

A JSON text meets the schema `canonical-vector-line` when, and only
when, the JSON text is a canonical vector line.

### 5.2 Vector lines

@schema vector-line=v1
@cites {
    rfc/8259, conformance#{conforming-program=v1, design=v1, input=v1},
    #{
        canonical-vector-line=v1, result=v1, byte-sequence=v1,
        valid-utf-8=v1, text-of-a-byte-sequence=v1, text=v1,
        character=v1, byte-order-mark=v1, line=v1, line-feed=v1,
        carriage-return=v1, whole-number=v1, decimal-numeral=v1,
        u-numeral=v1, code-span=v1,
    },
}

A vector of this design is an input and what a conforming program gives
for that input. The vectors are in groups, and each group has a name,
such as `decode`. The vector file of this design,
`text.test-vectors.jsonl` in the same directory as this design, is a
byte sequence that is valid UTF-8. The text of the file has no byte
order mark and no carriage return. The text of the file has no empty
line. When the text of the file is not empty, that text ends with a line
feed. So only a line feed ends a line of the vector file. A JSON string
of the vector file can hold U+0085, U+2028, or U+2029. These characters
do not end a line. The vector file holds zero or more vector lines.

The text of each line of the vector file is a vector line. A vector line
meets the schema `canonical-vector-line`, and its JSON object has the
members `form`, `group`, `input`, `note`, `result`, and `values`, and no
other member, with `note` and `result` only where these rules state:

- `form`: a JSON string of `#`, the name of the schema of this design
  for the group of the vector, `=`, and a label. That label is `v`, then
  the decimal numeral of a whole number of 1 or more, such as `v1`. An
  example of `form` is `"#decode-vector=v1"`.
- `group`: the name of the group of the vector, as a JSON string.
- `input`: the input.
- `note`: an explanation of the vector, as a JSON string. A conforming
  program does not give this explanation. A vector has this member only
  when the vector has an explanation.
- `result`: the result that a conforming program gives when the
  conforming program gives a result for the input. Only a vector of the
  group `decode` has this member.
- `values`: a JSON object that holds what a conforming program gives for
  the input, other than the result. Each vector has this member. The
  schema of the group says which of these things a conforming program
  gives in each case. An empty JSON object, `{}`, says that a conforming
  program gives none of the things that the schema names for `values`.

A vector line meets the schema `vector-line` when, and only when, it
meets what this schema states for one vector line: what this schema
states from "The text of each line of the vector file" up to this
paragraph, this paragraph left out. All vector lines in the vector file
with the same `group` have the same `#` and name of a schema in `form`,
and their labels in `form` may differ. The vector file meets the schema
`vector-line` when, and only when, the vector file meets what this
schema states before "The text of each line of the vector file" and
what this paragraph states on `group` and `form`, and the text of each
line of the vector file is a vector line that meets the schema
`vector-line`.

### 5.3 Byte sequences that a program decodes

@schema decode-vector=v1
@cites {
    rfc/8259, conformance#{conforming-program=v1, input=v1},
    #{
        vector-line=v1, validate-utf-8=v1,
        give-texts-of-byte-sequences=v1,
        omit-texts-of-invalid-byte-sequences=v1, result=v1,
        byte-sequence=v1, byte=v1, valid-utf-8=v1,
        text-of-a-byte-sequence=v1, text=v1, character=v1, hex-digit=v1,
        whole-number=v1, 0x-numeral=v1, line-feed=v1, code-span=v1,
    },
}

The group `decode` holds the vectors of the requirements
`validate-utf-8`, `give-texts-of-byte-sequences`, and
`omit-texts-of-invalid-byte-sequences`. Each vector gives a byte
sequence and what a conforming program gives for that byte sequence by
these requirements. Each vector line of the group meets the schema
`vector-line`.

Inside `input`, `result`, and `values`, a text and a byte sequence have
these forms:

- A text, such as a result, is a JSON string whose characters are the
  characters of the text, in order. So the text `a`, a line feed, `b` is
  `"a\nb"`, and the empty text is `""`.
- A byte sequence is a JSON string of hex digits. The characters of the
  JSON string are, for each byte of the byte sequence in order, the hex
  digit of the whole-number quotient of the byte divided by 16, then the
  hex digit of the remainder. So the byte sequence 0xC3, 0xA9 is
  `"c3a9"`, and the empty byte sequence is `""`.

The members `input`, `result`, and `values` of the JSON object of a
vector line hold these things:

- `input`: the byte sequence.
- `result`: "valid" when the byte sequence is valid UTF-8, and "invalid"
  when the byte sequence is not valid UTF-8.
- `values`: when the result is "valid", `values` is a JSON object with
  one member, `text`. When the result is "valid", `text` is the text of
  the byte sequence. When the result is "invalid", `values` is the empty
  JSON object, `{}`.

When a conforming program gives a result for whether the byte sequence
is valid UTF-8, the conforming program gives the result that `result`
holds, once, and no other result. When a conforming program gives a text
as the text of the byte sequence, the conforming program gives the text
that `text` holds, and no other text. When `values` is `{}`, a
conforming program gives no text as the text of the byte sequence.

```
{"form":"#decode-vector=v1","group":"decode","input":"6869","result":"valid","values":{"text":"hi"}}
{"form":"#decode-vector=v1","group":"decode","input":"ff","note":"the UTF-8 encoding of no character holds the byte 0xFF","result":"invalid","values":{}}
```

### 5.4 The UTF-8 encodings that a program gives

@schema encode-vector=v1
@cites {
    rfc/8259, conformance#{conforming-program=v1, input=v1},
    #{
        vector-line=v1, decode-vector=v1, give-utf-8-encodings=v1,
        text=v1, byte-sequence=v1, utf-8-encoding=v1, code-span=v1,
    },
}

The group `encode` holds the vectors of the requirement
`give-utf-8-encodings`. Each vector gives a text and the UTF-8 encoding
of the text. Each vector line of the group meets the schema
`vector-line`. Inside `input` and `values`, a text and a byte sequence
have the JSON forms that `decode-vector` states.

The members `input` and `values` of the JSON object of a vector line
hold these things:

- `input`: the text.
- `values`: a JSON object with one member, `encoding`: the UTF-8
  encoding of the text.

When a conforming program gives a byte sequence as the UTF-8 encoding of
the text, the conforming program gives the byte sequence that `encoding`
holds, and no other byte sequence, as the UTF-8 encoding of the text.

```
{"form":"#encode-vector=v1","group":"encode","input":"hi","values":{"encoding":"6869"}}
```

### 5.5 The lines that a program gives

@schema line-vector=v1
@cites {
    rfc/8259, conformance#{conforming-program=v1, input=v1},
    #{
        vector-line=v1, decode-vector=v1, give-lines=v1,
        give-numbered-lines=v1, give-only-lines=v1, text=v1, line=v1,
        line-number=v1, run=v1, boundary=v1, place=v1, position=v1,
        whole-number=v1, decimal-numeral=v1, sequence=v1, code-span=v1,
    },
}

The group `lines` holds the vectors of the requirements `give-lines`,
`give-numbered-lines`, and `give-only-lines`. Each vector gives a text
and the lines of the text. Each vector line of the group meets the
schema `vector-line`.

Inside `input` and `values`, a text has the JSON form that
`decode-vector` states. Inside `input` and `values`, a whole number of 0
or more, a run, and a sequence have these forms:

- A whole number of 0 or more, such as a place, a boundary, a line
  number, or a column, is a JSON number, such as `12`, written as the
  decimal numeral of that whole number.
- A run is a JSON object with two members: `from`, the boundary where
  the run starts, and `to`, the boundary where the run ends. So the run
  that starts at boundary 1 and ends at boundary 4 is
  `{"from":1,"to":4}`.
- A sequence, such as the lines of a text, is a JSON array of the
  elements of the sequence, in order.

The members `input` and `values` of the JSON object of a vector line
hold these things:

- `input`: the text.
- `values`: a JSON object with two members. `runs` is a JSON array of
  the lines of the text, as runs, in the order of their line numbers.
  `texts` is a JSON array of the texts of these lines, in the same
  order. So the k-th element of each JSON array is the line with the
  line number k, or the text of that line. When the text has no line,
  both JSON arrays are empty.

When a conforming program gives the lines of the text, the conforming
program gives as many runs or texts as `runs` has elements. When a
conforming program gives the lines of the text, the k-th of the runs or
texts that the conforming program gives is the k-th element of `runs` or
the k-th element of `texts`. When a conforming program gives a run,
together with a line number k, as a line of the text, that run is the
k-th element of `runs`. When a conforming program gives a text, together
with a line number k, as a line of the text, the text that the
conforming program gives is the k-th element of `texts`. So a conforming
program gives no run and no text together with a line number that is
less than 1, or greater than the number of elements of `runs`. A
conforming program gives, as a line of the text, only an element of
`runs` or an element of `texts`.

```
{"form":"#line-vector=v1","group":"lines","input":"a\nb","values":{"runs":[{"from":0,"to":1},{"from":2,"to":3}],"texts":["a","b"]}}
```

### 5.6 The positions of characters that a program gives

@schema character-position-vector=v1
@cites {
    rfc/8259, conformance#{conforming-program=v1, input=v1},
    #{
        vector-line=v1, decode-vector=v1, line-vector=v1,
        give-character-positions=v1, text=v1, character=v1, place=v1,
        body=v1, line=v1, position=v1, whole-number=v1, code-span=v1,
    },
}

The group `character-positions` holds the vectors of the requirement
`give-character-positions`. Each vector gives a text, a place of the
body of the text, and the position of the character at that place. Each
vector line of the group meets the schema `vector-line`.

Inside `input` and `values`, a text has the JSON form that
`decode-vector` states. Inside `input` and `values`, a whole number of 0
or more has the JSON form that `line-vector` states. Inside `input` and
`values`, a position has this form:

- A position is a JSON object with two members: `line`, the line number
  of the position, and `column`, the column of the position. So the
  position line 3, column 7 is `{"column":7,"line":3}`.

The members `input` and `values` of the JSON object of a vector line
hold these things:

- `input`: a JSON object with two members: `text`, the text, and
  `place`, the place.
- `values`: a JSON object with one member, `position`: the position of
  the character at the place.

When a conforming program gives a line number for the character at the
place, the conforming program gives the line number of `position`, and
no other line number, for that character. When a conforming program
gives a column for the character at the place, the conforming program
gives the column of `position`, and no other column, for that character.

```
{"form":"#character-position-vector=v1","group":"character-positions","input":{"place":3,"text":"a\nb"},"values":{"position":{"column":1,"line":2}}}
```

### 5.7 The starts and ends of spans that a program gives

@schema span-vector=v1
@cites {
    rfc/8259, conformance#{conforming-program=v1, input=v1},
    #{
        vector-line=v1, decode-vector=v1, line-vector=v1,
        character-position-vector=v1, give-span-starts=v1,
        give-span-ends=v1, text=v1, span=v1, run=v1, position=v1,
        whole-number=v1, code-span=v1,
    },
}

The group `spans` holds the vectors of the requirements
`give-span-starts` and `give-span-ends`. Each vector gives a text, a
span of the text, and the start and the end of the span. Each vector
line of the group meets the schema `vector-line`. Inside `input` and
`values`, a text has the JSON form that `decode-vector` states. Inside
`input` and `values`, a whole number of 0 or more and a run have the
JSON forms that `line-vector` states. Inside `input` and `values`, a
position has the JSON form that `character-position-vector` states.

The members `input` and `values` of the JSON object of a vector line
hold these things:

- `input`: a JSON object with two members: `text`, the text, and `run`,
  the span.
- `values`: a JSON object with two members: `start`, the start of the
  span, and `end`, the end of the span.

When a conforming program gives a line number for the start of the span,
the conforming program gives the line number of `start`, and no other
line number, for the start of the span. When a conforming program gives
a column for the start of the span, the conforming program gives the
column of `start`, and no other column, for the start of the span. When
a conforming program gives a line number for the end of the span, the
conforming program gives the line number of `end`, and no other line
number, for the end of the span. When a conforming program gives a
column for the end of the span, the conforming program gives the column
of `end`, and no other column, for the end of the span.

```
{"form":"#span-vector=v1","group":"spans","input":{"run":{"from":1,"to":2},"text":"abc"},"values":{"end":{"column":3,"line":1},"start":{"column":2,"line":1}}}
```
