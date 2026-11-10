<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 The Sinter Authors -->

# Text and notation
@design text=v1
@cites rfc/3629
@cites rfc/5234
@cites rfc/7405
Specifies characters and texts, bytes and UTF-8, lines and positions, hex digits and whole numbers, the notation of productions and of conformance vectors, and conforming programs, as used in Sinter, and requirements for conforming programs that decode and encode UTF-8 and give lines and positions.

A text is a finite sequence of characters, such as `docs/a.md`. A byte
sequence, such as the content of a file, holds a text when it is valid
UTF-8. The line feeds of a text divide it into lines, and each character
of a line has a position, such as line 3, column 7.

The productions in section 3 are written in ABNF, the notation of
RFC 5234. A production, such as `hex-digit = DIGIT / %x61-66`, gives the
texts that its name matches. In a production, `/` separates two
alternatives. The quoted string `"0"` is the character `0`. `*`
repeats the element after it any number of times, zero included.
`%x61` is the
character U+0061, and `%x31-39` is any one character from U+0031 to
U+0039. `DIGIT` is a core rule of RFC 5234: any one of the characters
`0` to `9`. In RFC 5234, a quoted string such as `"a"` matches its
letters in either case. RFC 7405 adds the form `%s"…"`, which matches
its letters only in the same case.

From RFC 3629, the design takes UTF-8: how a byte sequence encodes a
text, and the rule `UTF8-octets`, which gives the byte sequences that
are valid UTF-8.

## 1. Terms

| term | meaning |
|---|---|
| design | a document that declares requirements |
| conforming program | a program, or a part of a program, that meets every requirement of a design |
| must | states an obligation of a conforming program |
| whole number | a number with no fractional part, such as −7, 0, or 42 |
| decimal numeral | a text of the characters `0` to `9` that writes a whole number of 0 or more in base 10, with no leading `0`, such as `42` |
| hex digit | one of the characters `0` to `9` and `a` to `f`, which stand for the whole numbers 0 to 15 |
| code point | a whole number from 0 to 1,114,111, written as U+0000 to U+10FFFF |
| character | one Unicode scalar value: a code point that is not from U+D800 to U+DFFF |
| code point order | the order of characters by their code points |
| space, tab, line feed, carriage return | the characters U+0020, U+0009, U+000A, and U+000D |
| text | a finite sequence of characters |
| empty text | the text of no characters |
| place | the number of a character in the order of a text, counted from 1 |
| run | the characters of a text at the places from one place to another, such as `cd` in `abcde`; a run can be empty |
| Unicode normalization | a change of a text into a standard form of Unicode, such as the change of `e` and U+0301 into U+00E9 |
| byte | a whole number from 0 to 255 |
| byte sequence | a finite sequence of bytes |
| UTF-8 encoding | the byte sequence that encodes a text in UTF-8 |
| valid UTF-8 | a byte sequence is valid UTF-8 when it is the UTF-8 encoding of a text |
| text of a byte sequence | the text whose UTF-8 encoding a byte sequence is |
| byte order mark | the character U+FEFF when it is at place 1 of a text |
| body | the run of a text without its byte order mark |
| line ending | a line feed of a body, with the carriage return right before it when there is one |
| line | one of the runs into which the line endings divide a body, except an empty run at the end |
| position | a line number and a column, such as line 3, column 7 |
| line number | the first number of a position: the number of a line, counted from 1 |
| column | the second number of a position |
| ABNF | the notation for grammars of RFC 5234, with the case-sensitive strings of RFC 7405 |
| production | a rule of ABNF, such as `hex-digit = DIGIT / %x61-66`, which gives the texts that its name matches |
| input | a thing for which a conforming program gives a result, an output, or both, such as a byte sequence that it decodes |
| result | a name that a conforming program gives for an input, such as "valid" |
| output | a thing other than a result that a conforming program gives for an input, such as the text of a byte sequence |
| conformance vector | an input, and what a conforming program gives for it |
| explanation | the text in a conformance vector that says why a conforming program gives what it gives; a conforming program does not give it |

## 2. Texts, bytes, and lines

### 2.1 Numbers and digits

A whole number is a number with no fractional part, such as −7, 0, or
42. A decimal numeral writes a whole number of 0 or more in base 10,
with the characters `0` to `9`, such as `42` for 42. A decimal numeral
has no leading `0`: `0` is the decimal numeral of 0, and `042` is not a
decimal numeral.

Two forms name whole numbers in base 16, with the digits `0` to `9` and
the letters `A` to `F` for the values 0 to 15. The form `0x` and these
digits and letters names a whole number, such as 0x0A for 10 and 0xFF
for 255. The form `U+` and four to six of these digits and letters
names a code point, such as U+0041 for 65 and U+10FFFF for 1,114,111.

A hex digit is one of the sixteen characters `0` to `9` and `a` to `f`.
The hex digits `0` to `9` stand for the whole numbers 0 to 9, and the
hex digits `a` to `f` stand for 10 to 15. An upper-case letter is not a
hex digit: `3f2a` is a text of four hex digits, and `3F2A` is not. The
letters `A` to `F` of the forms `0x` and `U+` are upper-case letters, so
they are not hex digits.

### 2.2 Characters and texts

A code point is a whole number from 0 to 1,114,111. A character is a
Unicode scalar value: a code point that is not from U+D800 to U+DFFF.
So U+D800 is a code point and not a character. The form `U+` of the
code point of a character also names that character: U+0041 is the
character `A`.

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
of no characters. The places of a text number its characters from 1,
in order: in the text `abc`, `a` is at place 1, and `c` is at place 3.

Two texts are the same text when they have the same number of
characters and the same character at each place. Case matters, so `a`
and `A` are two different texts. Unicode normalization changes a text
into a standard form of Unicode, such as the change of `e` and U+0301
into U+00E9. Two texts that differ only by Unicode normalization are
two different texts: the text U+00E9 and the text `e`, U+0301 both
show as é, and they are not the same text.

A run of a text is the characters of the text at the places from one
place to the same place or a later place, such as `cd` at places 3 to 4
of `abcde`. A run keeps the places of its characters, so the text `aba`
has two different runs that each hold one `a`. A run can be empty. The
text of a run is its characters in their order: the text of each of
these two runs is `a`.

### 2.3 Bytes and UTF-8

A byte is a whole number from 0 to 255, such as 0x41. A byte sequence
is a finite sequence of bytes. The empty byte sequence is the byte
sequence of no bytes. Two byte sequences are the same byte sequence
when they have the same number of bytes and the same byte at each
place.

UTF-8, as RFC 3629 defines it, encodes each character in one to four
bytes. The UTF-8 encoding of a text holds the bytes of each of its
characters, in order, and no other bytes:

| text | UTF-8 encoding |
|---|---|
| `A` | 0x41 |
| U+00E9 | 0xC3, 0xA9 |
| `e`, U+0301 | 0x65, 0xCC, 0x81 |
| U+FEFF | 0xEF, 0xBB, 0xBF |
| U+1F600 | 0xF0, 0x9F, 0x98, 0x80 |
| the empty text | the empty byte sequence |

A byte sequence is valid UTF-8 when it is the UTF-8 encoding of a text.
The rule `UTF8-octets` of RFC 3629 gives these byte sequences. The text
of a byte sequence that is valid UTF-8 is the text whose UTF-8 encoding
it is. It holds each character that the bytes encode, in order, and no
other character. So the text keeps a U+FEFF at place 1, keeps each
carriage return, and keeps each character in the form that the bytes
encode, with no Unicode normalization.

These byte sequences are not valid UTF-8:

| byte sequence | why |
|---|---|
| 0xFF | no character of UTF-8 holds the byte 0xFF |
| 0xC0, 0xAF | an overlong form: UTF-8 encodes `/` as 0x2F |
| 0xED, 0xA0, 0x80 | the form of U+D800, which is not a character |
| 0xC3 | the first byte of a character with no byte after it |

### 2.4 Lines and positions

A position is a line number and a column, both counted from 1. Each
character of a text, except its byte order mark, has a position.

The byte order mark of a text is the character at place 1 when that
character is U+FEFF. The body of a text is the text without its byte
order mark. The byte order mark is on no line, so it has no position. A
U+FEFF at any other place is a character like any other.

A line ending is a line feed of the body, together with the carriage
return at the place right before that line feed when there is one. The
line endings divide the body into runs: the run before the first line
ending, the run between each line ending and the next line ending, and
the run after the last line ending. A body with no line ending is one
run. The lines of the text are these runs, in order, except the last run
when it is empty. The lines are numbered from 1.

A line never holds a line feed. A body that ends with a line feed has no
empty line after that line feed. The empty body has no line. A carriage
return that is not right before a line feed is a character of its line.
Only a line feed ends a line: U+000B, U+000C, U+0085, U+2028, and
U+2029 are characters of their line.

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

### 2.5 Productions

A production is a rule of ABNF, the notation of RFC 5234, with the
case-sensitive strings of RFC 7405. A production can use the core rules
of RFC 5234, such as `DIGIT` and `WSP`. Each terminal value of a
production is the code point of one character, so `%x61` matches the
character `a`, U+0061.

A text matches a production only as a whole. The text `42` matches the
production `decimal-numeral` of section 3.6, and the text `42a` does
not, although `42a` starts with `42`. A character matches a production
when the text of that one character matches it, so the character `a`
matches `hex-digit`.

### 2.6 Conforming programs, inputs, and results

A design is a document that declares requirements. A conforming program
of a design is a program, or a part of a program, that meets every
requirement of the design. So one program can hold conforming programs
of several designs, and the requirements of a design bind only the part
of the program that conforms to that design. In a requirement, "must"
states an obligation of a conforming program of the design that
declares the requirement.

A conforming program gives things for its inputs. An input is a thing
for which a conforming program gives a result, an output, or both. A
result is a name that states the outcome for the input, such as "valid"
or "invalid". An output is a thing other than a result that the program
gives for the input, such as the text of a byte sequence.

A conforming program has these inputs, and it gives these things for
them:

| input | result | output |
|---|---|---|
| a byte sequence that it decodes as UTF-8 | "valid" or "invalid" | the text of the byte sequence, with "valid" only |
| a text that it encodes as UTF-8 | none | the UTF-8 encoding of the text |
| a text whose lines it gives | none | the text of each line, in order |
| the character at a place of a text, for which it gives a position | none | the position of that character |

So a conforming program gives no position for a byte order mark: a byte
order mark has no position.

### 2.7 Conformance vectors

A conformance vector gives an input and what a conforming program gives
for it. A vector writes a result by its name, without the double quotes.
When the program gives outputs together with a result, the vector
writes them after the result, after a comma and the word "with", such
as "valid, with the text `hi`". Two outputs after "with" have a
semicolon between them. A vector writes an output that the program
gives with no result alone, such as "0x68, 0x69". It writes "none" when
the program gives nothing for the input.

The text after the first colon that is not between two backticks is an
explanation, as in "invalid: an overlong form". An explanation says why
the program gives what it gives. A conforming program does not give the
explanation.

A vector writes a text as its parts, in order, with commas between
them:

| part | stands for | example |
|---|---|---|
| characters between two backticks | those characters | `ab` |
| a space, a tab, a line feed, or a carriage return | that character | a line feed |
| a `U+` form | the character that it names | U+00E9 |
| a part, then "written", a decimal numeral, and "times" | that part, written as many times in a row as the number that the numeral writes | `ab` written 3 times |

So "`a`, a line feed, `b`" is the text of the three characters `a`,
U+000A, and `b`. The text of no characters is "the empty text".

A vector writes a byte sequence as its parts, in order, with commas
between them. A `0x` form stands for the byte that it names, and
characters between two backticks stand for the UTF-8 encoding of those
characters. So "`hi`, 0x0A" is the byte sequence 0x68, 0x69, 0x0A. The
byte sequence of no bytes is "the empty byte sequence".

A vector writes the lines of a text as the texts of the lines, in
order, with semicolons between them, and as "no line" when the text has
no line. A vector writes a position as "line", the decimal numeral of
its line number, a comma, "column", and the decimal numeral of its
column, such as "line 3, column 7".

## 3. Requirements

### 3.1 Whole numbers

@req whole-numbers=v1

A whole number is a number with no fractional part: 0, each number that
adding 1 to 0 one or more times gives, and each number that subtracting
1 from 0 one or more times gives.

### 3.2 Forms of numbers in base 16

@req number-forms=v1
@cites #{whole-numbers=v1}

The form `0x`, then one or more of the digits `0` to `9` and the
letters `A` to `F`, names the whole number that these digits and
letters write in base 16, with `A` to `F` for the values 10 to 15, such
as 0x0A for 10. The form `U+`, then four, five, or six of these digits
and letters, names in the same way the whole number that they write,
such as U+0041 for 65.

### 3.3 Characters

@req characters=v1
@cites #{whole-numbers=v1, number-forms=v1}

A code point is a whole number from 0 to 1,114,111. A character is a
Unicode scalar value: a code point from U+0000 to U+D7FF, or from
U+E000 to U+10FFFF. The `U+` form that names the code point of a
character also names that character. A space is U+0020, a tab is
U+0009, a line feed is U+000A, and a carriage return is U+000D. One
character comes before another in code point order, and the other comes
after it, when, and only when, the code point of the one is less than
the code point of the other.

### 3.4 Texts

@req texts=v1
@cites #{characters=v1, whole-numbers=v1}

A text is a finite sequence of characters. The empty text is the text
of no characters. The places of a text are numbered from 1, one place
for each character of the text, in the order of the text: the
character at place 1 is the first character of the text. Two texts are
the same text when, and only when, they have the same number of
characters and the same character at each place. A run of a text is the
characters of the text at the places from one place to the same place
or a later place, in order, each at its place. A run can also be empty,
and then it holds no character. The text of a run is the text of the
characters of the run, in their order.

### 3.5 Notation

@req notation=v1
@cites {rfc/5234, rfc/7405, #{characters=v1, texts=v1, number-forms=v1}}

A production is a rule of ABNF, the notation of RFC 5234, with the
case-sensitive strings of RFC 7405, that a requirement gives. A
production can use the core rules of RFC 5234, Appendix B.1. Each
terminal value of a production, and of each core rule that it uses, is
the code point of one character, so `%x41` matches the character
U+0041. A text matches a production when, and only when, the production
matches the whole of the text. A character matches a production when,
and only when, the text of that one character matches the production.

### 3.6 Decimal numerals

@req decimal-numerals=v1
@cites #{notation=v1, whole-numbers=v1, texts=v1}

A decimal numeral is a text that matches the production
`decimal-numeral`:

```
decimal-numeral  = "0" / %x31-39 *DIGIT
```

The number of a decimal numeral is the whole number that its characters
write in base 10, with the characters `0` to `9` for the values 0 to 9.
The decimal numeral of a whole number of 0 or more is the decimal
numeral whose number is that whole number.

### 3.7 Hex digits

@req hex-digits=v1
@cites #{notation=v1, whole-numbers=v1, characters=v1}

A hex digit is a character that matches the production `hex-digit`:

```
hex-digit  = DIGIT / %x61-66
```

The number of a hex digit is a whole number: 0 to 9 for the characters
`0` to `9`, in that order, and 10 to 15 for the characters `a` to `f`,
in that order.

### 3.8 Bytes

@req bytes=v1
@cites #{whole-numbers=v1, number-forms=v1}

A byte is a whole number from 0 to 255. A byte sequence is a finite
sequence of bytes. The empty byte sequence is the byte sequence of no
bytes. The places of a byte sequence are numbered from 1, one place for
each byte of the byte sequence, in its order. Two byte sequences are
the same byte sequence when, and only when, they have the same number
of bytes and the same byte at each place.

### 3.9 UTF-8

@req utf-8=v1
@cites {rfc/3629, #{characters=v1, texts=v1, bytes=v1}}

A byte sequence is valid UTF-8 when, and only when, the rule
`UTF8-octets` of RFC 3629 matches the whole byte sequence, with each
terminal value of that rule as one byte. The text of a byte sequence
that is valid UTF-8 holds one character for each `UTF8-char` that the
rule `UTF8-octets` matches in the byte sequence, in their order: the
character that the bytes of that `UTF8-char` encode, as RFC 3629
defines UTF-8. A U+FEFF that the first `UTF8-char` encodes is a
character of the text too. The UTF-8 encoding of a text is the byte
sequence that holds, for each character of the text in its order, the
bytes that encode that character, as RFC 3629 defines UTF-8, and no
other bytes.

### 3.10 Byte order marks

@req byte-order-marks=v1
@cites #{characters=v1, texts=v1, number-forms=v1}

The byte order mark of a text is the character at place 1 of the text
when that character is U+FEFF. A text has no other byte order mark.

### 3.11 Lines

@req lines=v1
@cites #{characters=v1, texts=v1, byte-order-marks=v1, whole-numbers=v1}

The body of a text is the run of the text that holds every character of
the text except its byte order mark. A line ending is the line feed at a
place of the body, together with the character at the place right
before that place when that character is a carriage return of the body.
The line endings divide the body into runs: the run before the first
line ending, the run between each line ending and the next line ending,
and the run after the last line ending; a body with no line ending is
one run. The lines of the text are these runs, in the order of the
body, except the last run when it is empty. The lines are numbered from
1, in their order. The line that ends at a line ending is the run right
before that line ending. A character of a line is the character at a
place of the body that the line holds.

### 3.12 Positions

@req positions=v1
@cites #{lines=v1, texts=v1, byte-order-marks=v1, whole-numbers=v1}

A position is a pair of whole numbers: a line number and a column. The
position of a character of a line has the number of that line as its
line number, and, as its column, 1 more than the number of the places
of that line before the place of that character. The position of a
character of a line ending has, as its line number, the number of the
line that ends at that line ending, and, as its column, 1 more than the
number of the characters of that line. A byte order mark has no
position.

### 3.13 Conforming programs

@req conforming-programs=v1

A design is a document that declares requirements. A conforming program
of a design is a program, or a part of a program, that meets every
requirement of the design. In a requirement of a design, a conforming
program is a conforming program of that design, and "must" states an
obligation of each conforming program of that design.

### 3.14 Inputs, results, and outputs

@req results=v1
@cites #{conforming-programs=v1}

An input is a thing for which a conforming program gives a result, an
output, or both. A result is a name that a conforming program gives for
an input, written between double quotes, such as "valid". An output is
a thing other than a result that a conforming program gives for an
input.

### 3.15 Byte sequences that a program decodes

@req decode-utf-8=v1
@cites #{conforming-programs=v1, results=v1, bytes=v1, utf-8=v1, texts=v1}

For each byte sequence that it decodes as UTF-8, a conforming program
must give exactly one result and no output other than this: the result
"valid", with the text of the byte sequence as its one output, when the
byte sequence is valid UTF-8, and the result "invalid", with no output,
when the byte sequence is not valid UTF-8.

### 3.16 Texts that a program encodes

@req encode-utf-8=v1
@cites #{conforming-programs=v1, results=v1, texts=v1, utf-8=v1}

For each text that it encodes as UTF-8, a conforming program must give
no result and one output: the UTF-8 encoding of the text.

### 3.17 The lines that a program gives

@req give-lines=v1
@cites #{conforming-programs=v1, results=v1, texts=v1, lines=v1}

For each text whose lines it gives, a conforming program must give no
result and one output: the text of each line of the text, in the order
of the lines, and no other text.

### 3.18 The positions that a program gives

@req give-positions=v1
@cites #{
    conforming-programs=v1, results=v1, texts=v1, positions=v1,
    byte-order-marks=v1,
}

When a conforming program gives a position for the character at a
place of a text, that position must be the position of that character,
and the program must give no result for that character.

### 3.19 Conformance vectors

@req vectors=v1
@cites #{conforming-programs=v1, results=v1}

A conformance vector is an input of a conforming program of a design,
together with what a conforming program of that design gives for it. A
vector writes a result by its name, without the double quotes. A vector
writes the outputs that a conforming program gives together with a
result after that result, after a comma and the word "with". When
there are two or more of these outputs, the vector writes a semicolon
between each two of them, and none of them is the lines of a text. A
vector writes an output that a conforming
program gives with no result alone. A vector writes "none" when a
conforming program gives no result and no output for the input.

### 3.20 Explanations in vectors

@req vector-explanations=v1
@cites #{vectors=v1, conforming-programs=v1}

In what a conformance vector writes for what a conforming program gives,
the text after the first colon that is not between two backticks is an
explanation. A conforming program does not give an explanation.

### 3.21 The notation of vectors

@req vector-notation=v1
@cites #{
    vectors=v1, characters=v1, texts=v1, bytes=v1, utf-8=v1,
    number-forms=v1, decimal-numerals=v1, lines=v1, positions=v1,
}

A conformance vector writes a text as "the empty text", or as one or
more parts, in their order, with a comma between each two parts. The
text stands for the characters for which its parts stand, in their
order. Each part is one of these:

- characters between two backticks, which stand for those characters,
  in their order;
- "a space", "a tab", "a line feed", or "a carriage return", which
  stands for that character;
- a `U+` form, which stands for the character that it names;
- a part, then "written", a decimal numeral, and "times", which stands
  for the characters for which that part stands, written as many times
  in a row as the number of the decimal numeral.

A conformance vector writes a byte sequence as "the empty byte
sequence", or as one or more parts, in their order, with a comma between
each two parts. Each part is a `0x` form, which stands for the byte
that it names, or characters between two backticks, which stand for the
UTF-8 encoding of the text of those characters. A conformance vector
writes the lines of a text as "no line" when the text has no line, and
otherwise as the texts of the lines, in their order, with a semicolon
between each two of them. A conformance vector writes a position as
"line", the decimal numeral of its line number, a comma, "column", and
the decimal numeral of its column.

## 4. Conformance

A program, or a part of a program, conforms to this design when it
meets every requirement of the section Requirements. Each vector below
gives an input and what a conforming program gives for it, as the
requirements `vectors`, `vector-explanations`, and `vector-notation`
state.

### 4.1 Byte sequences that a program decodes

| byte sequence | result |
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
| 0xFF | invalid: no character of UTF-8 holds the byte 0xFF |
| 0xFF, 0xFE | invalid: no character of UTF-8 holds the byte 0xFF |
| 0x80 | invalid: a continuation byte with no first byte before it |
| 0xC3 | invalid: the first byte of a character with no byte after it |
| `a`, 0xC3 | invalid: the first byte of a character with no byte after it |
| 0xC0, 0xAF | invalid: an overlong form |
| 0xC1, 0xBF | invalid: an overlong form |
| 0xE0, 0x80, 0xAF | invalid: an overlong form |
| 0xF0, 0x80, 0x80, 0xAF | invalid: an overlong form |
| 0xED, 0xA0, 0x80 | invalid: the form of U+D800, which is not a character |
| 0xED, 0xBF, 0xBF | invalid: the form of U+DFFF, which is not a character |
| 0xF4, 0x90, 0x80, 0x80 | invalid: the form of a number greater than 1,114,111 |
| 0xF8, 0x88, 0x80, 0x80, 0x80 | invalid: UTF-8 has no character of five bytes |

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

Each row gives a text, a place of that text, and the position that a
conforming program gives for the character at that place.

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
